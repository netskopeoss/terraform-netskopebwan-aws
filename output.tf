#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
locals {
  client-login = <<EOF

  ###########################################################################################
  ##  Since you have opt'ed to deploy a demo client, here are the login details of client  ##
  ##  to experience end to end testing
  ###########################################################################################

  To access the client, Primary GW has already been setup with required Port-forwarding configurations.

  Login Details :
  ---------------

         Public IP : ${try(module.clients[0].client_instance.ip, "")}
         Username  : ubuntu
         Password  : ${var.clients.password}

  EOF
}


output "primary-gw-gre-config" {
  value = module.aws_vpc.primary-gw-gre-config
}

output "secondary-gw-gre-config" {
  value = module.aws_vpc.secondary-gw-gre-config
}

output "client-details" {
  value = var.clients.create_clients ? local.client-login : null
}