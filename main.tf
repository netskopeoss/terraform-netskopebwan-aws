#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  primary_gw_gre_inside_ip   = try(cidrhost(var.aws_transit_gw["primary_inside_cidr"], 1), "")
  secondary_gw_gre_inside_ip = try(cidrhost(var.aws_transit_gw["secondary_inside_cidr"], 1), "")

  transit_gw_bgp_routers = {
    tgw_peer1_inside_ip1 = try(cidrhost(var.aws_transit_gw["primary_inside_cidr"], 2), "")
    tgw_peer1_inside_ip2 = try(cidrhost(var.aws_transit_gw["primary_inside_cidr"], 3), "")
    tgw_peer2_inside_ip1 = try(cidrhost(var.aws_transit_gw["secondary_inside_cidr"], 2), "")
    tgw_peer2_inside_ip2 = try(cidrhost(var.aws_transit_gw["secondary_inside_cidr"], 3), "")
  }
}

module "aws_vpc" {
  source = "./modules/aws_vpc"

  aws_profile           = var.aws_profile
  aws_create_vpc        = var.aws_create_vpc
  aws_vpc               = var.aws_vpc
  aws_network_config    = var.aws_network_config
  aws_create_transit_gw = var.aws_create_transit_gw
  aws_transit_gw        = var.aws_transit_gw
  netskope_ha_enable    = var.netskope_ha_enable
  netskope_tenant       = var.netskope_tenant
}

module "nsg_config" {
  source = "./modules/nsg_config"

  aws_network_config      = var.aws_network_config
  netskope_ha_enable      = var.netskope_ha_enable
  netskope_gateway_config = var.netskope_gateway_config
  primary_gw_interfaces   = module.aws_vpc.primary_gw_interfaces
  secondary_gw_interfaces = module.aws_vpc.secondary_gw_interfaces
}

locals {
  primary_gw_userdata = templatefile("modules/aws_ec2/scripts/user-data.sh",
    {
      netskope_gw_default_password = var.netskope_gateway_config["password"],
      netskope_tenant_url          = var.netskope_tenant["tenant_url"],
      netskope_gw_activation_key   = module.nsg_config.primary_gateway_token,
      netskope_gw_bgp_metric       = var.netskope_gateway_config["primary_bgp_med"],
      netskope_gw_asn              = var.netskope_tenant["tenant_bgp_asn"],
      transit_gw_peer_inside_ip1   = local.transit_gw_bgp_routers["tgw_peer1_inside_ip1"],
      transit_gw_peer_inside_ip2   = local.transit_gw_bgp_routers["tgw_peer1_inside_ip2"]
    }
  )

  secondary_gw_userdata = templatefile("modules/aws_ec2/scripts/user-data.sh",
    {
      netskope_gw_default_password = var.netskope_gateway_config["password"],
      netskope_tenant_url          = var.netskope_tenant["tenant_url"],
      netskope_gw_activation_key   = module.nsg_config.secondary_gateway_token,
      netskope_gw_bgp_metric       = var.netskope_gateway_config["secondary_bgp_med"],
      netskope_gw_asn              = var.netskope_tenant["tenant_bgp_asn"],
      transit_gw_peer_inside_ip1   = local.transit_gw_bgp_routers["tgw_peer2_inside_ip1"],
      transit_gw_peer_inside_ip2   = local.transit_gw_bgp_routers["tgw_peer2_inside_ip2"]
    }
  )
}

module "aws_ec2" {
  source             = "./modules/aws_ec2"
  aws_instance       = var.aws_instance
  netskope_ha_enable = var.netskope_ha_enable
  netskope_tenant    = var.netskope_tenant

  zones                   = module.aws_vpc.zones
  primary_gw_interfaces   = module.aws_vpc.primary_gw_interfaces
  secondary_gw_interfaces = module.aws_vpc.secondary_gw_interfaces
  primary_gw_userdata     = local.primary_gw_userdata
  secondary_gw_userdata   = local.secondary_gw_userdata
}

module "bgp_config" {
  source             = "./modules/bgp_config"
  netskope_ha_enable = var.netskope_ha_enable
  netskope_tenant    = var.netskope_tenant

  nsg_config              = module.nsg_config
  transit_gateway_config  = merge(module.aws_vpc.transit_gateway_output, local.transit_gw_bgp_routers)
  primary_gw_interfaces   = module.aws_vpc.primary_gw_interfaces
  secondary_gw_interfaces = module.aws_vpc.secondary_gw_interfaces
}