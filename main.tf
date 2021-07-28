locals {
  region = "us-east-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.51.0"
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

  default_tags {
    tags = {
      environment = var.env_name
    }
  }
}

module "frontend" {
  source                 = "./frontend"
  env_name               = var.env_name
  top_level_domain_name  = "clubxeni.com"
  customer_domain_prefix = ["xeni", "biirdee"]
}


module "backend" {
  source                 = "./backend"
  env_name               = var.env_name
  region                 = local.region
  ec2_instance_count     = 3
  ami_id                 = "ami-0305323a98dceb84e"
  top_level_domain_name  = "clubxeni.com"
  customer_domain_prefix = ["xeni", "biirdee"]
  mongodb_private_key    = var.mongodb_private_key
  mongodb_public_key     = var.mongodb_public_key
}
