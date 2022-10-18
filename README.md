# three-tier-architecture

## Overview
- This solution presents a 3-tier architecture in AWS, which is consisted of client, application and data layers. 
- The front end requests comes through an external ALB(in public subnet), then autoscaling set of httpd(apache) web servers serve it on the client layer which are in private subnet. They Spread across 2 availability zone for high availability)
- The application layer consists of EC2 servers present in private subnet, which are also spread across multi AZ for high availability.
- We then have the database layer consisting of RDS-mysql instance in private subnet. So, that it is not accessible by the internet

## How to set-up and run
- Install Terraform cli in your local machine 
    - `https://learn.hashicorp.com/tutorials/terraform/install-cli`
- Configure aws credentials in your local
    - `https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html`
- Ensure the S3 bucket used to save the terraform state file as given in providers.tf file is created/pre-exits in your AWS account
    - `https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html`
- Clone this repository
    - `git clone https://github.com/sumitroy2611/three-tier-architecture`
- Open the repository on your instance
    - `cd three-tier-architecture`
- Run following terraform commands in sequence
    - `terraform init` to initialise your terraform modules and establish connection with remote backend
    - `terraform plan -var-file ./terraform.tfvars` to verify the changes before applying
    - `terraform plan -var-file ./terraform.tfvars --auto-approve` to apply changes

 ## How to destroy the infra components
- Run the following command to destroy all the components created in above stages
    - `terraform destroy --auto-approve`
