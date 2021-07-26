module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = " ~> 3.2.0"

  name = "xeniapp-vpc-${var.env_name}"
  cidr = "10.0.0.0/16"

  azs = [
    "${var.region}a",
    "${var.region}b",
  "${var.region}c"]
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  "10.0.3.0/24"]
  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24",
  "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
  private_inbound_acl_rules     = local.network_acls.default_inbound
  private_outbound_acl_rules    = local.network_acls.default_outbound
  public_inbound_acl_rules      = local.network_acls.public_inbound
  public_outbound_acl_rules     = local.network_acls.public_outbound


}
