data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = " ~> 3.2.0"

  name = "vpc-link-${var.env_name}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  enable_dns_hostnames = true
  enable_dns_support   = true


}
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = " ~> 3.2.0"
  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-endpoint-${var.env_name}" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets,
      tags                = { Name = "ec2messages-endpoint-${var.env_name}" }

    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "ssmmessages-endpoint-${var.env_name}" }
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "ec2-endpoint-${var.env_name}" }

    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "ec2messages-endpoint-${var.env_name}" }
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "kms-endpoint-${var.env_name}" }

    },
    codedeploy = {
      service             = "codedeploy"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "codedeploy-endpoint-${var.env_name}" }
    },
    codedeploy_commands_secure = {
      service             = "codedeploy-commands-secure"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "cd-commands-secure-endpoint-${var.env_name}" }
    },
  }
}

###################
# HTTP API Gateway
###################
/*
module "api_gateway" {
  source = "../../"

  name          = "http-vpc-links-${var.env_name}"
  description   = "HTTP API Gateway"
  protocol_type = "HTTPS"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  create_api_domain_name = false

  integrations = {
    "ANY /" = {
      lambda_arn             = module.lambda_function.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "GET /alb-internal-route" = {
      connection_type    = "VPC_LINK"
      vpc_link           = "my-vpc"
      integration_uri    = module.alb.http_tcp_listener_arns[0]
      integration_type   = "HTTP_PROXY"
      integration_method = "ANY"
    }


  }

  vpc_links = {
    my-vpc = {
      name               = "example"
      security_group_ids = [module.api_gateway_security_group.security_group_id]
      subnet_ids         = module.vpc.public_subnets
    }
  }

  tags = {
    Name = "private-api"
  }
}

module "api_gateway_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "api-gateway-sg-${var.env_name}"
  description = "API Gateway group for example usage"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  egress_rules = ["all-all"]
}

*/
############################
# Application Load Balancer
############################
resource "aws_alb" "backend-alb" {
  name            = "backend-alb-${var.env_name}"
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_security_group.security_group_id]

}
resource "aws_alb_listener" "backend-alb-http-listener" {
  load_balancer_arn = aws_alb.backend-alb.arn

  port     = "80"
  protocol = "HTTP"
  # Default action, and other parameters removed for BLOG
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-alb-tg.arn

  }
}


resource "aws_lb_target_group" "backend-alb-tg" {
  name     = "backend-alb-tg-${var.env_name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path = "/"
    port = 80
  }

}

resource "aws_lb_target_group_attachment" "backend-alb-tg-attachment" {
  count            = var.ec2_instance_count
  target_group_arn = aws_lb_target_group.backend-alb-tg.arn
  target_id        = aws_instance.ec2-private.*.id[count.index]
  port             = 80

}


module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "alb-sg-${var.env_name}"
  description = "ALB for example usage"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  egress_rules = ["all-all"]
}

##################
# Extra resources
##################
/*
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
*/


resource "aws_instance" "ec2-private" {
  count = var.ec2_instance_count
  ami   = "ami-0fa8a49db383f956d"

  instance_type        = "t2.micro"
  subnet_id            = tolist(module.vpc.private_subnets)[count.index % var.ec2_instance_count]
  iam_instance_profile = module.iam_assumable_role.this_iam_instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.backend_security_group.id
  ]

  tags = {
    environment      = var.env_name,
    instance-ordinal = count.index,
    Name             = "backend-server-${count.index}"
  }
}

resource "aws_security_group" "backend_security_group" {
  name        = "backend-sg-${var.env_name}"
  description = "This is for ${var.env_name} security group"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "backend-sg-${var.env_name}"
  }
}

resource "aws_security_group_rule" "allow_incoming_traffic_from_vpc" {

  type              = "ingress"
  protocol          = "-1"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  security_group_id = aws_security_group.backend_security_group.id
  description       = "allows all incoming traffic from vpc"
  from_port         = 0
  to_port           = 0
}

#########################################
# IAM policy
#########################################
module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role             = true
  create_instance_profile = true

  role_name         = "backend-server-${var.env_name}-iam-role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  ]

  tags = {
    Role = "backend-server-${var.env_name}-iam-role"
  }
}

