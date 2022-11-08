#------------------------------------------------------------------------------
#  Copyright (c) 2022 Netskope Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
##################################
##  AWS VPC Specific Variables  ##
##################################

aws_network_config = {
  create_vpc = true
  region     = "ap-southeast-2"
  vpc_cidr   = "172.32.0.0/16"
  primary_gw_subnets = {
    ge1 = {
      subnet_cidr = "172.32.1.0/28"
    }
    ge2 = {
      subnet_cidr = "172.32.1.16/28"
    }
  }
  secondary_gw_subnets = {
    ge1 = {
      subnet_cidr = "172.32.1.48/28"
    }
    ge2 = {
      subnet_cidr = "172.32.1.64/28"
    }
  }
}

################################
##  AWS Transit GW Variables  ##
################################

aws_transit_gw = {
  create_transit_gw     = true
  tgw_asn               = "64513"
  tgw_cidr              = "192.0.1.0/24"
  primary_inside_cidr   = "169.254.101.0/29"
  secondary_inside_cidr = "169.254.101.8/29"
}

###################################################
##  Netskope Borderless SD-WAN Tenant Variables  ##
###################################################

netskope_tenant = {
  tenant_id      = "60675"
  tenant_url     = "https://example.infiot.net"
  tenant_token   = "WzEwPSJd"
  tenant_bgp_asn = "400"
}

netskope_gateway_config = {
  ha_enabled     = true
  gateway_policy = "aws-gw-ap2"
  gateway_name   = "aws-gw-ap2"
  gateway_role   = "hub"
}

##############################
##  AWS Instance Variables  ##
##############################

aws_instance = {
  keypair = "test"
}

clients = {
  create_clients = true
}