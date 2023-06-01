#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------

data "aws_vpc" "netskope_sdwan_gw_vpc" {
  count = var.aws_network_config.vpc_id != "" ? 1 : 0
  id    = var.aws_network_config.vpc_id
}

resource "aws_vpc" "netskope_sdwan_gw_vpc" {
  count      = var.aws_network_config.create_vpc ? 1 : 0
  cidr_block = var.aws_network_config.vpc_cidr
  tags = {
    Name = join("-", ["VPC", var.netskope_tenant.tenant_id])
  }
}

locals {
  netskope_sdwan_gw_vpc = element(coalescelist(data.aws_vpc.netskope_sdwan_gw_vpc.*.id, aws_vpc.netskope_sdwan_gw_vpc.*.id, [""]), 0)
}

data "aws_internet_gateway" "netskope_sdwan_gw_igw" {
  count = var.aws_network_config.vpc_id != "" ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [local.netskope_sdwan_gw_vpc]
  }
}

resource "aws_internet_gateway" "netskope_sdwan_gw_igw" {
  count  = var.aws_network_config.create_vpc ? 1 : 0
  vpc_id = local.netskope_sdwan_gw_vpc
  tags = {
    Name = join("-", ["IGW", var.netskope_tenant.tenant_id])
  }
}

locals {
  netskope_sdwan_gw_igw = element(coalescelist(data.aws_internet_gateway.netskope_sdwan_gw_igw.*.id, aws_internet_gateway.netskope_sdwan_gw_igw.*.id, [""]), 0)
}

data "aws_subnets" "all_subnets" {
  count = var.aws_network_config.vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.netskope_sdwan_gw_vpc]
  }
}

locals {
  all_subnet_ids = tomap({ "subnets" : try(data.aws_subnets.all_subnets[0].ids, []) })
}

data "aws_subnet" "all_subnet_cidr" {
  count = var.aws_network_config.vpc_id != "" ? length(local.all_subnet_ids["subnets"]) : 0
  id    = local.all_subnet_ids["subnets"][count.index]
}

locals {
  primary_zone_cidr_index = {
    for intf, subnet in local.primary_zone_enabled_interfaces :
    intf => try(index([for s in data.aws_subnet.all_subnet_cidr : s.cidr_block], local.primary_zone_enabled_interfaces[intf].subnet_cidr), -1)
  }
  primary_zone_subnet_tag = {
    for intf, subnet in local.primary_zone_enabled_interfaces :
    intf => local.primary_zone_cidr_index[intf] >= 0 ? try(data.aws_subnet.all_subnet_cidr[local.primary_zone_cidr_index[intf]].tags["Environment"], "TAG_NOT_EXISTS") : "SUBNET_NOT_FOUND"
  }
  secondary_zone_cidr_index = {
    for intf, subnet in local.secondary_zone_enabled_interfaces :
    intf => try(index([for s in data.aws_subnet.all_subnet_cidr : s.cidr_block], local.secondary_zone_enabled_interfaces[intf].subnet_cidr), -1)
  }
  secondary_zone_subnet_tag = {
    for intf, subnet in local.secondary_zone_enabled_interfaces :
    intf => local.secondary_zone_cidr_index[intf] >= 0 ? try(data.aws_subnet.all_subnet_cidr[local.secondary_zone_cidr_index[intf]].tags["Environment"], "TAG_NOT_EXISTS") : "SUBNET_NOT_FOUND"
  }
}

data "aws_subnet" "netskope_sdwan_primary_zone_subnets" {
  for_each = {
    for intf, subnet in local.primary_zone_enabled_interfaces : intf => subnet if local.primary_zone_cidr_index[intf] >= 0
  }
  vpc_id     = local.netskope_sdwan_gw_vpc
  cidr_block = each.value.subnet_cidr
}

data "aws_subnet" "netskope_sdwan_secondary_zone_subnets" {
  for_each = {
    for intf, subnet in local.secondary_zone_enabled_interfaces : intf => subnet if(local.secondary_zone_cidr_index[intf] >= 0)
  }
  vpc_id     = local.netskope_sdwan_gw_vpc
  cidr_block = each.value.subnet_cidr
}

resource "aws_subnet" "netskope_sdwan_primary_zone_subnets" {
  for_each = {
    for intf, subnet in local.primary_zone_enabled_interfaces : intf => subnet
    if(local.primary_zone_cidr_index[intf] == -1 || try(regex(var.netskope_tenant.tenant_id, local.primary_zone_subnet_tag[intf]), "") != "" || local.primary_zone_subnet_tag[intf] == "SUBNET_NOT_FOUND")
  }
  vpc_id            = local.netskope_sdwan_gw_vpc
  cidr_block        = each.value
  availability_zone = local.primary_zone

  tags = {
    Environment = join("-", [each.key, local.primary_zone, var.netskope_tenant.tenant_id])
  }
}

