#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

resource "aws_instance" "netskope_sdwan_gw_instance" {
  ami               = local.netskope_gw_image_id
  instance_type     = var.aws_instance["instance_type"]
  availability_zone = var.zones["primary"]
  user_data         = var.primary_gw_userdata
  key_name          = var.aws_instance["keypair"]

  network_interface {
    network_interface_id = var.primary_gw_interfaces["ge1"]["id"]
    device_index         = 0
  }

  network_interface {
    network_interface_id = var.primary_gw_interfaces["ge2"]["id"]
    device_index         = 1
  }

  tags = {
    Name = var.netskope_tenant["tenant_id"]
  }
}

resource "aws_instance" "netskope_sdwan_ha_gw_instance" {
  count             = var.netskope_ha_enable ? 1 : 0
  ami               = local.netskope_gw_image_id
  instance_type     = var.aws_instance["instance_type"]
  availability_zone = var.zones["secondary"]
  user_data         = var.secondary_gw_userdata
  key_name          = var.aws_instance["keypair"]

  network_interface {
    network_interface_id = var.secondary_gw_interfaces["ge1"]["id"]
    device_index         = 0
  }

  network_interface {
    network_interface_id = var.secondary_gw_interfaces["ge2"]["id"]
    device_index         = 1
  }

  tags = {
    Name = join("-", ["HA", var.netskope_tenant["tenant_id"]])
  }
}