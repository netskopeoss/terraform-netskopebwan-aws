#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

output "primary_gateway_id" {
  value = resource.netskopebwan_gateway.primary.id
}

output "secondary_gateway_id" {
  value = try(resource.netskopebwan_gateway.secondary[0].id, "")
}

output "primary_gateway_token" {
  value = resource.netskopebwan_gateway_activate.primary.token
}

output "secondary_gateway_token" {
  value = try(resource.netskopebwan_gateway_activate.secondary[0].token, "")
}

