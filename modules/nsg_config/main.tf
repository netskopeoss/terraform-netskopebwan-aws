#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

data "netskopebwan_policy" "multicloud" {
  count = var.netskope_gateway_config.gateway_policy_create != true ? 1 : 0
  name = var.netskope_gateway_config.gateway_policy_name
}

//  Policy Resource 
resource "netskopebwan_policy" "multicloud" {
  count = var.netskope_gateway_config.gateway_policy_create == true ? 1 : 0
  name = var.netskope_gateway_config.gateway_policy_name
}

locals {
  netskope_policy_id = element(coalescelist(data.netskopebwan_policy.multicloud.*.id, netskopebwan_policy.multicloud.*.id, [""]), 0)
}

// Gateway Resource 
resource "netskopebwan_gateway" "netskope_gw" {
  for_each = {
    for index in range(1, var.netskope_gateway_config.gateway_count + 1) : join("-", [upper(var.netskope_gateway_config.gateway_name), index]) => join("-", [upper(var.netskope_gateway_config.gateway_name), index])
  }
  name  = each.key
  model = var.netskope_gateway_config.gateway_model
  role  = var.netskope_gateway_config.gateway_role
  assigned_policy {
    id   = local.netskope_policy_id
    name = var.netskope_gateway_config.gateway_policy_name
  }
}

# Netskope GW creation can take a few seconds to
# create all dependent services in backend
resource "time_sleep" "netskope_gw_propagation" {
  for_each = {
    for index in range(1, var.netskope_gateway_config.gateway_count + 1) : join("-", [upper(var.netskope_gateway_config.gateway_name), index]) => join("-", [upper(var.netskope_gateway_config.gateway_name), index])
  }
  create_duration = "30s"

  triggers = {
    gateway_id = netskopebwan_gateway.netskope_gw[each.key].id
  }
}

locals {
  netskope_gateway_interfaces = flatten([
    for name, gateway in var.netskope_gateway_config.gateway_data: [
      for intf_name, interface in gateway.interfaces : interface
    ]
  ])
}

resource "netskopebwan_gateway_interface" "netskope_gw" {
  for_each   = { for name, elements in local.netskope_gateway_interfaces : name => elements }
  gateway_id = time_sleep.netskope_gw_propagation[each.value.gateway_name].triggers["gateway_id"]
  name       = upper(each.value.logical_name)
  type       = "ethernet"
  addresses {
    address            = tolist(each.value.interface.private_ips)[0]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config.dns_primary
    dns_secondary      = var.netskope_gateway_config.dns_secondary
    gateway            = cidrhost(each.value.subnet_cidr, 1)
    mask               = cidrnetmask(each.value.subnet_cidr)
  }
  dynamic "overlay_setting" {
    for_each = each.value.overlay == "public" || each.value.overlay == "private" ? [1] : []
    content {
      is_backup           = false
      tx_bw_kbps          = 1000000
      rx_bw_kbps          = 1000000
      bw_measurement_mode = "manual"
      tag                 = each.value.overlay == "public" ? "wired" : "private"
    }
  }
  enable_nat  = each.value.overlay == "public" ? true : false
  mode        = "routed"
  mtu         = each.value.overlay == "public" ? 1500 : 9001
  mtu_discovery         = each.value.overlay == "public" ? "auto" : "custom"
  is_disabled = false
  
  zone        = each.value.overlay == "public" ? "untrusted" : "trusted"
}

// Static Route
resource "netskopebwan_gateway_staticroute" "metadata" {
  for_each   = { for name, element in local.netskope_gateway_interfaces : name => element if element.overlay == "public" }
  gateway_id  = time_sleep.netskope_gw_propagation[each.value.gateway_name].triggers["gateway_id"]
  advertise   = false
  destination = "169.254.169.254/32"
  device      = "GE1"
  install     = true
  nhop        = cidrhost(each.value.subnet_cidr, 1) 
}

resource "netskopebwan_gateway_staticroute" "tgw" {
  for_each   = { for name, element in local.netskope_gateway_interfaces : name => element if element.lan == true }
  gateway_id  = time_sleep.netskope_gw_propagation[each.value.gateway_name].triggers["gateway_id"]
  advertise   = false
  destination = var.aws_transit_gw.tgw_cidr
  device      = upper(each.value.logical_name)
  install     = true
  nhop        = cidrhost(each.value.subnet_cidr, 1) 
}

resource "netskopebwan_gateway_activate" "code" {
  for_each = {
    for index in range(1, var.netskope_gateway_config.gateway_count + 1) : join("-", [upper(var.netskope_gateway_config.gateway_name), index]) => join("-", [upper(var.netskope_gateway_config.gateway_name), index])
  }
  gateway_id         = time_sleep.netskope_gw_propagation[each.key].triggers["gateway_id"]
  timeout_in_seconds = 86400
}

// BGP Peer
resource "netskopebwan_gateway_bgpconfig" "tgwpeer1" {
  for_each  = { 
    for name, interface in local.netskope_gateway_interfaces : name => interface if interface.lan
  }
  gateway_id = time_sleep.netskope_gw_propagation[each.value.gateway_name].triggers["gateway_id"]
  name       = "tgw-peer-1-primary"
  neighbor   = cidrhost(each.value.inside_cidr, 2)
  remote_as  = var.aws_transit_gw.tgw_asn
}

resource "netskopebwan_gateway_bgpconfig" "tgwpeer2" {
  for_each  = { 
    for name, interface in local.netskope_gateway_interfaces : name => interface if interface.lan
  }
  gateway_id = time_sleep.netskope_gw_propagation[each.value.gateway_name].triggers["gateway_id"]
  name       = "tgw-peer-2-primary"
  neighbor   = cidrhost(each.value.inside_cidr, 3)
  remote_as  = var.aws_transit_gw.tgw_asn
}
