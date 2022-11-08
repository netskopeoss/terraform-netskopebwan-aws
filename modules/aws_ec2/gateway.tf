#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  primary_gw_peers = {
    inside_ip1 = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 2), "")
    inside_ip2 = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 3), "")
  }
  secondary_gw_peers = {
    inside_ip1 = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 2), "")
    inside_ip2 = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 3), "")
  }
}

resource "aws_instance" "netskope_sdwan_gw_instance" {
  ami               = local.netskope_gw_image_id
  instance_type     = var.aws_instance.instance_type
  availability_zone = var.aws_network_config.primary_zone
  user_data = templatefile("modules/aws_ec2/scripts/user-data.sh",
    {
      netskope_gw_default_password = var.netskope_gateway_config.gateway_password,
      netskope_tenant_url          = var.netskope_tenant.tenant_url,
      netskope_gw_activation_key   = var.netskope_gateway_config.gateway_data.primary.token,
      netskope_gw_bgp_metric       = "10",
      netskope_gw_asn              = var.netskope_tenant.tenant_bgp_asn,
      transit_gw_peer_inside_ip1   = local.primary_gw_peers.inside_ip1,
      transit_gw_peer_inside_ip2   = local.primary_gw_peers.inside_ip2
    }
  )
  key_name = var.aws_instance.keypair

  dynamic "network_interface" {
    for_each = keys(var.netskope_gateway_config.gateway_data.primary.interfaces)
    content {
      network_interface_id = var.netskope_gateway_config.gateway_data.primary.interfaces[network_interface.value].id
      device_index         = network_interface.key
    }
  }

  tags = {
    Name = var.netskope_tenant.tenant_id
  }
}

resource "aws_instance" "netskope_sdwan_ha_gw_instance" {
  count             = var.netskope_gateway_config.ha_enabled ? 1 : 0
  ami               = local.netskope_gw_image_id
  instance_type     = var.aws_instance.instance_type
  availability_zone = var.aws_network_config.secondary_zone
  user_data = templatefile("modules/aws_ec2/scripts/user-data.sh",
    {
      netskope_gw_default_password = var.netskope_gateway_config.gateway_password,
      netskope_tenant_url          = var.netskope_tenant.tenant_url,
      netskope_gw_activation_key   = var.netskope_gateway_config.gateway_data.secondary.token,
      netskope_gw_bgp_metric       = "20",
      netskope_gw_asn              = var.netskope_tenant.tenant_bgp_asn,
      transit_gw_peer_inside_ip1   = local.secondary_gw_peers.inside_ip1,
      transit_gw_peer_inside_ip2   = local.secondary_gw_peers.inside_ip2
    }
  )
  key_name = var.aws_instance.keypair

  dynamic "network_interface" {
    for_each = keys(var.netskope_gateway_config.gateway_data.secondary.interfaces)
    content {
      network_interface_id = var.netskope_gateway_config.gateway_data.secondary.interfaces[network_interface.value].id
      device_index         = network_interface.key
    }
  }

  tags = {
    Name = join("-", ["HA", var.netskope_tenant.tenant_id])
  }
}