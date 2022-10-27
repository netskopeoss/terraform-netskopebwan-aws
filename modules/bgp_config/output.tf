#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
output "transit_gateway_ip" {
  value = {
    tgw_primary_ip   = local.tgw_primary_ip
    tgw_secondary_ip = local.tgw_secondary_ip
  }
}