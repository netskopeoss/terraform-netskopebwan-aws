#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

output "transit_gateway_output" {
  value = {
    tgw_asn               = local.transit_gateway_asn
    tgw_cidr              = local.transit_gateway_cidr_block
    tgw_connect           = aws_ec2_transit_gateway_connect.netskope_sdwan_tgw_connect.id
    primary_inside_cidr   = var.aws_transit_gw["primary_inside_cidr"]
    secondary_inside_cidr = var.aws_transit_gw["secondary_inside_cidr"]
  }
}

output "zones" {
  value = {
    primary   = local.primary_zone
    secondary = local.secondary_zone
  }
}

output "primary_gw_interfaces" {
  value = {
    ge1 = {
      ip = local.netskope_sdwan_gw1_iface1_ip,
      id = try(aws_network_interface.netskope_sdwan_gw1_iface1_ip.id, "")
    }
    ge2 = {
      ip = local.netskope_sdwan_gw1_iface2_ip,
      id = try(aws_network_interface.netskope_sdwan_gw1_iface2_ip.id, "")
    }
  }
}

output "secondary_gw_interfaces" {
  value = {
    ge1 = {
      ip = local.netskope_sdwan_gw2_iface1_ip
      id = try(aws_network_interface.netskope_sdwan_gw2_iface1_ip[0].id, "")
    }
    ge2 = {
      ip = local.netskope_sdwan_gw2_iface2_ip
      id = try(aws_network_interface.netskope_sdwan_gw2_iface2_ip[0].id, "")
    }
  }
}