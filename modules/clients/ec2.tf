#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

resource "aws_network_interface" "client_interface" {
  subnet_id       = aws_subnet.client_subnet.id
  security_groups = [aws_security_group.client_security_group.id]
  tags = {
    Name = join("-", ["Client-Eth0", var.netskope_tenant.tenant_id])
  }
}

data "aws_ami" "client_image" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = [join("", [var.clients.client_ami, "*"])]
  }
}

resource "aws_instance" "client_instance" {
  ami               = data.aws_ami.client_image.id
  instance_type     = var.clients.instance_type
  availability_zone = data.aws_availability_zones.aws_availability_zone.names[0]
  key_name          = var.aws_instance.keypair
  user_data = templatefile("modules/clients/scripts/user-data.sh",
    {
      password = var.clients.password
    }
  )

  network_interface {
    network_interface_id = aws_network_interface.client_interface.id
    device_index         = 0
  }

  tags = {
    Name = join("-", ["Client", var.netskope_tenant.tenant_id])
  }
}