#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

data "aws_ami" "netskope_gw_image_id" {
  most_recent = true
  owners      = [var.aws_instance["ami_owner"]]

  filter {
    name   = "name"
    values = [join("", [var.aws_instance["ami_name"], "*"])]
  }
}

locals {
  netskope_gw_image_id = data.aws_ami.netskope_gw_image_id.image_id
}