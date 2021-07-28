locals {
  instance_name_tags = tomap({
    "group" = "backend-server-${var.env_name}"
  })
  tld_domain_name = trimsuffix(var.top_level_domain_name, ".")
  domain_suffix   = "${var.env_name}.api.${local.tld_domain_name}"

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
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token",
    "x-amz-user-agent"]
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
  name    = "backend-alb-${var.env_name}"
  subnets = module.vpc.public_subnets
  security_groups = [
  module.alb_security_group.security_group_id]

}
resource "aws_alb_listener" "backend-alb-http-listener" {
  load_balancer_arn = aws_alb.backend-alb.arn

  port     = "80"
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "backend-alb-https-listener" {
  load_balancer_arn = aws_alb.backend-alb.arn
  certificate_arn   = module.acm.acm_certificate_arn
  port              = "443"
  protocol          = "HTTPS"
  # Default action, and other parameters removed for BLOG
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-alb-tg.arn

  }
}


resource "aws_lb_target_group" "backend-alb-tg" {
  name_prefix = "alb-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path = "/"
    port = 3000
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "backend-alb-tg-${var.env_name}"
  }

}

resource "aws_lb_target_group_attachment" "backend-alb-tg-attachment" {
  count            = var.ec2_instance_count
  target_group_arn = aws_lb_target_group.backend-alb-tg.arn
  target_id        = aws_instance.ec2-private.*.id[count.index]
  port             = 3000

}


module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "alb-sg-${var.env_name}"
  description = "ALB for ${var.env_name} backend servers"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [
  "0.0.0.0/0"]
  ingress_rules = [
    "http-80-tcp",
    "https-443-tcp"
  ]

  egress_rules = [
  "all-all"]
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
  ami   = var.ami_id

  instance_type        = "t2.micro"
  subnet_id            = tolist(module.vpc.private_subnets)[count.index % var.ec2_instance_count]
  iam_instance_profile = module.iam_assumable_role.this_iam_instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.backend_security_group.id
  ]

  tags = merge(
    local.instance_name_tags,
    tomap({
      instance-ordinal = count.index,
      Name             = "backend-server-${count.index}"
    })
  )
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

  type     = "ingress"
  protocol = "-1"
  cidr_blocks = [
  module.vpc.vpc_cidr_block]
  security_group_id = aws_security_group.backend_security_group.id
  description       = "allows all incoming traffic from vpc"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "allow_outgoing_traffic_to_vpc" {

  type     = "egress"
  protocol = "-1"
  cidr_blocks = [
  "0.0.0.0/0"]
  security_group_id = aws_security_group.backend_security_group.id
  description       = "allows all outgoing traffic to vpc"
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
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"

  ]

  tags = {
    Role = "backend-server-${var.env_name}-iam-role"
  }
}

module "code-deploy" {
  source             = "./code-deploy"
  env_name           = var.env_name
  instance_name_tags = local.instance_name_tags

}

data "aws_route53_zone" "top_level_dns_zone" {
  name         = local.tld_domain_name
  private_zone = false
}


module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = "*.${local.domain_suffix}"
  //${var.env_name}.api.${local.tld_domain_name}
  zone_id = coalescelist(data.aws_route53_zone.top_level_dns_zone.*.zone_id)[0]

  subject_alternative_names = [
    local.domain_suffix
    //"api.${local.tld_domain_name}"
  ]

  wait_for_validation = true

  tags = {
    Name = "asterisk.${local.domain_suffix}"
  }
}
resource "aws_route53_record" "a-route-53-api" {
  zone_id = data.aws_route53_zone.top_level_dns_zone.zone_id
  name    = local.domain_suffix
  type    = "A"
  alias {
    name                   = aws_alb.backend-alb.dns_name
    zone_id                = aws_alb.backend-alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "a-route-53-customers" {
  for_each = var.customer_domain_prefix
  zone_id  = data.aws_route53_zone.top_level_dns_zone.zone_id

  name = "${each.value}.${local.domain_suffix}"
  // e.g. xeni.dev.api.xeniapp.com
  type = "A"
  alias {
    name                   = aws_alb.backend-alb.dns_name
    zone_id                = aws_alb.backend-alb.zone_id
    evaluate_target_health = false
  }
}


module "mongodb" {
  source                 = "./mongodb"
  region                 = "us-east-1"
  atlas_org_id           = "60ae824fac63ca5d66f040ab"
  subnet_ids             = module.vpc.private_subnets
  security_group_ids     = [aws_security_group.endpoints.id]
  vpc_id                 = module.vpc.vpc_id
  mongodb_private_key    = var.mongodb_private_key
  mongodb_public_key     = var.mongodb_public_key
  env_name               = var.env_name
  atlas_vpc_cidr         = "192.168.248.0/21"
  vpc_cidr               = module.vpc.vpc_cidr_block
  route_table_ids        = toset(module.vpc.private_route_table_ids)
  admin_users            = ["admin@xeniapp.com", "dheeraj@xeniapp.com"]
  read_write_admin_users = ["admin@xeniapp.com", "dheeraj@xeniapp.com"]

}


