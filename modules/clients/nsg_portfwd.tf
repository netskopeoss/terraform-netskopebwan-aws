// BGP Peer
resource "netskopebwan_gateway_port_forward" "client" {
  for_each        = toset(var.clients.ports)
  gateway_id      = var.netskope_gateway_config.gateway_data[join("-", [upper(var.netskope_gateway_config.gateway_name), "1"])].gateway.id
  name            = join("-", ["client", each.key])
  bi_directional  = false
  lan_ip          = tolist(aws_network_interface.client_interface.private_ips)[0]
  lan_port        = each.key
  public_ip       = var.netskope_gateway_config.gateway_data[join("-", [upper(var.netskope_gateway_config.gateway_name), "1"])].interfaces[join("-", [upper(var.netskope_gateway_config.gateway_name), "1-GE1"])].elastic_ip.public_ip
  public_port     = sum([2000, tonumber(each.key)])
  up_link_if_name = "GE1"
}