// BGP Peer
resource "netskopebwan_gateway_port_forward" "client" {
  for_each        = toset(var.clients.ports)
  gateway_id      = var.netskope_gateway_config.gateway_data.primary.id
  name            = join("-", ["client", each.key])
  bi_directional  = false
  lan_ip          = tolist(aws_network_interface.client_interface.private_ips)[0]
  lan_port        = each.key
  public_ip       = var.netskope_gateway_config.gateway_data.primary.elastic_ips[keys(var.netskope_gateway_config.gateway_data.primary.elastic_ips)[0]].public_ip
  public_port     = sum([2000, tonumber(each.key)])
  up_link_if_name = upper(keys(var.netskope_gateway_config.gateway_data.primary.elastic_ips)[0])
}