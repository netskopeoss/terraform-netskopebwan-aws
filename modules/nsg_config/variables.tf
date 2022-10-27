#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
##########################
## AWS Subnet Variables ##
##########################

variable "aws_network_config" {
  description = "AWS Subnet Details"
  type        = map(any)
}

###########################
## Netskope GW Variables ##
###########################

variable "netskope_ha_enable" {
  type = bool
}

variable "netskope_gateway_config" {
  description = "Netskope Gateway Details"
  type        = map(any)
}

variable "primary_gw_interfaces" {
  type = map(any)
}

variable "secondary_gw_interfaces" {
  type = map(any)
}