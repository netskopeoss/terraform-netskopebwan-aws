locals {
  primary_gw_peers = {
    inside_ip1 = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 2), "")
    inside_ip2 = try(cidrhost(var.aws_transit_gw.primary_inside_cidr, 3), "")
  }
  secondary_gw_peers = {
    inside_ip1 = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 2), "")
    inside_ip2 = try(cidrhost(var.aws_transit_gw.secondary_inside_cidr, 3), "")
  }

  primary_gw_enabled_interfaces = {
    for intf, subnet in var.aws_network_config.primary_gw_subnets :
    intf => subnet if subnet != null
  }
  secondary_gw_enabled_interfaces = {
    for intf, subnet in var.aws_network_config.secondary_gw_subnets :
    intf => subnet if subnet != null
  }
  primary_public_overlay_interfaces = {
    for intf, subnet in local.primary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "public"
  }
  primary_private_overlay_interfaces = {
    for intf, subnet in local.primary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "private"
  }
  secondary_public_overlay_interfaces = {
    for intf, subnet in local.secondary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "public"
  }
  secondary_private_overlay_interfaces = {
    for intf, subnet in local.secondary_gw_enabled_interfaces : intf => subnet if subnet.overlay == "private"
  }

  primary_non_overlay_interfaces   = setsubtract(keys(local.primary_gw_enabled_interfaces), keys(merge(local.primary_public_overlay_interfaces, local.primary_private_overlay_interfaces)))
  primary_lan_interfaces           = length(local.primary_non_overlay_interfaces) != 0 ? local.primary_non_overlay_interfaces : keys(local.primary_private_overlay_interfaces)
  secondary_non_overlay_interfaces = setsubtract(keys(local.secondary_gw_enabled_interfaces), keys(merge(local.secondary_public_overlay_interfaces, local.secondary_private_overlay_interfaces)))
  secondary_lan_interfaces         = length(local.secondary_non_overlay_interfaces) != 0 ? local.secondary_non_overlay_interfaces : keys(local.secondary_private_overlay_interfaces)
}

//  Policy Resource 
resource "netskopebwan_policy" "multicloud" {
  name = var.netskope_gateway_config.gateway_policy
}

// Gateway Resource 
resource "netskopebwan_gateway" "primary" {
  name  = var.netskope_gateway_config.gateway_name
  model = var.netskope_gateway_config.gateway_model
  role  = var.netskope_gateway_config.gateway_role
  assigned_policy {
    id   = resource.netskopebwan_policy.multicloud.id
    name = resource.netskopebwan_policy.multicloud.name
  }
}

# Netskope GW creation can take a few seconds to
# create all dependent services in backend
resource "time_sleep" "primary_gw_propagation" {
  create_duration = "30s"

  triggers = {
    gateway_id = netskopebwan_gateway.primary.id
  }
}

resource "netskopebwan_gateway" "secondary" {
  count = var.netskope_gateway_config.ha_enabled ? 1 : 0
  name  = "${var.netskope_gateway_config.gateway_name}-ha"
  model = var.netskope_gateway_config.gateway_model
  role  = var.netskope_gateway_config.gateway_role
  assigned_policy {
    id   = resource.netskopebwan_policy.multicloud.id
    name = resource.netskopebwan_policy.multicloud.name
  }
  depends_on = [netskopebwan_gateway.primary, time_sleep.api_delay]
}

resource "time_sleep" "secondary_gw_propagation" {
  count           = var.netskope_gateway_config.ha_enabled ? 1 : 0
  create_duration = "30s"

  triggers = {
    gateway_id = netskopebwan_gateway.secondary[0].id
  }
}

// Configure GE1 Interface
resource "netskopebwan_gateway_interface" "primary" {
  for_each   = local.primary_gw_enabled_interfaces
  gateway_id = time_sleep.primary_gw_propagation.triggers["gateway_id"]
  name       = upper(each.key)
  type       = "ethernet"
  addresses {
    address            = tolist(var.netskope_gateway_config.gateway_data.primary.interfaces[each.key].private_ips)[0]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config.dns_primary
    dns_secondary      = var.netskope_gateway_config.dns_secondary
    gateway            = cidrhost(var.aws_network_config.primary_gw_subnets[each.key].subnet_cidr, 1)
    mask               = cidrnetmask(var.aws_network_config.primary_gw_subnets[each.key].subnet_cidr)
  }
  dynamic "overlay_setting" {
    for_each = lookup(merge(local.primary_public_overlay_interfaces, local.primary_private_overlay_interfaces), each.key, "") != "" ? [1] : []
    content {
      is_backup           = false
      tx_bw_kbps          = 1000000
      rx_bw_kbps          = 1000000
      bw_measurement_mode = "manual"
      tag                 = lookup(local.primary_public_overlay_interfaces, each.key, "") != "" ? "wired" : "private"
    }
  }
  enable_nat  = lookup(local.primary_public_overlay_interfaces, each.key, "") != "" ? true : false
  mode        = "routed"
  is_disabled = false
  zone        = lookup(local.primary_public_overlay_interfaces, each.key, "") != "" ? "untrusted" : "trusted"
}

