# create a CodeDeploy application
resource "aws_codedeploy_app" "main" {
  name = "Xeniapp-backend-${var.env_name}"
}

# create a deployment group
resource "aws_codedeploy_deployment_group" "main" {
  app_name              = aws_codedeploy_app.main.name
  deployment_group_name = "eniapp-backend-dep-group-${var.env_name}"
  service_role_arn      = module.iam_assumable_role.this_iam_role_arn

  deployment_config_name = "CodeDeployDefault.OneAtATime" # AWS defined deployment config

  ec2_tag_filter = {
    key   = var.instance_group_tag_key
    type  = "KEY_AND_VALUE"
    value = var.instance_group_tag_value
  }

  # trigger a rollback on deployment failure event
  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
    ]
  }
}