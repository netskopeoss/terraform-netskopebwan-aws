#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_network_config.region
}

data "aws_availability_zones" "aws_availability_zone" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.aws_network_config.region]
  }
}

locals {
  primary_zone   = var.aws_network_config.primary_zone != null ? var.aws_network_config.primary_zone : data.aws_availability_zones.aws_availability_zone.names[0]
  secondary_zone = var.aws_network_config.secondary_zone != null ? var.aws_network_config.secondary_zone : data.aws_availability_zones.aws_availability_zone.names[1]
}

locals {
  primary_zone_enabled_interfaces = {
    for intf, subnet in var.aws_network_config.primary_zone_subnets :
    intf => subnet if subnet != null
  }
  secondary_zone_enabled_interfaces = {
    for intf, subnet in var.aws_network_config.secondary_zone_subnets :
    intf => subnet if subnet != null
  }
  public_overlay_interfaces = {
    for intf, subnet in local.primary_zone_enabled_interfaces : intf => subnet if var.netskope_gateway_config.overlay_config[intf] == "public"
  }
  private_overlay_interfaces = {
    for intf, subnet in local.primary_zone_enabled_interfaces : intf => subnet if var.netskope_gateway_config.overlay_config[intf] == "private"
  }
  non_overlay_interfaces   = setsubtract(keys(local.primary_zone_enabled_interfaces), keys(merge(local.public_overlay_interfaces, local.private_overlay_interfaces)))
  lan_interfaces           = length(local.non_overlay_interfaces) != 0 ? local.non_overlay_interfaces : keys(local.private_overlay_interfaces)
}

locals {
  netskope_gateways = merge({
      for gateway in range(1, (var.netskope_gateway_config.gateway_count) + 1): 
        join("-", [upper(var.netskope_gateway_config.gateway_name), tostring(gateway)]) => merge(
        {
          "gateway_index" = gateway
          "inside_cidr" = cidrsubnet(var.aws_transit_gw.inside_cidr_block, 5, gateway - 1)
        }, 
        {
          "interfaces" = {
          for intf, subnet in local.primary_zone_enabled_interfaces:
            upper(intf) => {
              "logical_name" = intf
              "gateway_index" = gateway
              "overlay" = var.netskope_gateway_config.overlay_config[intf]
              "subnet_cidr" = var.aws_network_config.primary_zone_subnets[intf]
              "inside_cidr" = cidrsubnet(var.aws_transit_gw.inside_cidr_block, 5, gateway - 1)
              "lan" = try(element(tolist(local.lan_interfaces), 0), "") == intf ? true : false
              "gateway_name" = join("-", [upper(var.netskope_gateway_config.gateway_name), tostring(gateway)])
              "eniname" = join("-", [upper(var.netskope_gateway_config.gateway_name), tostring(gateway), upper(intf)])
            }
          }
        })
      if gateway % 2 == 1
    },
    {
      for gateway in range(1, (var.netskope_gateway_config.gateway_count) + 1): 
        join("-", [upper(var.netskope_gateway_config.gateway_name), tostring(gateway)]) => merge(
        {
          "gateway_index" = gateway
          "inside_cidr" = cidrsubnet(var.aws_transit_gw.inside_cidr_block, 5, gateway - 1)
        }, 
        {
          "interfaces" = {
          for intf, subnet in local.secondary_zone_enabled_interfaces:
            upper(intf) => {
              "gateway_index" = gateway
              "eniname" = join("-", [upper(var.netskope_gateway_config.gateway_name), tostring(gateway), upper(intf)])
              "subnet_cidr" = var.aws_network_config.secondary_zone_subnets[intf]
              "inside_cidr" = cidrsubnet(var.aws_transit_gw.inside_cidr_block, 5, gateway - 1)
              "gateway_name" = join("-", [upper(var.netskope_gateway_config.gateway_name), tostring(gateway)])
              "overlay" = var.netskope_gateway_config.overlay_config[intf]
              "logical_name" = intf
              "lan" = try(element(tolist(local.lan_interfaces), 0), "") == intf ? true : false
            }
          }
        })
      if gateway % 2 == 0
    }
  )
}

