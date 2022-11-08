#------------------------------------------------------------------------------
#  Copyright (c) 2022 Netskope Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
##################################
##  AWS VPC Specific Variables  ##
##################################

aws_network_config = {
  create_vpc = false
  vpc_id     = "vpc-064378cc401df95e5"
  region     = "ap-southeast-2"
  primary_gw_subnets = {
    ge1 = {
      subnet_cidr = "172.17.1.0/27"
    }
    ge2 = {
      subnet_cidr = "172.17.1.32/27"
    }
    ge3 = {
      subnet_cidr = "172.17.1.64/27"
    }
  }
  secondary_gw_subnets = {
    ge1 = {
      subnet_cidr = "172.17.1.96/27"
    }
    ge2 = {
      subnet_cidr = "172.17.1.128/27"
    }
    ge3 = {
      subnet_cidr = "172.17.1.160/27"
    }
  }
}

################################
##  AWS Transit GW Variables  ##
################################

aws_transit_gw = {
  create_transit_gw = false
  tgw_id            = "tgw-084a9cb2bf3d8484f"
}

###################################################
##  Netskope Borderless SD-WAN Tenant Variables  ##
###################################################

netskope_tenant = {
  tenant_id      = "606787aaac"
  tenant_url     = "https://example.infiot.net"
  tenant_token   = "WzEsIjYzNWNhZjSJd"
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
  keypair = "venky"
}

clients = {
  create_clients = true
}
