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
     # Choose the Region to deploy the resources
    region         = optional(string, "us-east-1")

    # This boolean will control the GW deployment in either existing VPC or new VPC
    create_vpc     = optional(bool, true)

    # If the above boolean was set to true, then should NOT be empty
    vpc_id         = optional(string, "")

    # If the "create_vpc" boolean is false, provide CIDR to create new VPC
    vpc_cidr       = optional(string, "")

    # Choose the availability zones. Else it will be auto-picked
    primary_zone   = optional(string)
    secondary_zone = optional(string)

    # Irrespective of new VPC or existing VPC,
    # These subnet details are needed to identify existing Subnets and re-use them.
    primary_zone_subnets = object({ 
      ge1 = optional(string, null)
      ge2 = optional(string, null)
      ge3 = optional(string, null)
      ge4 = optional(string, null)
    })
    # Same as above, but for the secondary zone
    secondary_zone_subnets = object({ 
      ge1 = optional(string, null)
      ge2 = optional(string, null)
      ge3 = optional(string, null)
      ge4 = optional(string, null)
    })
    # Provide Route Table IDs if need to reuse the existing ones. Otherwise, new Routing table will be created
    route_table = optional(object({
      public  = optional(string, "")
      private = optional(string, "")
    }), { public = "", private = "" })
  })
  validation {
    condition     = (
      (var.aws_network_config.primary_zone_subnets.ge1 != null && 
      var.aws_network_config.secondary_zone_subnets.ge1 != null) ||
      (var.aws_network_config.primary_zone_subnets.ge2 != null && 
      var.aws_network_config.secondary_zone_subnets.ge2 != null) ||
      (var.aws_network_config.primary_zone_subnets.ge3 != null && 
      var.aws_network_config.secondary_zone_subnets.ge3 != null) ||
      (var.aws_network_config.primary_zone_subnets.ge4 != null && 
      var.aws_network_config.secondary_zone_subnets.ge4 != null)
    )
    error_message = "Please provide proper subnets for both availability zones for high availability"
  }
}

##############################
## AWS Transit GW Variables ##
##############################

variable "aws_transit_gw" {
  description = "AWS TGW Details"
  type = object({
    # Boolean to control either new TGW creation or to use existing one
    create_transit_gw     = optional(bool, true)
    # If the "create_transit_gw" boolean is set to false, this ID should not be empty
    tgw_id                = optional(string, "")
    # If the "create_transit_gw" boolean is set to true, this CIDR should not be empty
    tgw_cidr              = optional(string, "192.0.0.0/24")
    # If the "create_transit_gw" boolean is set to true, this ASN should not be empty
    tgw_asn               = optional(string, "64512")
    # VPC attachment to reuse, if you are going to reuse existing TGW which is already attached to the existing VPC
    vpc_attachment        = optional(string, "")
    inside_cidr_block     = optional(string, "169.254.100.0/24")
  })
  validation {
    condition     = (
      cidrnetmask(var.aws_transit_gw.inside_cidr_block) == "255.255.255.0"
    )
    error_message = "Please provide /24 subnet possibly in 169.254.0.0/16 range for Inside CIDR block"
  }
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
    # Netskope Borderless SD-WAN Tenant UID
    tenant_id      = string
    # Netskope Borderless SD-WAN Tenant URL                
    tenant_url     = string
    # Netskope Borderless SD-WAN Tenant Token                 
    tenant_token   = string
    # Default Netskope SD-WAN BGP ASN           
    tenant_bgp_asn = optional(string, "400") 
  })
}

variable "netskope_gateway_config" {
  description = "Netskope Gateway Details"
  type = object({
    gateway_name = string
    gateway_count = optional(number, 2)
    gateway_mode = optional(string, "HA")
    gateway_bgp_med = optional(number, 10)
    # Overlay configuration
    overlay_config = object({
      ge1 = optional(string, "public")
      ge2 = optional(string, null)
      ge3 = optional(string, null)
      ge4 = optional(string, null)
    })
    # Default password to be useful for console login
    gateway_password = optional(string, "infiot")
    # Control variable to create new policy or not
    gateway_policy_create = optional(bool, true)
    # New Gateway Policy name to create
    gateway_policy_name = optional(string, "test")
    # Gateway Model
    gateway_model    = optional(string, "iXVirtual")
    # Gateway Role "spoke" or "hub"
    gateway_role     = optional(string, "spoke")
    # Primary DNS
    dns_primary      = optional(string, "8.8.8.8")
    # Secondary DNS
    dns_secondary    = optional(string, "8.8.4.4")
    # It will be auto-computed
    gateway_data   = optional(any)
  })
  //validation {
  //  condition = var.netskope_gateway_config.gateway_count % 2 == 0
  //  error_message = "Please provide even numbers of gateways to deploy with redundancy"
  //}
  validation {
    condition = contains(["HA", "LB"], upper(var.netskope_gateway_config.gateway_mode))
    error_message = "Deployment mode should be either HA or LB"
  }
}

###############################
## Optional Client Variables ##
###############################

variable "clients" {
  description = "Optional Client / Host VPC configuration"
  type = object({
    # Blob to deploy optional Client in a new VPC for end to end testing.
    create_clients = optional(bool, false)
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
