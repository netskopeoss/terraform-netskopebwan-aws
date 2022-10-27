#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
##################################
## Profile and Region Variables ##
##################################
variable "aws_instance" {
  description = "AWS Instance Config"
  type        = map(any)
}

###########################
## Netskope GW Variables ##
###########################

variable "netskope_ha_enable" {
  type = bool
}

variable "netskope_tenant" {
  description = "Netskope Tenant Details"
  type        = map(any)
}

variable "primary_gw_interfaces" {
  type = map(any)
}

variable "secondary_gw_interfaces" {
  type = map(any)
}

variable "primary_gw_userdata" {
  type = string
}

variable "secondary_gw_userdata" {
  type = string
}

variable "zones" {
  type = map(any)
}