#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
##################################
## Profile and Region Variables ##
##################################
variable "aws_profile" {
  description = "AWS Config Profile"
  type        = map(any)
}

#######################
## AWS VPC Variables ##
#######################

variable "aws_vpc" {
  description = "Existing AWS VPC Details"
  type        = map(any)
}

variable "aws_create_vpc" {
  type = bool
}

##########################
## AWS Subnet Variables ##
##########################

variable "aws_network_config" {
  description = "AWS Subnet Details"
  type        = map(any)
}

##############################
## AWS Transit GW Variables ##
##############################

variable "aws_create_transit_gw" {
  type = bool
}

variable "aws_transit_gw" {
  description = "AWS TGW Details"
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