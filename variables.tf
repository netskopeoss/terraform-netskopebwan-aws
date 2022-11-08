#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
#######################
## AWS VPC Variables ##
#######################

variable "aws_network_config" {
  description = "Existing AWS VPC Details"
  type = object({
    region         = optional(string, "us-east-1") # Choose the Region to deploy the resources
    create_vpc     = optional(bool, true)          # This boolean will control the GW deployment in either existing VPC or new VPC
    vpc_id         = optional(string, "")          # If the above boolean was set to true, then should NOT be empty
    vpc_cidr       = optional(string, "")          # If the "create_vpc" boolean is false, provide CIDR to create new VPC
    primary_zone   = optional(string)              # Choose the availability zones. Else it will be auto-picked
    secondary_zone = optional(string)
    primary_gw_subnets = object({ # Irrespective of new VPC or existing VPC, these subnet details are needed to identify existing Subnets and re-use them.
      ge1 = object({
        subnet_cidr = optional(string)           # Provide CIDR to create a new subnet
        overlay     = optional(string, "public") # Overlay setting
      })
      ge2 = optional(object({
        subnet_cidr = optional(string)
        overlay     = optional(string)
      }), null)
      ge3 = optional(object({
        subnet_cidr = optional(string)
        overlay     = optional(string)
      }), null)
      ge4 = optional(object({
        subnet_cidr = optional(string)
        overlay     = optional(string)
      }), null)
    })
    secondary_gw_subnets = object({ # Same as above, but for the secondary GW
      ge1 = object({
        subnet_cidr = optional(string)
        overlay     = optional(string, "public")
      })
      ge2 = optional(object({
        subnet_cidr = optional(string)
        overlay     = optional(string)
      }), null)
      ge3 = optional(object({
        subnet_cidr = optional(string)
        overlay     = optional(string)
      }), null)
      ge4 = optional(object({
        subnet_cidr = optional(string)
        overlay     = optional(string)
      }), null)
    })
    route_table = optional(object({ # Provide Route Table IDs if need to reuse the existing ones. Otherwise, new Routing table will be created
      public  = optional(string, "")
      private = optional(string, "")
    }), { public = "", private = "" })
  })
}

##############################
## AWS Transit GW Variables ##
##############################

variable "aws_transit_gw" {
  description = "AWS TGW Details"
  type = object({
    create_transit_gw     = optional(bool, true)                 # Boolean to control either new TGW creation or to use existing one
    tgw_id                = optional(string)                     # If the "create_transit_gw" boolean is set to false, this ID should not be empty
    tgw_cidr              = optional(string, "192.0.0.0/24")     # If the "create_transit_gw" boolean is set to true, this CIDR should not be empty
    tgw_asn               = optional(string, "64512")            # If the "create_transit_gw" boolean is set to true, this ASN should not be empty
    vpc_attachment        = optional(string, "")                 # VPC attachment to reuse, if you are going to reuse existing TGW which is already attached to the existing VPC
    primary_inside_cidr   = optional(string, "169.254.100.0/29") # GRE inside CIDR for Primary GW
    secondary_inside_cidr = optional(string, "169.254.100.8/29") # GRE inside CIDR for Secondary GW
  })
  default = {}
}

##################################
## Profile and Region Variables ##
##################################

variable "aws_instance" {
  description = "AWS Instance Config"
  type = object({
    keypair       = optional(string, "")
    instance_type = optional(string, "t3.medium")
    ami_name      = optional(string, "Infiot-Edge_R1.4.109")
    ami_owner     = optional(string, "aws-marketplace")
  })
  default = {
    keypair = ""
  }
}

###########################
## Netskope GW Variables ##
###########################

variable "netskope_tenant" {
  description = "Netskope Tenant Details"
  type = object({
    tenant_id      = string                  # Netskope Borderless SD-WAN Tenant UID
    tenant_url     = string                  # Netskope Borderless SD-WAN Tenant URL
    tenant_token   = string                  # Netskope Borderless SD-WAN Tenant Token
    tenant_bgp_asn = optional(string, "400") # Default Netskope SD-WAN BGP ASN
  })
}

variable "netskope_gateway_config" {
  description = "Netskope Gateway Details"
  type = object({
    ha_enabled       = optional(bool, false)         # Boolean to control HA GW deployment
    gateway_password = optional(string, "infiot")    # Default password to be useful for console login
    gateway_policy   = optional(string, "test")      # New Gateway Policy name to create
    gateway_name     = optional(string, "test")      # New Gateway name to create
    gateway_model    = optional(string, "iXVirtual") # Gateway Model
    gateway_role     = optional(string, "spoke")     # Gateway Role "spoke" or "hub"
    dns_primary      = optional(string, "8.8.8.8")   # Primary DNS
    dns_secondary    = optional(string, "8.8.4.4")   # Secondary DNS
    gateway_data     = optional(any)                 # It will be auto-computed
  })
}

###############################
## Optional Client Variables ##
###############################

variable "clients" {
  description = "Optional Client / Host VPC configuration"
  type = object({
    create_clients = optional(bool, false) # Blob to deploy optional Client in a new VPC for end to end testing.
    client_ami     = optional(string, "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server")
    vpc_cidr       = optional(string, "192.168.255.0/28")
    instance_type  = optional(string, "t3.small")
    password       = optional(string, "infiot")
    ports          = optional(list(string), ["22"])
  })
  default = {
    create_clients = false
  }
}