#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

data "aws_availability_zones" "aws_availability_zone" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.aws_network_config.region]
  }
}

resource "aws_vpc" "client_vpc" {
  cidr_block = var.clients.vpc_cidr
  tags = {
    Name = join("-", ["Client-VPC", var.netskope_tenant.tenant_id])
  }
}

resource "aws_subnet" "client_subnet" {
  vpc_id            = aws_vpc.client_vpc.id
  cidr_block        = var.clients.vpc_cidr
  availability_zone = data.aws_availability_zones.aws_availability_zone.names[0]

  tags = {
    Environment = join("-", ["Client-Subnet", var.netskope_tenant.tenant_id])
  }
}

resource "aws_route_table" "client_route_table" {
  vpc_id = aws_vpc.client_vpc.id

  tags = {
    Name = join("-", ["Client-RT", var.netskope_tenant.tenant_id])
  }
}

resource "aws_route_table_association" "client_rt" {
  subnet_id      = aws_subnet.client_subnet.id
  route_table_id = aws_route_table.client_route_table.id
}

resource "aws_security_group" "client_security_group" {
  name   = join("-", ["Client-SG", var.netskope_tenant.tenant_id])
  vpc_id = aws_vpc.client_vpc.id

  ingress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join("-", ["Client-SG", var.netskope_tenant.tenant_id])
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "client_tgw_attach" {
  subnet_ids         = [aws_subnet.client_subnet.id]
  transit_gateway_id = var.aws_transit_gw.tgw_id
  vpc_id             = aws_vpc.client_vpc.id

  tags = {
    Name = join("-", ["Client-Attach", var.netskope_tenant.tenant_id])
  }
}

resource "aws_route" "netskope_sdwan_gw_tgw_route_entry" {
  route_table_id         = aws_route_table.client_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.aws_transit_gw.tgw_id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.client_tgw_attach
  ]
}