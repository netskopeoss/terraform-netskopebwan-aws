#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

locals {
  primary-gw-gre_config = <<EOF
  Please follow the below steps in Netskope SD-WAN GWto create GRE tunnel to AWS Transit GW.

  1) Configure GRE Tunnel

      infhostd config-gre -inside-ip ${local.primary_gw_gre_inside_ip} \
        -inside-mask ${cidrnetmask(var.aws_transit_gw["primary_inside_cidr"])} \
        -intfname gre1 \
        -local-ip ${module.aws_vpc.primary_gw_interfaces["ge2"]["ip"]} \
        -remote-ip ${module.bgp_config.transit_gateway_ip["tgw_primary_ip"]} \
        -mtu 1300 \
        -phy-intfname ens6
  
  2) Restart the services

      service infhost restart
      infhostd restart-container
      EOF

  secondary-gw-gre_config = <<EOF
  Please execute the following command  to create GRE tunnel to AWS Transit GW.
  Please follow the below steps in secondary Netskope SD-WAN GW to create GRE tunnel to AWS Transit GW.

  1) Configure GRE Tunnel

      infhostd config-gre -inside-ip ${local.secondary_gw_gre_inside_ip} \
        -inside-mask ${cidrnetmask(var.aws_transit_gw["secondary_inside_cidr"])} \
        -intfname gre1 \
        -local-ip ${module.aws_vpc.secondary_gw_interfaces["ge2"]["ip"]} \
        -remote-ip ${module.bgp_config.transit_gateway_ip["tgw_secondary_ip"]} \
        -mtu 1300 \
        -phy-intfname ens6

  2) Restart the services

      service infhost restart
      infhostd restart-container
  EOF
}

output "primary-gw-gre_config" {
  value = local.primary-gw-gre_config
}

output "secondary-gw-gre_config" {
  value = var.netskope_ha_enable ? local.secondary-gw-gre_config : null
}