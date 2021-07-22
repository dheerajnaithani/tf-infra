locals {
  region = "us-east-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
  required_version = "~> 1.0.2"

  backend "remote" {
    organization = "zest-tech"

    workspaces {
      prefix = "base-infra-"
    }
  }
}

provider "aws" {
  region = local.region
}
/*
module "frontend" {
  source   = "./frontend"
  env_name = var.env_name
}
*/

module "backend" {
  source             = "./backend"
  env_name           = var.env_name
  region             = local.region
  ec2_instance_count = 3
  ami_id             = "ami-039ef0886c8164e93"
}