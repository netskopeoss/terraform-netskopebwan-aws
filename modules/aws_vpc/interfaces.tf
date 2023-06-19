#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  netskope_gateway_interfaces = flatten([
    for gateway, interfaces in local.netskope_gateways: [
      for interface in interfaces.interfaces : interface
    ]
  ])
}

resource "aws_network_interface" "netskope_sdwan_gw_ip" {
  for_each = { for index, interface in local.netskope_gateway_interfaces : interface.eniname => interface }
  subnet_id = each.value.gateway_index % 2 == 1 ? local.primary_zone_subnets[each.value.logical_name] : local.secondary_zone_subnets[each.value.logical_name]
  security_groups = contains(keys(local.public_overlay_interfaces), each.value.logical_name) ? [aws_security_group.netskope_sdwan_gw_public_sg.id] : [aws_security_group.netskope_sdwan_gw_private_sg.id]
  source_dest_check = contains(keys(local.public_overlay_interfaces), each.value.logical_name) ? false : true
  tags = {
    Name = join("-", [upper(each.key), var.netskope_tenant.tenant_id])
  }
}

resource "aws_eip" "netskope_sdwan_gw_eip" {
  for_each = { for index, interface in local.netskope_gateway_interfaces : interface.eniname => interface if interface.overlay == "public"}
  vpc = true
  network_interface         = aws_network_interface.netskope_sdwan_gw_ip[each.key].id
  associate_with_private_ip = tolist(aws_network_interface.netskope_sdwan_gw_ip[each.key].private_ips)[0]
  tags = {
    Name = join("-", [upper(each.key), var.netskope_tenant.tenant_id])
  }
}