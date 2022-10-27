//  Policy Resource 
resource "netskopebwan_policy" "multicloud" {
  name = var.netskope_gateway_config["policy"]
}

// Gateway Resource 
resource "netskopebwan_gateway" "primary" {
  name  = var.netskope_gateway_config["name"]
  model = var.netskope_gateway_config["model"]
  role  = var.netskope_gateway_config["role"]
  assigned_policy {
    id   = resource.netskopebwan_policy.multicloud.id
    name = resource.netskopebwan_policy.multicloud.name
  }
}

resource "netskopebwan_gateway" "secondary" {
  count = var.netskope_ha_enable ? 1 : 0
  name  = "${var.netskope_gateway_config["name"]}-ha"
  model = var.netskope_gateway_config["model"]
  role  = var.netskope_gateway_config["role"]
  assigned_policy {
    id   = resource.netskopebwan_policy.multicloud.id
    name = resource.netskopebwan_policy.multicloud.name
  }
  depends_on = [netskopebwan_gateway.primary, time_sleep.api_delay]
}

// Configure GE1 Interface
resource "netskopebwan_gateway_interface" "ge1_primary" {
  gateway_id = resource.netskopebwan_gateway.primary.id
  name       = "GE1"
  type       = "ethernet"
  addresses {
    address            = var.primary_gw_interfaces["ge1"]["ip"]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config["dns_primary"]
    dns_secondary      = var.netskope_gateway_config["dns_secondary"]
    gateway            = cidrhost(var.aws_network_config["primary_gw_subnets"]["ge1"], 1)
    mask               = cidrnetmask(var.aws_network_config["primary_gw_subnets"]["ge1"])
  }
  overlay_setting {
    is_backup           = false
    tx_bw_kbps          = 1000000
    rx_bw_kbps          = 1000000
    bw_measurement_mode = "manual"
    tag                 = "wired"
  }
  enable_nat  = true
  mode        = "routed"
  is_disabled = false
  zone        = "trusted"
}

// Enable GE2 LAN Interface
resource "netskopebwan_gateway_interface" "ge2_primary" {
  gateway_id = resource.netskopebwan_gateway.primary.id
  name       = "GE2"
  type       = "ethernet"
  addresses {
    address            = var.primary_gw_interfaces["ge2"]["ip"]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config["dns_primary"]
    dns_secondary      = var.netskope_gateway_config["dns_secondary"]
    gateway            = cidrhost(var.aws_network_config["primary_gw_subnets"]["ge2"], 1)
    mask               = cidrnetmask(var.aws_network_config["primary_gw_subnets"]["ge2"])
  }
  mode        = "routed"
  is_disabled = false
  zone        = "trusted"
}

resource "netskopebwan_gateway_interface" "ge1_secondary" {
  count      = var.netskope_ha_enable ? 1 : 0
  gateway_id = resource.netskopebwan_gateway.secondary[0].id
  name       = "GE1"
  type       = "ethernet"
  mode       = "routed"
  addresses {
    address            = var.secondary_gw_interfaces["ge1"]["ip"]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config["dns_primary"]
    dns_secondary      = var.netskope_gateway_config["dns_secondary"]
    gateway            = cidrhost(var.aws_network_config["secondary_gw_subnets"]["ge1"], 1)
    mask               = cidrnetmask(var.aws_network_config["secondary_gw_subnets"]["ge1"])
  }
  overlay_setting {
    is_backup           = false
    tx_bw_kbps          = 1000000
    rx_bw_kbps          = 1000000
    bw_measurement_mode = "manual"
    tag                 = "wired"
  }
  enable_nat  = true
  is_disabled = false
  zone        = "trusted"
}

resource "netskopebwan_gateway_interface" "ge2_secondary" {
  count      = var.netskope_ha_enable ? 1 : 0
  gateway_id = resource.netskopebwan_gateway.secondary[0].id
  name       = "GE2"
  type       = "ethernet"
  mode       = "routed"
  addresses {
    address            = var.secondary_gw_interfaces["ge2"]["ip"]
    address_assignment = "static"
    address_family     = "ipv4"
    dns_primary        = var.netskope_gateway_config["dns_primary"]
    dns_secondary      = var.netskope_gateway_config["dns_secondary"]
    gateway            = cidrhost(var.aws_network_config["secondary_gw_subnets"]["ge2"], 1)
    mask               = cidrnetmask(var.aws_network_config["secondary_gw_subnets"]["ge2"])
  }
  is_disabled = false
  zone        = "trusted"
}

// Static Route
resource "netskopebwan_gateway_staticroute" "metadata_primary" {
  gateway_id  = resource.netskopebwan_gateway.primary.id
  advertise   = true
  destination = "169.254.169.254/32"
  device      = "GE1"
  install     = true
  nhop        = cidrhost(var.aws_network_config["primary_gw_subnets"]["ge1"], 1)
}

resource "netskopebwan_gateway_staticroute" "metadata_secondary" {
  count       = var.netskope_ha_enable ? 1 : 0
  gateway_id  = resource.netskopebwan_gateway.secondary[0].id
  advertise   = true
  destination = "169.254.169.254/32"
  device      = "GE1"
  install     = true
  nhop        = cidrhost(var.aws_network_config["secondary_gw_subnets"]["ge1"], 1)
}

resource "netskopebwan_gateway_activate" "primary" {
  gateway_id         = resource.netskopebwan_gateway.primary.id
  timeout_in_seconds = 86400
}

resource "netskopebwan_gateway_activate" "secondary" {
  count              = var.netskope_ha_enable ? 1 : 0
  gateway_id         = resource.netskopebwan_gateway.secondary[0].id
  timeout_in_seconds = 86400
}