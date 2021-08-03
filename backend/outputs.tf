
output "atlasclusterstring" {
  value = module.mongodb.atlasclusterstring
}



output "secrets_policy" {
  value = data.aws_iam_policy_document.secret_manager_iam_policy_document.json
}
