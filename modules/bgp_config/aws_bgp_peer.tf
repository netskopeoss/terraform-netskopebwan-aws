#------------------------------------------------------------------------------
#  Copyright (c) 2022 Netskope Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  tgw_primary_ip   = cidrhost(var.transit_gateway_config["tgw_cidr"], -2)
  tgw_secondary_ip = cidrhost(var.transit_gateway_config["tgw_cidr"], -3)
}
resource "aws_ec2_transit_gateway_connect_peer" "netskope_sdwan_tgw_connect_peer1" {
  peer_address                  = var.primary_gw_interfaces["ge2"]["ip"]
  bgp_asn                       = var.netskope_tenant["tenant_bgp_asn"]
  transit_gateway_address       = local.tgw_primary_ip
  inside_cidr_blocks            = [var.transit_gateway_config["primary_inside_cidr"]]
  transit_gateway_attachment_id = var.transit_gateway_config["tgw_connect"]

  tags = {
    Name = join("-", ["BGP1", var.netskope_tenant["tenant_id"]])
  }
  depends_on = [time_sleep.api_delay]
}

resource "aws_ec2_transit_gateway_connect_peer" "netskope_sdwan_tgw_connect_peer2" {
  count                         = var.netskope_ha_enable ? 1 : 0
  peer_address                  = var.secondary_gw_interfaces["ge2"]["ip"]
  bgp_asn                       = var.netskope_tenant["tenant_bgp_asn"]
  transit_gateway_address       = local.tgw_secondary_ip
  inside_cidr_blocks            = [var.transit_gateway_config["secondary_inside_cidr"]]
  transit_gateway_attachment_id = var.transit_gateway_config["tgw_connect"]

  tags = {
    Name = join("-", ["BGP2", var.netskope_tenant["tenant_id"]])
  }
  depends_on = [time_sleep.api_delay]
}