resource "aws_subnet" "netskope_sdwan_secondary_zone_subnets" {
  for_each = {
    for intf, subnet in local.secondary_zone_enabled_interfaces : intf => subnet
    if(local.secondary_zone_cidr_index[intf] == -1 || try(regex(var.netskope_tenant.tenant_id, local.secondary_zone_subnet_tag[intf]), "") != "" || local.secondary_zone_subnet_tag[intf] == "SUBNET_NOT_FOUND")
  }
  vpc_id            = local.netskope_sdwan_gw_vpc
  cidr_block        = each.value
  availability_zone = local.secondary_zone

  tags = {
    Environment = join("-", [each.key, local.secondary_zone, var.netskope_tenant.tenant_id])
  }
}

locals {
  primary_zone_subnets = {
    for intf, subnet in local.primary_zone_enabled_interfaces :
    intf => element(coalescelist(try([data.aws_subnet.netskope_sdwan_primary_zone_subnets[intf].id], []), try([aws_subnet.netskope_sdwan_primary_zone_subnets[intf].id], []), [""]), 0)
    if subnet != null
  }
  secondary_zone_subnets = {
    for intf, subnet in local.secondary_zone_enabled_interfaces :
    intf => element(coalescelist(try([data.aws_subnet.netskope_sdwan_secondary_zone_subnets[intf].id], []), try([aws_subnet.netskope_sdwan_secondary_zone_subnets[intf].id], [""]), [""]), 0)
    if subnet != null
  }
}

resource "aws_route_table" "netskope_sdwan_gw_public_rt" {
  count  = (var.aws_network_config.create_vpc || var.aws_network_config.route_table.public == "") ? 1 : 0
  vpc_id = local.netskope_sdwan_gw_vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.netskope_sdwan_gw_igw
  }

  tags = {
    Name = join("-", ["Public-RT", var.netskope_tenant.tenant_id])
  }
}

resource "aws_route_table" "netskope_sdwan_gw_private_rt" {
  count  = (var.aws_network_config.create_vpc || var.aws_network_config.route_table.private == "") ? 1 : 0
  vpc_id = local.netskope_sdwan_gw_vpc

  tags = {
    Name = join("-", ["Private-RT", var.netskope_tenant.tenant_id])
  }
}

locals {
  netskope_sdwan_public_rt  = var.aws_network_config.route_table.public != "" ? var.aws_network_config.route_table.public : try(element(aws_route_table.netskope_sdwan_gw_public_rt.*.id, 0), "")
  netskope_sdwan_private_rt = var.aws_network_config.route_table.private != "" ? var.aws_network_config.route_table.private : try(element(aws_route_table.netskope_sdwan_gw_private_rt.*.id, 0), "")
}

resource "aws_route_table_association" "netskope_sdwan_primary_zone_public_rt" {
  for_each       = toset(keys(local.public_overlay_interfaces))
  subnet_id      = local.primary_zone_subnets[each.key]
  route_table_id = local.netskope_sdwan_public_rt
}

resource "aws_route_table_association" "netskope_sdwan_primary_zone_private_rt" {
  for_each       = toset(local.lan_interfaces)
  subnet_id      = local.primary_zone_subnets[each.key]
  route_table_id = local.netskope_sdwan_private_rt
}

resource "aws_route_table_association" "netskope_sdwan_secondary_zone_public_rt" {
  for_each       = toset(keys(local.public_overlay_interfaces))
  subnet_id      = local.secondary_zone_subnets[each.key]
  route_table_id = local.netskope_sdwan_public_rt
}

resource "aws_route_table_association" "netskope_sdwan_secondary_zone_private_rt" {
  for_each       = toset(local.lan_interfaces)
  subnet_id      = local.secondary_zone_subnets[each.key]
  route_table_id = local.netskope_sdwan_private_rt
}

resource "aws_security_group" "netskope_sdwan_gw_public_sg" {
  name   = join("-", ["Public-SG", var.netskope_tenant.tenant_id])
  vpc_id = local.netskope_sdwan_gw_vpc

dynamic "ingress" {
    for_each = var.clients.create_clients ? toset(var.clients.ports) : toset([])
    content {
      description = "SSH"
      from_port   = sum([2000, tonumber(ingress.key)])
      to_port     = sum([2000, tonumber(ingress.key)])
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
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
    Name = join("-", ["Public-SG", var.netskope_tenant.tenant_id])
  }
}

resource "aws_security_group" "netskope_sdwan_gw_private_sg" {
  name        = join("-", ["Private-SG", var.netskope_tenant.tenant_id])
  description = join("-", ["Private-SG", var.netskope_tenant.tenant_id])
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
    Name = join("-", ["Private-SG", var.netskope_tenant.tenant_id])
  }
}