resource "netskopebwan_gateway_interface" "secondary" {
  for_each = {
    for intf, subnet in local.secondary_gw_enabled_interfaces : intf => subnet
    if var.netskope_gateway_config.ha_enabled
  }
  gateway_id = time_sleep.secondary_gw_propagation[0].triggers["gateway_id"]
  name       = upper(each.key)
  type       = "ethernet"
  addresses {
    address            = tolist(var.netskope_gateway_config.gateway_data.secondary.interfaces[each.key].private_ips)[0]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config.dns_primary
    dns_secondary      = var.netskope_gateway_config.dns_secondary
    gateway            = cidrhost(var.aws_network_config.secondary_gw_subnets[each.key].subnet_cidr, 1)
    mask               = cidrnetmask(var.aws_network_config.secondary_gw_subnets[each.key].subnet_cidr)
  }
  dynamic "overlay_setting" {
    for_each = lookup(merge(local.secondary_public_overlay_interfaces, local.secondary_private_overlay_interfaces), each.key, "") != "" ? [1] : []
    content {
      is_backup           = false
      tx_bw_kbps          = 1000000
      rx_bw_kbps          = 1000000
      bw_measurement_mode = "manual"
      tag                 = lookup(local.secondary_public_overlay_interfaces, each.key, "") != "" ? "wired" : "private"
    }
  }
  enable_nat  = lookup(local.secondary_public_overlay_interfaces, each.key, "") != "" ? true : false
  mode        = "routed"
  is_disabled = false
  zone        = lookup(local.secondary_public_overlay_interfaces, each.key, "") != "" ? "untrusted" : "trusted"
}

// Static Route
resource "netskopebwan_gateway_staticroute" "metadata_primary" {
  gateway_id  = time_sleep.primary_gw_propagation.triggers["gateway_id"]
  advertise   = true
  destination = "169.254.169.254/32"
  device      = "GE1"
  install     = true
  nhop        = cidrhost(var.aws_network_config.primary_gw_subnets[element(keys(local.primary_public_overlay_interfaces), 0)].subnet_cidr, 1)
}

resource "netskopebwan_gateway_staticroute" "metadata_secondary" {
  count       = var.netskope_gateway_config.ha_enabled ? 1 : 0
  gateway_id  = time_sleep.secondary_gw_propagation[0].triggers["gateway_id"]
  advertise   = true
  destination = "169.254.169.254/32"
  device      = "GE1"
  install     = true
  nhop        = cidrhost(var.aws_network_config.secondary_gw_subnets[element(keys(local.secondary_public_overlay_interfaces), 0)].subnet_cidr, 1)
}

resource "netskopebwan_gateway_activate" "primary" {
  gateway_id         = time_sleep.primary_gw_propagation.triggers["gateway_id"]
  timeout_in_seconds = 86400
}

resource "netskopebwan_gateway_activate" "secondary" {
  count              = var.netskope_gateway_config.ha_enabled ? 1 : 0
  gateway_id         = time_sleep.secondary_gw_propagation[0].triggers["gateway_id"]
  timeout_in_seconds = 86400
}

// BGP Peer
resource "netskopebwan_gateway_bgpconfig" "tgwpeer1_primary" {
  gateway_id = time_sleep.primary_gw_propagation.triggers["gateway_id"]
  name       = "tgw-peer-1-primary"
  neighbor   = local.primary_gw_peers.inside_ip1
  remote_as  = var.aws_transit_gw.tgw_asn
}

resource "netskopebwan_gateway_bgpconfig" "tgwpeer2_primary" {
  gateway_id = time_sleep.primary_gw_propagation.triggers["gateway_id"]
  name       = "tgw-peer-2-primary"
  neighbor   = local.primary_gw_peers.inside_ip2
  remote_as  = var.aws_transit_gw.tgw_asn
}

// BGP Peer
resource "netskopebwan_gateway_bgpconfig" "tgwpeer1_secondary" {
  count      = var.netskope_gateway_config.ha_enabled ? 1 : 0
  gateway_id = time_sleep.secondary_gw_propagation[0].triggers["gateway_id"]
  name       = "tgw-peer-1-secondary"
  neighbor   = local.secondary_gw_peers.inside_ip1
  remote_as  = var.aws_transit_gw.tgw_asn
}

resource "netskopebwan_gateway_bgpconfig" "tgwpeer2_secondary" {
  count      = var.netskope_gateway_config.ha_enabled ? 1 : 0
  gateway_id = time_sleep.secondary_gw_propagation[0].triggers["gateway_id"]
  name       = "tgw-peer-2-secondary"
  neighbor   = local.secondary_gw_peers.inside_ip2
  remote_as  = var.aws_transit_gw.tgw_asn
}