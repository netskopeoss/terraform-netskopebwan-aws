#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
/*locals {
  netskope_sdwan_primary_gw_ip = {
    for intf, subnet in local.primary_gw_enabled_interfaces :
    intf => try(cidrhost(local.primary_gw_enabled_interfaces[intf], -2), "")
  }
  netskope_sdwan_secondary_gw_ip = {
    for intf, subnet in local.secondary_gw_enabled_interfaces :
    intf => try(cidrhost(local.secondary_gw_enabled_interfaces[intf], -2), "")
  }
}*/

resource "aws_network_interface" "netskope_sdwan_primary_gw_ip" {
  for_each  = local.primary_gw_enabled_interfaces
  subnet_id = local.primary_gw_subnets[each.key]
  #private_ips     = [local.netskope_sdwan_primary_gw_ip[each.key]]
  security_groups = contains(keys(local.primary_public_overlay_interfaces), each.key) ? [aws_security_group.netskope_sdwan_gw_public_sg.id] : [aws_security_group.netskope_sdwan_gw_private_sg.id]
  tags = {
    Name = join("-", ["Primary", upper(each.key), var.netskope_tenant.tenant_id])
  }
}

resource "aws_network_interface" "netskope_sdwan_secondary_gw_ip" {
  for_each  = var.netskope_gateway_config.ha_enabled ? local.secondary_gw_enabled_interfaces : {}
  subnet_id = local.secondary_gw_subnets[each.key]
  #private_ips       = [local.netskope_sdwan_secondary_gw_ip[each.key]]
  security_groups   = contains(keys(local.secondary_public_overlay_interfaces), each.key) ? [aws_security_group.netskope_sdwan_gw_public_sg.id] : [aws_security_group.netskope_sdwan_gw_private_sg.id]
  source_dest_check = false
  tags = {
    Name = join("-", ["Secondary", upper(each.key), var.netskope_tenant.tenant_id])
  }
}

resource "aws_eip" "netskope_sdwan_primary_gw_eip" {
  for_each                  = local.primary_public_overlay_interfaces
  vpc                       = true
  network_interface         = aws_network_interface.netskope_sdwan_primary_gw_ip[each.key].id
  associate_with_private_ip = tolist(aws_network_interface.netskope_sdwan_primary_gw_ip[each.key].private_ips)[0]
  tags = {
    Name = join("-", ["Primary", upper(each.key), var.netskope_tenant.tenant_id])
  }
}

resource "aws_eip" "netskope_sdwan_secondary_gw_eip" {
  for_each                  = var.netskope_gateway_config.ha_enabled ? local.secondary_public_overlay_interfaces : {}
  vpc                       = true
  network_interface         = aws_network_interface.netskope_sdwan_secondary_gw_ip[each.key].id
  associate_with_private_ip = tolist(aws_network_interface.netskope_sdwan_secondary_gw_ip[each.key].private_ips)[0]
  tags = {
    Name = join("-", ["Secondary", upper(each.key), var.netskope_tenant.tenant_id])
  }
}