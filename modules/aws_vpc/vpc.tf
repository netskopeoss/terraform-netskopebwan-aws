#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

data "aws_vpc" "netskope_sdwan_gw_vpc" {
  count = var.aws_create_vpc == false ? 1 : 0
  id    = var.aws_vpc["id"]
}

resource "aws_vpc" "netskope_sdwan_gw_vpc" {
  count      = var.aws_create_vpc ? 1 : 0
  cidr_block = var.aws_vpc["cidr"]
  tags = {
    Name = join("-", ["VPC", var.netskope_tenant["tenant_id"]])
  }
}

locals {
  netskope_sdwan_gw_vpc = element(coalescelist(data.aws_vpc.netskope_sdwan_gw_vpc.*.id, aws_vpc.netskope_sdwan_gw_vpc.*.id, [""]), 0)
}

data "aws_internet_gateway" "netskope_sdwan_gw_igw" {
  count = var.aws_create_vpc == false ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [local.netskope_sdwan_gw_vpc]
  }
}

resource "aws_internet_gateway" "netskope_sdwan_gw_igw" {
  count  = var.aws_create_vpc ? 1 : 0
  vpc_id = local.netskope_sdwan_gw_vpc
  tags = {
    Name = join("-", ["IGW", var.netskope_tenant["tenant_id"]])
  }
}

locals {
  netskope_sdwan_gw_igw = element(coalescelist(data.aws_internet_gateway.netskope_sdwan_gw_igw.*.id, aws_internet_gateway.netskope_sdwan_gw_igw.*.id, [""]), 0)
}

data "aws_subnets" "all_subnets" {
  count = var.aws_create_vpc == false ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.netskope_sdwan_gw_vpc]
  }
}

locals {
  all_subnet_ids = tomap({ "subnets" : try(data.aws_subnets.all_subnets[0].ids, []) })
}

data "aws_subnet" "all_subnet_cidr" {
  count = var.aws_create_vpc == false ? length(local.all_subnet_ids["subnets"]) : 0
  id    = local.all_subnet_ids["subnets"][count.index]
}

locals {
  primary_public_cidr_index    = try(index([for s in data.aws_subnet.all_subnet_cidr : s.cidr_block], var.aws_network_config["primary_gw_subnets"]["ge1"]), -1)
  primary_private_cidr_index   = try(index([for s in data.aws_subnet.all_subnet_cidr : s.cidr_block], var.aws_network_config["primary_gw_subnets"]["ge2"]), -1)
  secondary_public_cidr_index  = try(index([for s in data.aws_subnet.all_subnet_cidr : s.cidr_block], var.aws_network_config["secondary_gw_subnets"]["ge1"]), -1)
  secondary_private_cidr_index = try(index([for s in data.aws_subnet.all_subnet_cidr : s.cidr_block], var.aws_network_config["secondary_gw_subnets"]["ge2"]), -1)

  primary_public_subnet_tag    = local.primary_public_cidr_index >= 0 ? try(data.aws_subnet.all_subnet_cidr[local.primary_public_cidr_index].tags["Environment"], "TAG_NOT_EXISTS") : "SUBNET_NOT_FOUND"
  primary_private_subnet_tag   = local.primary_private_cidr_index >= 0 ? try(data.aws_subnet.all_subnet_cidr[local.primary_private_cidr_index].tags["Environment"], "TAG_NOT_EXISTS") : "SUBNET_NOT_FOUND"
  secondary_public_subnet_tag  = local.secondary_public_cidr_index >= 0 ? try(data.aws_subnet.all_subnet_cidr[local.secondary_public_cidr_index].tags["Environment"], "TAG_NOT_EXISTS") : "SUBNET_NOT_FOUND"
  secondary_private_subnet_tag = local.secondary_private_cidr_index >= 0 ? try(data.aws_subnet.all_subnet_cidr[local.secondary_private_cidr_index].tags["Environment"], "TAG_NOT_EXISTS") : "SUBNET_NOT_FOUND"
}

