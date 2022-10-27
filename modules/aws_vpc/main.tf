#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

data "aws_availability_zones" "aws_availability_zone" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.aws_profile["region"]]
  }
}

locals {
  primary_zone   = element(coalescelist(try([var.aws_network_config["primary_gw_subnets"]["zone"]], []), [data.aws_availability_zones.aws_availability_zone.names[0]]), 0)
  secondary_zone = element(coalescelist(try([var.aws_network_config["secondary_gw_subnets"]["zone"]], []), [data.aws_availability_zones.aws_availability_zone.names[1]]), 0)
}
