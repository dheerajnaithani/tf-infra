# create a CodeDeploy application
resource "aws_codedeploy_app" "main" {
  name = "Xeniapp-backend-${var.env_name}"
}

# create a deployment group
resource "aws_codedeploy_deployment_group" "main" {
  app_name              = aws_codedeploy_app.main.name
  deployment_group_name = "Xeniapp-backend-dep-group-${var.env_name}"
  service_role_arn      = module.iam_assumable_role.this_iam_role_arn

  deployment_config_name = "CodeDeployDefault.OneAtATime" # AWS defined deployment config

  dynamic "ec2_tag_set" {

    for_each = var.instance_name_tags
    content {
      ec2_tag_filter {
        key   = ec2_tag_set.value["key"]
        type  = "KEY_AND_VALUE"
        value = ec2_tag_set.value["value"]
      }
    }
  }
  # trigger a rollback on deployment failure event
  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
    ]
  }
}