data "aws_subnet" "netskope_sdwan_gw_primary_public_subnet" {
  count      = local.primary_public_cidr_index >= 0 ? 1 : 0
  vpc_id     = local.netskope_sdwan_gw_vpc
  cidr_block = var.aws_network_config["primary_gw_subnets"]["ge1"]
}

data "aws_subnet" "netskope_sdwan_gw_primary_private_subnet" {
  count      = local.primary_private_cidr_index >= 0 ? 1 : 0
  vpc_id     = local.netskope_sdwan_gw_vpc
  cidr_block = var.aws_network_config["primary_gw_subnets"]["ge2"]
}

data "aws_subnet" "netskope_sdwan_gw_secondary_public_subnet" {
  count      = (var.netskope_ha_enable && local.secondary_public_cidr_index >= 0) ? 1 : 0
  vpc_id     = local.netskope_sdwan_gw_vpc
  cidr_block = var.aws_network_config["secondary_gw_subnets"]["ge1"]
}

data "aws_subnet" "netskope_sdwan_gw_secondary_private_subnet" {
  count      = (var.netskope_ha_enable && local.secondary_private_cidr_index >= 0) ? 1 : 0
  vpc_id     = local.netskope_sdwan_gw_vpc
  cidr_block = var.aws_network_config["secondary_gw_subnets"]["ge2"]
}

resource "aws_subnet" "netskope_sdwan_gw_primary_public_subnet" {
  count             = (local.primary_public_cidr_index == -1 || try(regex(var.netskope_tenant["tenant_id"], local.primary_public_subnet_tag), "") != "" || local.primary_public_subnet_tag == "SUBNET_NOT_FOUND") ? 1 : 0
  vpc_id            = local.netskope_sdwan_gw_vpc
  cidr_block        = var.aws_network_config["primary_gw_subnets"]["ge1"]
  availability_zone = local.primary_zone

  tags = {
    Environment = join("-", ["Public-Subnet-Primary", var.netskope_tenant["tenant_id"]])
  }
}

resource "aws_subnet" "netskope_sdwan_gw_primary_private_subnet" {
  count             = (local.primary_private_cidr_index == -1 || try(regex(var.netskope_tenant["tenant_id"], local.primary_private_subnet_tag), "") != "" || local.primary_private_subnet_tag == "SUBNET_NOT_FOUND") ? 1 : 0
  vpc_id            = local.netskope_sdwan_gw_vpc
  cidr_block        = var.aws_network_config["primary_gw_subnets"]["ge2"]
  availability_zone = local.primary_zone

  tags = {
    Environment = join("-", ["Private-Subnet-Primary", var.netskope_tenant["tenant_id"]])
  }
}

resource "aws_subnet" "netskope_sdwan_gw_secondary_public_subnet" {
  count             = (var.netskope_ha_enable && (local.secondary_public_cidr_index == 0 || try(regex(var.netskope_tenant["tenant_id"], local.secondary_public_subnet_tag), "") != "" || local.secondary_public_subnet_tag == "SUBNET_NOT_FOUND")) ? 1 : 0
  vpc_id            = local.netskope_sdwan_gw_vpc
  cidr_block        = var.aws_network_config["secondary_gw_subnets"]["ge1"]
  availability_zone = local.secondary_zone

  tags = {
    Environment = join("-", ["Public-Subnet-Secondary", var.netskope_tenant["tenant_id"]])
  }
}

resource "aws_subnet" "netskope_sdwan_gw_secondary_private_subnet" {
  count             = (var.netskope_ha_enable && (local.secondary_private_cidr_index == 0 || try(regex(var.netskope_tenant["tenant_id"], local.secondary_private_subnet_tag), "") != "" || local.secondary_private_subnet_tag == "SUBNET_NOT_FOUND")) ? 1 : 0
  vpc_id            = local.netskope_sdwan_gw_vpc
  cidr_block        = var.aws_network_config["secondary_gw_subnets"]["ge2"]
  availability_zone = local.secondary_zone

  tags = {
    Environment = join("-", ["Private-Subnet-Secondary", var.netskope_tenant["tenant_id"]])
  }
}


