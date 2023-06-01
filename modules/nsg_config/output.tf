#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

output "nsg_config_output" {
  value = {
    netskope_gateway_config = merge(
      {
        "gateway_data" = {
            for index in range(1, var.netskope_gateway_config.gateway_count + 1) : join("-", [upper(var.netskope_gateway_config.gateway_name), index]) => merge({
              "gateway" = lookup(netskopebwan_gateway.netskope_gw, join("-", [upper(var.netskope_gateway_config.gateway_name), index]), null) 
              "token" = lookup(netskopebwan_gateway_activate.code, join("-", [upper(var.netskope_gateway_config.gateway_name), index]), null)
            },
            lookup(var.netskope_gateway_config.gateway_data, join("-", [upper(var.netskope_gateway_config.gateway_name), index]), null) 
        )}
      }
    )
  }
}