data "aws_ec2_transit_gateway" "netskope_sdwan_tgw_datasource" {
  count = var.aws_transit_gw.create_transit_gw == false && var.aws_transit_gw.tgw_id != null ? 1 : 0
  id    = var.aws_transit_gw.tgw_id
}

resource "aws_ec2_transit_gateway" "netskope_sdwan_tgw" {
  count                           = var.aws_transit_gw.create_transit_gw ? 1 : 0
  description                     = join("-", ["TGW", var.netskope_tenant.tenant_id])
  amazon_side_asn                 = var.aws_transit_gw.tgw_asn
  dns_support                     = "enable"
  multicast_support               = "disable"
  vpn_ecmp_support                = "enable"
  transit_gateway_cidr_blocks     = [var.aws_transit_gw.tgw_cidr]
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  auto_accept_shared_attachments  = "enable"

  tags = {
    Name = join("-", ["TGW", var.netskope_tenant.tenant_id])
  }

  depends_on = [time_sleep.api_delay]
}

locals {
  aws_transit_gateway = element(coalescelist(data.aws_ec2_transit_gateway.netskope_sdwan_tgw_datasource.*, aws_ec2_transit_gateway.netskope_sdwan_tgw.*, [null]), 0)
}

data "aws_ec2_transit_gateway" "netskope_sdwan_tgw" {
  id = local.aws_transit_gateway.id
}

data "aws_ec2_transit_gateway_vpc_attachments" "all_vpc_attachments" {
  filter {
    name   = "transit-gateway-id"
    values = [local.aws_transit_gateway.id]
  }
}

locals {
  all_attachments = tomap({ "attachments" : try(data.aws_ec2_transit_gateway_vpc_attachments.all_vpc_attachments.ids, []) })
}

data "aws_ec2_transit_gateway_vpc_attachment" "netskope_sdwan_tgw_attach" {
  count = (var.aws_network_config.create_vpc == false && var.aws_transit_gw.vpc_attachment != "") ? 1 : 0
  filter {
    name   = "transit-gateway-id"
    values = [local.aws_transit_gateway.id]
  }
  filter {
    name   = "transit-gateway-attachment-id"
    values = [var.aws_transit_gw.vpc_attachment]
  }
  filter {
    name   = "vpc-id"
    values = [local.netskope_sdwan_gw_vpc]
  }
}

locals {
  netskope_sdwan_primary_private_subnet   = length(local.lan_interfaces) > 0 ? local.primary_zone_subnets[element(tolist(local.lan_interfaces), 0)] : ""
  netskope_sdwan_secondary_private_subnet = length(local.lan_interfaces) > 0 ? local.secondary_zone_subnets[element(tolist(local.lan_interfaces), 0)] : ""
  private_subnets_to_attach               = concat([local.netskope_sdwan_primary_private_subnet], local.netskope_sdwan_secondary_private_subnet != "" ? [local.netskope_sdwan_secondary_private_subnet] : [])
}

resource "aws_ec2_transit_gateway_vpc_attachment" "netskope_sdwan_tgw_attach" {
  count              = (var.aws_network_config.create_vpc || var.aws_transit_gw.vpc_attachment == "") && length(local.lan_interfaces) > 0 ? 1 : 0
  subnet_ids         = local.private_subnets_to_attach
  transit_gateway_id = local.aws_transit_gateway.id
  vpc_id             = local.netskope_sdwan_gw_vpc

  tags = {
    Name = join("-", ["NSG-Attach", var.netskope_tenant.tenant_id])
  }
}

locals {
  aws_transit_gateway_attachment = element(coalescelist(data.aws_ec2_transit_gateway_vpc_attachment.netskope_sdwan_tgw_attach.*.id, aws_ec2_transit_gateway_vpc_attachment.netskope_sdwan_tgw_attach.*.id, [""]), 0)
}

resource "aws_route" "netskope_sdwan_gw_tgw_route_entry" {
  count                  = length(local.lan_interfaces) > 0 ? 1 : 0
  route_table_id         = local.netskope_sdwan_private_rt
  destination_cidr_block = tolist(local.aws_transit_gateway.transit_gateway_cidr_blocks)[0]
  transit_gateway_id     = local.aws_transit_gateway.id
}

resource "aws_ec2_transit_gateway_connect" "netskope_sdwan_tgw_connect" {
  count                   = length(local.lan_interfaces) > 0 ? ceil(var.netskope_gateway_config.gateway_count / 4) : 0
  transport_attachment_id = local.aws_transit_gateway_attachment
  transit_gateway_id      = local.aws_transit_gateway.id

  tags = {
    Name = join("-", ["tgw_connect", var.netskope_tenant.tenant_id])
  }
  depends_on = [time_sleep.api_delay]
}

##########################################################