locals {
  netskope_sdwan_primary_public_subnet    = element(coalescelist(data.aws_subnet.netskope_sdwan_gw_primary_public_subnet.*.id, aws_subnet.netskope_sdwan_gw_primary_public_subnet.*.id, [""]), 0)
  netskope_sdwan_primary_private_subnet   = element(coalescelist(data.aws_subnet.netskope_sdwan_gw_primary_private_subnet.*.id, aws_subnet.netskope_sdwan_gw_primary_private_subnet.*.id, [""]), 0)
  netskope_sdwan_secondary_public_subnet  = element(coalescelist(data.aws_subnet.netskope_sdwan_gw_secondary_public_subnet.*.id, aws_subnet.netskope_sdwan_gw_secondary_public_subnet.*.id, [""]), 0)
  netskope_sdwan_secondary_private_subnet = element(coalescelist(data.aws_subnet.netskope_sdwan_gw_secondary_private_subnet.*.id, aws_subnet.netskope_sdwan_gw_secondary_private_subnet.*.id, [""]), 0)
}

resource "aws_route_table" "netskope_sdwan_gw_public_rt" {
  count  = (var.aws_create_vpc || var.aws_network_config["route_table"]["public"] == "") ? 1 : 0
  vpc_id = local.netskope_sdwan_gw_vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.netskope_sdwan_gw_igw
  }

  tags = {
    Name = join("-", ["Public-RT", var.netskope_tenant["tenant_id"]])
  }
}

resource "aws_route_table" "netskope_sdwan_gw_private_rt" {
  count  = (var.aws_create_vpc || var.aws_network_config["route_table"]["private"] == "") ? 1 : 0
  vpc_id = local.netskope_sdwan_gw_vpc

  tags = {
    Name = join("-", ["Private-RT", var.netskope_tenant["tenant_id"]])
  }
}

locals {
  netskope_sdwan_public_rt  = element(coalescelist(try([aws_route_table.netskope_sdwan_gw_public_rt.0.id], []), [var.aws_network_config["route_table"]["public"]]), 0)
  netskope_sdwan_private_rt = element(coalescelist(try([aws_route_table.netskope_sdwan_gw_private_rt.0.id], []), [var.aws_network_config["route_table"]["private"]]), 0)
}

resource "aws_route_table_association" "netskope_sdwan_gw_primary_public_rt" {
  subnet_id      = local.netskope_sdwan_primary_public_subnet
  route_table_id = local.netskope_sdwan_public_rt
}

resource "aws_route_table_association" "netskope_sdwan_gw_primary_private_rt" {
  subnet_id      = local.netskope_sdwan_primary_private_subnet
  route_table_id = local.netskope_sdwan_private_rt
}

resource "aws_route_table_association" "netskope_sdwan_gw_secondary_public_rt" {
  count          = var.netskope_ha_enable ? 1 : 0
  subnet_id      = local.netskope_sdwan_secondary_public_subnet
  route_table_id = local.netskope_sdwan_public_rt
}

resource "aws_route_table_association" "netskope_sdwan_gw_secondary_private_rt" {
  count          = var.netskope_ha_enable ? 1 : 0
  subnet_id      = local.netskope_sdwan_secondary_private_subnet
  route_table_id = local.netskope_sdwan_private_rt
}

resource "aws_security_group" "netskope_sdwan_gw_public_sg" {
  name   = join("-", ["Public-SG", var.netskope_tenant["tenant_id"]])
  vpc_id = local.netskope_sdwan_gw_vpc

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "IPSec"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join("-", ["Public-SG", var.netskope_tenant["tenant_id"]])
  }
}

resource "aws_security_group" "netskope_sdwan_gw_private_sg" {
  name        = join("-", ["Private-SG", var.netskope_tenant["tenant_id"]])
  description = join("-", ["Private-SG", var.netskope_tenant["tenant_id"]])
  vpc_id      = local.netskope_sdwan_gw_vpc

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
    Name = join("-", ["Private-SG", var.netskope_tenant["tenant_id"]])
  }
}

data "aws_ec2_transit_gateway" "netskope_sdwan_tgw_datasource" {
  count = var.aws_create_transit_gw == false ? 1 : 0
  id    = var.aws_transit_gw["tgw_id"]
}

