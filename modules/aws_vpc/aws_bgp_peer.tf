#------------------------------------------------------------------------------
#  Copyright (c) 2022 Netskope Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_connect_peer" "netskope_sdwan_tgw_connect_peer1" {
  count                         = length(local.primary_lan_interfaces) > 0 ? 1 : 0
  peer_address                  = tolist(aws_network_interface.netskope_sdwan_primary_gw_ip[tolist(local.primary_lan_interfaces)[0]].private_ips)[0]
  bgp_asn                       = var.netskope_tenant.tenant_bgp_asn
  inside_cidr_blocks            = [var.aws_transit_gw.primary_inside_cidr]
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.netskope_sdwan_tgw_connect[0].id

  tags = {
    Name = join("-", ["BGP1", var.netskope_tenant.tenant_id])
  }
  depends_on = [time_sleep.api_delay]
}

resource "aws_ec2_transit_gateway_connect_peer" "netskope_sdwan_tgw_connect_peer2" {
  count                         = (length(local.secondary_lan_interfaces) > 0 && var.netskope_gateway_config.ha_enabled) ? 1 : 0
  peer_address                  = tolist(aws_network_interface.netskope_sdwan_secondary_gw_ip[tolist(local.secondary_lan_interfaces)[0]].private_ips)[0]
  bgp_asn                       = var.netskope_tenant.tenant_bgp_asn
  inside_cidr_blocks            = [var.aws_transit_gw.secondary_inside_cidr]
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.netskope_sdwan_tgw_connect[0].id

  tags = {
    Name = join("-", ["BGP2", var.netskope_tenant.tenant_id])
  }
  depends_on = [time_sleep.api_delay]
}