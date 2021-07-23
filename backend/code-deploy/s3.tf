# create an S3 bucket
resource "aws_s3_bucket" "code-deploy-bucket" {
  bucket = "xeniapp-backend-codedeploy-${var.env_name}"
  acl    = "private"
}