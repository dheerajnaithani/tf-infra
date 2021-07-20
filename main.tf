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
  region = "us-east-1"
}

module "frontend" {
  source = "./frontend"
}