resource "aws_ec2_transit_gateway" "netskope_sdwan_tgw" {
  count                           = var.aws_create_transit_gw ? 1 : 0
  description                     = join("-", ["TGW", var.netskope_tenant["tenant_id"]])
  amazon_side_asn                 = var.aws_transit_gw["tgw_asn"]
  dns_support                     = "enable"
  multicast_support               = "disable"
  vpn_ecmp_support                = "enable"
  transit_gateway_cidr_blocks     = [var.aws_transit_gw["tgw_cidr"]]
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  auto_accept_shared_attachments  = "enable"

  tags = {
    Name = join("-", ["TGW", var.netskope_tenant["tenant_id"]])
  }

  depends_on = [time_sleep.api_delay]
}

locals {
  aws_transit_gateway = element(coalescelist(data.aws_ec2_transit_gateway.netskope_sdwan_tgw_datasource.*.id, aws_ec2_transit_gateway.netskope_sdwan_tgw.*.id, [""]), 0)
}

data "aws_ec2_transit_gateway" "netskope_sdwan_tgw" {
  id = local.aws_transit_gateway
}

locals {
  transit_gateway_cidr_block = element(coalescelist(data.aws_ec2_transit_gateway.netskope_sdwan_tgw.transit_gateway_cidr_blocks, [var.aws_transit_gw["tgw_cidr"]], [""]), 0)
  transit_gateway_asn        = element(coalescelist([data.aws_ec2_transit_gateway.netskope_sdwan_tgw.amazon_side_asn], [var.aws_transit_gw["tgw_asn"]], [""]), 0)
}

resource "aws_route" "netskope_sdwan_gw_tgw_route_entry" {
  route_table_id         = local.netskope_sdwan_private_rt
  destination_cidr_block = local.transit_gateway_cidr_block
  transit_gateway_id     = local.aws_transit_gateway
}

data "aws_ec2_transit_gateway_vpc_attachments" "all_vpc_attachments" {
  filter {
    name   = "transit-gateway-id"
    values = [local.aws_transit_gateway]
  }
}

locals {
  all_attachments = tomap({ "attachments" : try(data.aws_ec2_transit_gateway_vpc_attachments.all_vpc_attachments.ids, []) })
}

data "aws_ec2_transit_gateway_vpc_attachment" "netskope_sdwan_tgw_attach" {
  count = (var.aws_create_vpc == false && var.aws_transit_gw["vpc_attachment"] != "") ? 1 : 0
  filter {
    name   = "transit-gateway-id"
    values = [local.aws_transit_gateway]
  }
  filter {
    name   = "transit-gateway-attachment-id"
    values = [var.aws_transit_gw["vpc_attachment"]]
  }
  filter {
    name   = "vpc-id"
    values = [local.netskope_sdwan_gw_vpc]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "netskope_sdwan_tgw_attach" {
  count              = (var.aws_create_vpc || var.aws_transit_gw["vpc_attachment"] == "") ? 1 : 0
  subnet_ids         = concat([local.netskope_sdwan_primary_private_subnet], local.netskope_sdwan_secondary_private_subnet != "" ? [local.netskope_sdwan_secondary_private_subnet] : [])
  transit_gateway_id = local.aws_transit_gateway
  vpc_id             = local.netskope_sdwan_gw_vpc

  tags = {
    Name = join("-", ["NSG-Attach", var.netskope_tenant["tenant_id"]])
  }
}

locals {
  aws_transit_gateway_attachment = element(coalescelist(data.aws_ec2_transit_gateway_vpc_attachment.netskope_sdwan_tgw_attach.*.id, aws_ec2_transit_gateway_vpc_attachment.netskope_sdwan_tgw_attach.*.id, [""]), 0)
}


resource "aws_ec2_transit_gateway_connect" "netskope_sdwan_tgw_connect" {
  transport_attachment_id = local.aws_transit_gateway_attachment
  transit_gateway_id      = local.aws_transit_gateway

  tags = {
    Name = join("-", ["tgw_connect", var.netskope_tenant["tenant_id"]])
  }
  depends_on = [time_sleep.api_delay]
}

##########################################################