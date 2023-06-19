#------------------------------------------------------------------------------
#  Copyright (c) 2022 Netskope Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_connect_peer" "netskope_sdwan_primary_zone_tgw_peer" {
  for_each  = { 
    for index, interface in local.netskope_gateway_interfaces : interface.eniname => interface
    if length(local.lan_interfaces) > 0 && interface.logical_name == tolist(local.lan_interfaces)[0]
  }
  peer_address                  = tolist(aws_network_interface.netskope_sdwan_gw_ip[each.key].private_ips)[0]
  bgp_asn                       = var.netskope_tenant.tenant_bgp_asn
  inside_cidr_blocks            = [each.value.inside_cidr]
  transit_gateway_address       = cidrhost(tolist(local.aws_transit_gateway.transit_gateway_cidr_blocks)[0], each.value.gateway_index)
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.netskope_sdwan_tgw_connect[ceil(each.value.gateway_index / 4) - 1].id

  tags = {
    Name = join("-", ["BGP", each.key])
  }
  depends_on = [
    time_sleep.api_delay
  ]
}