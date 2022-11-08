# Netskope SD-WAN GW AWS Module

This Infrastructure as Code (IaC) will help you deploy Netskope SD-WAN Gateway in your AWS environment in following scenarios:
- Deploy and activate Netskope SD-WAN Gateway in a new VPC and connect to a new Transit GW
- Deploy and activate Netskope SD-WAN Gateway in an existing VPC and connect to existing Transit GW
- Deploy Gateway with multiple WAN links / interfaces
- Optional client deployment for end to end solution validation

This module creates / configures the following objects in AWS and Netskop SD-WAN Portal:

## AWS Cloud
   - Virtual Network (Re-use existing or create new one)
   - Subnets (Re-use existing or create new one)
   - Transit Gateway (Re-use existing or create new one)
   - Network Security Groups (For both WAN network and Private network)
   - BGP Peering in Transit GW to Netskope SD-WAN GW
   - Route tables for WAN network and Private network
   - Host VPC / VM and required peerings (if chosen)

## Netskope SD-WAN Portal
   - Create new policy
   - Create new gateway (HA deployment is optional)
   - Configure required static routes and BGP peers

## Key Points

- The default username for the gateway is "infiot". Password authentication is disabled and you must use SSH keys to authenticate.
  This module has an option to set the password for the default username "infiot". This will be used only for console access.

## Known Limitations

1) Since "aws_ec2_transit_gateway_vpc_attachment" API has known limitations / open bugs to update the subnet list in an existing VPC Attachment, if the user provides existing VPC, Transit GW and VPC attachment to reuse, user has to manually update subnet list into the attachment, since this resource will not be managed by terraform. 

## Architecture Diagram

This IaC will create the AWS resources as shown below.

![](.//images/AWS.png)

*Fig 1. Netskope SD-WAN GW deployment in AWS*

## Deployment

To deploy this template in AWS:

- Identify the "Base URL" for your Netskope SD-WAN Tenant. This is a URL that you use to access your Netskope tenant, for example: `https://example.infiot.net`
  This will be set in "netskope_tenant" variable blob

- Get the ID of your Tenant from Netskope Team.

- Create a REST API Token as follows:

![API Token](images/api-token.png)

*Fig 2. Netskope SD-WAN Portal API Token*

- Clone the GitHub repository for this deployment.

- Configure provider block or set variables in the "provider.tf" file.

- Customize variables in the `example.tfvars` and `variables.tf` file as needed.
- Change to the repository directory and then initialize the providers and modules.

   ```sh
   $ cd <Code Directory>
   $ terraform init
    ```
- Submit the Terraform plan to preview the changes Terraform will make to match your configuration.

   ```sh
   $ terraform plan
   ```
- Apply the plan. The apply will make no changes to your resources, you can either respond to the confirmation prompt with a 'Yes' or cancel the apply if changes are needed.

   ```sh
   $ terraform apply
   ```

## Destruction

- To destroy this deployment, use the command:

   ```sh
   $ terraform destroy
   ```

## Support

Netskope-provided scripts in this and other GitHub projects do not fall under the regular Netskope technical support scope and are not supported by Netskope support services.