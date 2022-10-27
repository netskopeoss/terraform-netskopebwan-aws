#------------------------------------------------------------------------------
#  Copyright (c) 2022 Netskope Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

######################
## Region Variables ##
######################

aws_profile = {
  access_key = "AKI***Z"        # AWS_ACCESS_KEY_ID
  secret_key = "AU******Z7S"    # AWS_SECRET_KEY
  region     = "ap-southeast-1" # AWS Region to deploy resources
}

##############################
##  AWS Instance Variables  ##
##############################

aws_instance = {
  instance_type = "t3.medium" # AWS Instance Type
  keypair       = ""          # AWS Key Pair
  ami_name      = "Infiot-Edge_R1.4.109"
  ami_owner     = "aws-marketplace"
}

##################################
##  AWS VPC Specific Variables  ##
##################################

aws_create_vpc = false # Create new VPC if set to TRUE

aws_vpc = {
  id   = "vpc-0089a45cd3d784240" # Existing VPC ID to use (Optional)
  cidr = "172.31.0.0/16"         # VPC CIDR (Required)
}

##########################
## AWS Subnet Variables ##
##########################

aws_network_config = {
  primary_gw_subnets = {
    zone = "ap-southeast-1c"
    ge1  = "172.31.1.0/28"  # Netskope GW's Public Subnet
    ge2  = "172.31.1.16/28" # Netskope GW's Private Subnet
  }
  secondary_gw_subnets = {
    zone = "ap-southeast-1a"
    ge1  = "172.31.1.32/28" # Secondary Netskope GW's Public Subnet
    ge2  = "172.31.1.48/28" # Secondary Netskope GW's Private Subnet
  }
  route_table = {
    public  = ""                      # Existing Public Routing Table ID (Optional)
    private = "rtb-01ef470747b775800" # Existing Private Routing Table ID (Optional)
  }
}

################################
##  AWS Transit GW Variables  ##
################################

aws_create_transit_gw = false # Create new Transit GW if set to TRUE

aws_transit_gw = {
  tgw_id                = "tgw-037b1ce5388935b05" # Existing Transit GW ID
  tgw_cidr              = "192.1.1.0/24"          # Existing or New Transit GW CIDR
  tgw_asn               = "65100"                 # New Transit GW CIDR
  vpc_attachment        = ""                      # Existing VPC Attachment to use if deploying in existing subnets
  primary_inside_cidr   = "169.254.100.0/29"      # Primary GW's GRE Inside CIDR
  secondary_inside_cidr = "169.254.100.8/29"      # Secondary GW's GRE Inside CIDR
}

###################################################
##  Netskope Borderless SD-WAN Tenant Variables  ##
###################################################

netskope_ha_enable = true # Deploy Secondary Netskope GW for HA

netskope_tenant = {
  tenant_id      = "6067581c27b2dc0de587aaac"       # Netskope Borderless SD-WAN Tenant ID
  tenant_url     = "https://demo.stage1.infiot.net" # Netskope Borderless SD-WAN Tenant URL
  tenant_token   = "WzEs********d"                  # Netskope Borderless SD-WAN Tenant Token
  tenant_bgp_asn = "400"
}

netskope_gateway_config = {
  password          = "infiot"             # Default Login password for EC2 instances
  policy            = "Multi-Cloud-Policy" # New Netskope SD-WAN Policy Name
  name              = "decathlon"          # Netskope SD-WAN Gateway Name
  model             = "iXVirtual"          # Netskope SD-WAN Model
  role              = "spoke"              # Netskope SD-WAN Role
  dns_primary       = "8.8.8.8"            # Netskope SD-WAN GW primary DNS
  dns_secondary     = "8.8.4.4"            # Netskope SD-WAN GW secondary DNS
  primary_bgp_med   = "10"                 # Primary GW's BGP MED to advertise
  secondary_bgp_med = "20"                 # Secondary GW's BGP MED to advertise
}