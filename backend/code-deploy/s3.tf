# create an S3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "Xeniapp-backend-codedeploy-${var.env_name}"
  acl    = "private"
}