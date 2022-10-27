// BGP Peer
resource "netskopebwan_gateway_bgpconfig" "tgwpeer1_primary" {
  gateway_id = var.nsg_config.primary_gateway_id
  name       = "tgw-peer-1-primary"
  neighbor   = var.transit_gateway_config["tgw_peer1_inside_ip1"]
  remote_as  = var.transit_gateway_config["tgw_asn"]
}

resource "netskopebwan_gateway_bgpconfig" "tgwpeer2_primary" {
  gateway_id = var.nsg_config.primary_gateway_id
  name       = "tgw-peer-2-primary"
  neighbor   = var.transit_gateway_config["tgw_peer1_inside_ip2"]
  remote_as  = var.transit_gateway_config["tgw_asn"]
}

// BGP Peer
resource "netskopebwan_gateway_bgpconfig" "tgwpeer1_secondary" {
  count      = var.netskope_ha_enable ? 1 : 0
  gateway_id = var.nsg_config.secondary_gateway_id
  name       = "tgw-peer-1-secondary"
  neighbor   = var.transit_gateway_config["tgw_peer2_inside_ip1"]
  remote_as  = var.transit_gateway_config["tgw_asn"]
}

resource "netskopebwan_gateway_bgpconfig" "tgwpeer2_secondary" {
  count      = var.netskope_ha_enable ? 1 : 0
  gateway_id = var.nsg_config.secondary_gateway_id
  name       = "tgw-peer-2-secondary"
  neighbor   = var.transit_gateway_config["tgw_peer2_inside_ip2"]
  remote_as  = var.transit_gateway_config["tgw_asn"]
}