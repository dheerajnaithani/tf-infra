
resource "aws_security_group" "endpoints" {
  description = "Security group for VPC endpoints"
  name        = "endpoints-sg"
  tags = {
    Name = "endpoints-sg"
  }
  vpc_id = var.vpc_id
}


resource "aws_security_group_rule" "endpoints-https" {
  cidr_blocks = [
    var.private_subnets_cidr_blocks
  ]
  description       = "HTTPS access from private subnet"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.endpoints.id
  to_port           = 443
  type              = "ingress"
}


resource "aws_vpc_endpoint" "ec2messages" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoints.id]
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  subnet_ids          = var.private_subnets
  tags = {
    Name = "ec2messages-endpoint"
  }
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
}

resource "aws_vpc_endpoint" "ssmmessages" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoints.id]
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  subnet_ids          = var.private_subnets
  tags = {
    Name = "ssmmessages-endpoint"
  }
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
}

resource "aws_vpc_endpoint" "ssm" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoints.id]
  service_name        = "com.amazonaws.us-east-1.ssm"
  subnet_ids          = var.private_subnets
  tags = {
    Name = "ssm-endpoint"
  }
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
}