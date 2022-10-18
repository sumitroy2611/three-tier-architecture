provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "sumit-demo-terraform-states"
    region  = "eu-west-2"
    key     = "demo-site/terraform.tfstate"
  }
}
