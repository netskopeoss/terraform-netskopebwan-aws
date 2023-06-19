#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

output "client_instance" {
  value = {
    id = aws_instance.client_instance.id
    ip = try(var.netskope_gateway_config.gateway_data[join("-", [upper(var.netskope_gateway_config.gateway_name), "1"])].interfaces[join("-", [upper(var.netskope_gateway_config.gateway_name), "1-GE1"])].elastic_ip.public_ip, "")
  }
}
