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
  default = {
    profile = "default"
    region  = "us-west-2"
  }
}

variable "aws_instance" {
  description = "AWS Instance Config"
  type        = map(any)
  default = {
    keypair       = ""
    instance_type = "t3.medium"
    ami_name      = "Infiot-Edge_R1.4.109"
    ami_owner     = "aws-marketplace"
  }
}

#######################
## AWS VPC Variables ##
#######################

variable "aws_vpc" {
  description = "Existing AWS VPC Details"
  type        = map(any)
  default = {
    id   = ""
    cidr = ""
  }
}

variable "aws_create_vpc" {
  default = false
  type    = bool
}

##########################
## AWS Subnet Variables ##
##########################

variable "aws_network_config" {
  description = "AWS Network Details"
  type        = map(any)
  default = {
    primary_gw_subnets = {
      ge1 = "" # Netskope GW's Public Subnet
      ge2 = "" # Netskope GW's Private Subnet
    }
    secondary_gw_subnets = {
      ge1 = "" # Secondary Netskope GW's Public Subnet
      ge2 = "" # Secondary Netskope GW's Private Subnet
    }
    route_table = {
      public  = "" # Existing Public Routing Table ID (Optional)
      private = "" # Existing Private Routing Table ID (Optional)
    }
  }

}

##############################
## AWS Transit GW Variables ##
##############################

variable "aws_create_transit_gw" {
  default = false
  type    = bool
}

variable "aws_transit_gw" {
  description = "AWS TGW Details"
  type        = map(any)
  default = {
    tgw_id                = ""
    tgw_cidr              = ""
    tgw_asn               = ""
    vpc_attachment        = ""
    primary_inside_cidr   = "169.254.100.0/29"
    secondary_inside_cidr = "169.254.100.8/29"
  }
}

###########################
## Netskope GW Variables ##
###########################

variable "netskope_tenant" {
  description = "Netskope Tenant Details"
  type        = map(any)
  default = {
    tenant_id      = ""
    tenant_url     = ""
    tenant_token   = ""
    tenant_bgp_asn = "400"
  }
}

variable "netskope_ha_enable" {
  default = false
  type    = bool
}

variable "netskope_gateway_config" {
  description = "Netskope Gateway Details"
  type        = map(any)
  default = {
    password          = ""
    policy            = ""
    name              = ""
    model             = ""
    role              = ""
    dns_primary       = "8.8.8.8"
    dns_secondary     = "8.8.4.4"
    primary_bgp_med   = "10" # Primary GW's BGP MED to advertise
    secondary_bgp_med = "20" # Secondary GW's BGP MED to advertise
  }
}