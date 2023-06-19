#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------


locals {
  aws_interfaces = {
    for name, element in local.netskope_gateways : name => merge(
      {
        "gateway_index" = element.gateway_index
        "inside_cidr" = element.inside_cidr
      },
      {
        "interfaces" = {
          for name, interface in element.interfaces : interface.eniname => merge(
            {
              "elastic_ip" = lookup(aws_eip.netskope_sdwan_gw_eip, interface.eniname, null) 
              "interface" = lookup(aws_network_interface.netskope_sdwan_gw_ip, interface.eniname, null)
            },
            interface
          )
        }
      }
    )
  }
}

output "aws_vpc_output" {
  value = {
    aws_transit_gw = {
      tgw_id           = local.aws_transit_gateway.id
      tgw_asn          = local.aws_transit_gateway.amazon_side_asn
      tgw_cidr         = tolist(local.aws_transit_gateway.transit_gateway_cidr_blocks)[0]
    }
    zones = {
      primary_zone    = local.primary_zone
      secondary_gzone = local.secondary_zone
    }
    lan_interfaces = local.lan_interfaces
    netskope_gateway_config = {
      gateway_data = local.aws_interfaces
    }
  }
}

locals {
  netskope-gw-gre-config = {
    for index, interface in local.netskope_gateway_interfaces : interface.eniname => {
      value = <<EOF
      #############################################################################################
        Please follow the below steps in Netskope SD-WAN GWto create GRE tunnel to AWS Transit GW.
      #############################################################################################

      1) Configure GRE Tunnel

        infhostd config-gre -inside-ip ${try(cidrhost(interface.inside_cidr, 1), "")} \
          -inside-mask ${cidrnetmask(interface.inside_cidr)} \
          -intfname gre1 \
          -local-ip ${try(tolist(aws_network_interface.netskope_sdwan_gw_ip[interface.eniname].private_ips)[0], "")} \
          -remote-ip ${cidrhost(tolist(local.aws_transit_gateway.transit_gateway_cidr_blocks)[0], interface.gateway_index)} \
          -mtu 1500 \
          -phy-intfname ens6
            
      2) Restart the services

        service infhost restart
        infhostd restart-container
        EOF
    }
    if interface.overlay != "public"
  }
}

output "netskope-gw-gre-config" {
  value = length(local.lan_interfaces) > 0 ? local.netskope-gw-gre-config : null
}
