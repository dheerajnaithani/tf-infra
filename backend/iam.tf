#########################################
# IAM policy
#########################################
data "aws_iam_policy_document" "secret_manager_iam_policy_document" {
  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    "secretsmanager:ListSecrets"]
    resources = [
    "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:/dev/*"]
    effect = "Allow"
  }
}

module "secret_manager_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "ec2-secret-manager-policy-${var.env_name}"
  path        = format("/%s/", var.env_name)
  description = "secret manager policy for ${var.env_name}"

  policy = data.aws_iam_policy_document.secret_manager_iam_policy_document.json

}

data "aws_iam_policy_document" "parameter_store_iam_policy_document" {
  statement {
    actions = [
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
    "ssm:DescribeParameters"]
    resources = [
    "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/dev/*"]
    effect = "Allow"
  }
}

module "parameter_store_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "ec2-parameter-store-policy-${var.env_name}"
  path        = format("/%s/", var.env_name)
  description = "parameter store policy for ${var.env_name}"

  policy = data.aws_iam_policy_document.parameter_store_iam_policy_document.json
}

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
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy",
    module.secret_manager_iam_policy.arn,
    module.parameter_store_iam_policy.arn

  ]

  tags = {
    Role = "backend-server-${var.env_name}-iam-role"
  }
}
