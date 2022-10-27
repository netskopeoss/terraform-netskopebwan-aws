#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
###########################
## Netskope GW Variables ##
###########################

variable "netskope_ha_enable" {
  type = bool
}

variable "netskope_tenant" {
  type = map(any)
}

variable "transit_gateway_config" {
  type = map(any)
}

variable "nsg_config" {
  type = map(any)
}

variable "primary_gw_interfaces" {
  type = map(any)
}

variable "secondary_gw_interfaces" {
  type = map(any)
}