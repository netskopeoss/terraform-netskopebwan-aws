# Netskope SD-WAN GW AWS Module
A Terraform Module that deploys Netskope SD-WAN GW and establish Dynamic Routing with existing infrastructure

## Usage

1) Please refer to the terraform.tfvars file for sample configurations and prepare your environment variables.
2) ```
    terraform init
    terraform apply 
   ```
(review the plan and approve the deployment by providing "yes")

## Known Limitations

1) Since "aws_ec2_transit_gateway_vpc_attachment" API has known limitations / open bugs to update the subnet list in an existing VPC Attachment, if the user provides existing VPC attachment to reuse, user has to manually update subnet list into the attachment, since this resource will not be managed by terraform. 

2) At present, this module will support GW deployment with only 2 interfaces.