#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

output "client_instance" {
  value = {
    id = aws_instance.client_instance.id
    ip = try(var.netskope_gateway_config.gateway_data.primary.elastic_ips[keys(var.netskope_gateway_config.gateway_data.primary.elastic_ips)[0]].public_ip, "")
  }
}