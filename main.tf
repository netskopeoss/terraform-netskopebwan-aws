#------------------------------------------------------------------------------
#  Copyright (c) 2022 Infiot Inc.
#  All rights reserved.
#------------------------------------------------------------------------------
module "aws_vpc" {
  source                  = "./modules/aws_vpc"
  aws_network_config      = var.aws_network_config
  clients                 = var.clients
  aws_transit_gw          = var.aws_transit_gw
  netskope_tenant         = var.netskope_tenant
  netskope_gateway_config = var.netskope_gateway_config
}

module "nsg_config" {
  source                  = "./modules/nsg_config"
  clients                 = var.clients
  netskope_tenant         = var.netskope_tenant
  aws_network_config      = merge(var.aws_network_config, module.aws_vpc.aws_vpc_output.zones)
  netskope_gateway_config = merge(var.netskope_gateway_config, module.aws_vpc.aws_vpc_output.netskope_gateway_config)
  aws_transit_gw          = merge(var.aws_transit_gw, module.aws_vpc.aws_vpc_output.aws_transit_gw)
}

module "aws_ec2" {
  source                  = "./modules/aws_ec2"
  aws_instance            = var.aws_instance
  netskope_tenant         = var.netskope_tenant
  aws_transit_gw          = merge(var.aws_transit_gw, module.aws_vpc.aws_vpc_output.aws_transit_gw)
  aws_network_config      = merge(var.aws_network_config, module.aws_vpc.aws_vpc_output.zones)
  netskope_gateway_config = merge(var.netskope_gateway_config, module.nsg_config.nsg_config_output.netskope_gateway_config)
}

module "clients" {
  source                  = "./modules/clients"
  count                   = var.clients.create_clients ? 1 : 0
  clients                 = var.clients
  aws_instance            = var.aws_instance
  netskope_tenant         = var.netskope_tenant
  aws_network_config      = merge(var.aws_network_config, module.aws_vpc.aws_vpc_output.zones)
  netskope_gateway_config = merge(var.netskope_gateway_config, module.nsg_config.nsg_config_output.netskope_gateway_config)
  aws_transit_gw          = merge(var.aws_transit_gw, module.aws_vpc.aws_vpc_output.aws_transit_gw)
}