#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

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
  primary_gw_enabled_interfaces = {
    for intf, subnet in var.aws_network_config.primary_gw_subnets :
    intf => subnet if subnet != null
  }
  secondary_gw_enabled_interfaces = {
    for intf, subnet in var.aws_network_config.secondary_gw_subnets :
    intf => subnet if subnet != null
  }
  primary_public_overlay_interfaces = {
    for intf, subnet in local.primary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "public"
  }
  primary_private_overlay_interfaces = {
    for intf, subnet in local.primary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "private"
  }
  secondary_public_overlay_interfaces = {
    for intf, subnet in local.secondary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "public"
  }
  secondary_private_overlay_interfaces = {
    for intf, subnet in local.secondary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "private"
  }

  primary_non_overlay_interfaces   = setsubtract(keys(local.primary_gw_enabled_interfaces), keys(merge(local.primary_public_overlay_interfaces, local.primary_private_overlay_interfaces)))
  primary_lan_interfaces           = length(local.primary_non_overlay_interfaces) != 0 ? local.primary_non_overlay_interfaces : keys(local.primary_private_overlay_interfaces)
  secondary_non_overlay_interfaces = setsubtract(keys(local.secondary_gw_enabled_interfaces), keys(merge(local.secondary_public_overlay_interfaces, local.secondary_private_overlay_interfaces)))
  secondary_lan_interfaces         = length(local.secondary_non_overlay_interfaces) != 0 ? local.secondary_non_overlay_interfaces : keys(local.secondary_private_overlay_interfaces)
}

locals {
  gateway_gre_config = {
    primary_gw_inside_ip   = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 1), "")
    secondary_gw_inside_ip = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 1), "")
  }
}