
resource "aws_security_group" "endpoints" {
  description = "Security group for VPC endpoints"
  name        = "endpoints-sg-${var.env_name}"
  tags = {
    Name = "endpoints-sg-${var.env_name}"
  }
  vpc_id = module.vpc.vpc_id
}


resource "aws_security_group_rule" "endpoints-https" {
  cidr_blocks = [
  module.vpc.vpc_cidr_block]

  description       = "HTTPS access from private subnet"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.endpoints.id
  to_port           = 443
  type              = "ingress"
}
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = " ~> 3.2.0"
  vpc_id  = module.vpc.vpc_id
  security_group_ids = [
  aws_security_group.endpoints.id]

  endpoints = {
    s3 = {
      service = "s3"
      tags = {
        Name = "s3-endpoint-${var.env_name}"
      }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets,
      tags = {
        Name = "ssm-endpoint-${var.env_name}"
      }

    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "ssmmessages-endpoint-${var.env_name}"
      }
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "ec2-endpoint-${var.env_name}"
      }

    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "ec2messages-endpoint-${var.env_name}"
      }
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "kms-endpoint-${var.env_name}"
      }

    },
    codedeploy = {
      service             = "codedeploy"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "codedeploy-endpoint-${var.env_name}"
      }
    },
    codedeploy_commands_secure = {
      service             = "codedeploy-commands-secure"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "cd-commands-secure-endpoint-${var.env_name}"
      }
    },
  }
}
