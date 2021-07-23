module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  trusted_role_services = [
    "codedeploy.amazonaws.com"
  ]

  create_role             = true
  create_instance_profile = true

  role_name         = "code-deploy-${var.env_name}-iam-role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"

  ]

  tags = {
    Role = "code-deploy-${var.env_name}-iam-role"
  }
}