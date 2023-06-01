#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  primary_gw_peers = {
    inside_ip1 = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 2), "")
    inside_ip2 = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 3), "")
  }
  secondary_gw_peers = {
    inside_ip1 = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 2), "")
    inside_ip2 = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 3), "")
  }
}

resource "aws_instance" "netskope_sdwan_gw_instance" {
  for_each = {
    for name, element in var.netskope_gateway_config.gateway_data : name => element
  }
  ami               = local.netskope_gw_image_id
  instance_type     = var.aws_instance.instance_type
  availability_zone = each.value.gateway_index % 2 == 1 ? var.aws_network_config.primary_zone : var.aws_network_config.secondary_zone
  user_data = templatefile("modules/aws_ec2/scripts/user-data.sh",
    {
      netskope_gw_default_password = var.netskope_gateway_config.gateway_password,
      netskope_tenant_url          = var.netskope_tenant.tenant_url,
      netskope_gw_activation_key   = each.value.token.token,
      netskope_gw_bgp_metric       = var.netskope_gateway_config.gateway_mode == "LB" ? var.netskope_gateway_config.gateway_bgp_med : (var.netskope_gateway_config.gateway_bgp_med * each.value.gateway_index),
      netskope_gw_asn              = var.netskope_tenant.tenant_bgp_asn,
      transit_gw_peer_inside_ip1   = try(cidrhost(each.value.inside_cidr, 2), "")
      transit_gw_peer_inside_ip2   = try(cidrhost(each.value.inside_cidr, 3), "")
    }
  )
  key_name = var.aws_instance.keypair

  dynamic "network_interface" {
    for_each = keys(each.value.interfaces)
    content {
      network_interface_id = var.netskope_gateway_config.gateway_data[each.key].interfaces[network_interface.value].interface.id
      device_index         = network_interface.key
    }
  }

  tags = {
    Name = join("-", [each.key, var.netskope_tenant.tenant_id])
  }
}