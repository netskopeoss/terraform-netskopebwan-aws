#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
locals {
  netskope_sdwan_gw1_iface1_ip = try(cidrhost(var.aws_network_config["primary_gw_subnets"]["ge1"], -2), "")
  netskope_sdwan_gw1_iface2_ip = try(cidrhost(var.aws_network_config["primary_gw_subnets"]["ge2"], -2), "")
  netskope_sdwan_gw2_iface1_ip = try(cidrhost(var.aws_network_config["secondary_gw_subnets"]["ge1"], -2), "")
  netskope_sdwan_gw2_iface2_ip = try(cidrhost(var.aws_network_config["secondary_gw_subnets"]["ge2"], -2), "")
}

resource "aws_network_interface" "netskope_sdwan_gw1_iface1_ip" {
  subnet_id       = local.netskope_sdwan_primary_public_subnet
  private_ips     = [local.netskope_sdwan_gw1_iface1_ip]
  security_groups = [aws_security_group.netskope_sdwan_gw_public_sg.id]
  tags = {
    Name = join("-", [var.netskope_tenant["tenant_id"], "Primary-Eth0"])
  }
}

resource "aws_network_interface" "netskope_sdwan_gw1_iface2_ip" {
  subnet_id         = local.netskope_sdwan_primary_private_subnet
  private_ips       = [local.netskope_sdwan_gw1_iface2_ip]
  security_groups   = [aws_security_group.netskope_sdwan_gw_private_sg.id]
  source_dest_check = false
  tags = {
    Name = join("-", [var.netskope_tenant["tenant_id"], "Primary-Eth1"])
  }
}

resource "aws_network_interface" "netskope_sdwan_gw2_iface1_ip" {
  count           = var.netskope_ha_enable ? 1 : 0
  subnet_id       = local.netskope_sdwan_secondary_public_subnet
  private_ips     = [local.netskope_sdwan_gw2_iface1_ip]
  security_groups = [aws_security_group.netskope_sdwan_gw_public_sg.id]
  tags = {
    Name = join("-", [var.netskope_tenant["tenant_id"], "Secondary-Eth0"])
  }
}

resource "aws_network_interface" "netskope_sdwan_gw2_iface2_ip" {
  count             = var.netskope_ha_enable ? 1 : 0
  subnet_id         = local.netskope_sdwan_secondary_private_subnet
  private_ips       = [local.netskope_sdwan_gw2_iface2_ip]
  security_groups   = [aws_security_group.netskope_sdwan_gw_private_sg.id]
  source_dest_check = false
  tags = {
    Name = join("-", [var.netskope_tenant["tenant_id"], "Secondary-Eth1"])
  }
}

resource "aws_eip" "netskope_sdwan_gw1_public_ip" {
  vpc                       = true
  network_interface         = aws_network_interface.netskope_sdwan_gw1_iface1_ip.id
  associate_with_private_ip = local.netskope_sdwan_gw1_iface1_ip
  tags = {
    Name = join("-", [var.netskope_tenant["tenant_id"], "Primary"])
  }
}

resource "aws_eip" "netskope_sdwan_gw2_public_ip" {
  count                     = var.netskope_ha_enable ? 1 : 0
  vpc                       = true
  network_interface         = aws_network_interface.netskope_sdwan_gw2_iface1_ip[0].id
  associate_with_private_ip = local.netskope_sdwan_gw2_iface1_ip
  tags = {
    Name = join("-", [var.netskope_tenant["tenant_id"], "Secondary"])
  }
}