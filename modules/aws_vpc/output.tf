#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  tgw_primary_ip   = aws_ec2_transit_gateway_connect_peer.netskope_sdwan_tgw_connect_peer1[0].transit_gateway_address
  tgw_secondary_ip = try(aws_ec2_transit_gateway_connect_peer.netskope_sdwan_tgw_connect_peer2[0].transit_gateway_address, "")
}
output "aws_vpc_output" {
  value = {
    aws_transit_gw = {
      tgw_id           = local.aws_transit_gateway.id
      tgw_asn          = local.aws_transit_gateway.amazon_side_asn
      tgw_cidr         = local.aws_transit_gateway.transit_gateway_cidr_blocks[0]
      tgw_primary_ip   = local.tgw_primary_ip
      tgw_secondary_ip = local.tgw_secondary_ip
    }
    zones = {
      primary_zone    = local.primary_zone
      secondary_gzone = local.secondary_zone
    }
    netskope_gateway_config = {
      gateway_data = {
        primary = {
          elastic_ips = aws_eip.netskope_sdwan_primary_gw_eip
          interfaces  = aws_network_interface.netskope_sdwan_primary_gw_ip
        }
        secondary = {
          elastic_ips = aws_eip.netskope_sdwan_secondary_gw_eip
          interfaces  = aws_network_interface.netskope_sdwan_secondary_gw_ip
        }
      }
    }
  }
}

locals {
  primary-gw-gre_config = <<EOF

  ###########################################################################################
  Please follow the below steps in Netskope SD-WAN GWto create GRE tunnel to AWS Transit GW.
  ###########################################################################################

  1) Configure GRE Tunnel

      infhostd config-gre -inside-ip ${local.gateway_gre_config.primary_gw_inside_ip} \
        -inside-mask ${cidrnetmask(var.aws_transit_gw.primary_inside_cidr)} \
        -intfname gre1 \
        -local-ip ${try(tolist(aws_network_interface.netskope_sdwan_primary_gw_ip[tolist(local.primary_lan_interfaces)[0]].private_ips)[0], "")} \
        -remote-ip ${local.tgw_primary_ip} \
        -mtu 1300 \
        -phy-intfname ens6
  
  2) Restart the services

      service infhost restart
      infhostd restart-container
      EOF

  secondary-gw-gre_config = <<EOF

  ###############################################################################
  Do the similar steps in secondary Netskope SD-WAN GW also to create GRE tunnel
  ###############################################################################

  1) Configure GRE Tunnel

      infhostd config-gre -inside-ip ${local.gateway_gre_config.secondary_gw_inside_ip} \
        -inside-mask ${cidrnetmask(var.aws_transit_gw.secondary_inside_cidr)} \
        -intfname gre1 \
        -local-ip ${try(tolist(aws_network_interface.netskope_sdwan_secondary_gw_ip[tolist(local.secondary_lan_interfaces)[0]].private_ips)[0], "")} \
        -remote-ip ${local.tgw_secondary_ip} \
        -mtu 1300 \
        -phy-intfname ens6

  2) Restart the services

      service infhost restart
      infhostd restart-container
  EOF
}


output "primary-gw-gre-config" {
  value = length(local.primary_lan_interfaces) > 0 ? local.primary-gw-gre_config : null
}

output "secondary-gw-gre-config" {
  value = (length(local.secondary_lan_interfaces) > 0 && var.netskope_gateway_config.ha_enabled) ? local.secondary-gw-gre_config : null
}