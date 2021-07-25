locals {

  tld_domain_name = trimsuffix(var.top_level_domain_name, ".")
  domain_suffix   = "${var.env_name}.booking.${local.tld_domain_name}"
  customer_dns    = formatlist("%s.${local.domain_suffix}", var.customer_domain_prefix)
  all_dns         = concat(local.customer_dns, [local.domain_suffix])

}
module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = local.all_dns

  comment             = "frontend-deployment"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "My awesome CloudFront can access"
  }

  logging_config = {
    bucket = module.log_bucket.s3_bucket_bucket_domain_name
    prefix = "cloudfront"
  }

  origin = {
    appsync = {
      domain_name = "appsync.${local.domain_suffix}"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols = [
        "TLSv1"]
      }

      custom_header = [
        {
          name  = "X-Forwarded-Scheme"
          value = "https"
        },
        {
          name  = "X-Frame-Options"
          value = "SAMEORIGIN"
        }
      ]
    }

    s3_one = {
      domain_name = module.s3_one.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
        # key in `origin_access_identities`
        # cloudfront_access_identity_path = "origin-access-identity/cloudfront/E5IGQAA1QO48Z" # external OAI resource
      }
    }
  }

  origin_group = {
    group_one = {
      failover_status_codes = [
        403,
        404,
        500,
      502]
      primary_member_origin_id   = "appsync"
      secondary_member_origin_id = "s3_one"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "appsync"
    viewer_protocol_policy = "allow-all"

    allowed_methods = [
      "GET",
      "HEAD",
    "OPTIONS"]
    cached_methods = [
      "GET",
    "HEAD"]
    compress     = true
    query_string = true

  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/*"
      target_origin_id       = "s3_one"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = [
        "GET",
        "HEAD",
      "OPTIONS"]
      cached_methods = [
        "GET",
      "HEAD"]
      compress     = true
      query_string = true


    }
  ]

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  geo_restriction = {
    restriction_type = "whitelist"
    locations = [
      "NO",
      "UA",
      "US",
    "GB"]
  }

}

######
# ACM
######

data "aws_route53_zone" "this" {
  name = local.tld_domain_name
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = "*.${local.domain_suffix}"
  zone_id     = data.aws_route53_zone.this.id

}

#############
# S3 buckets
#############

data "aws_canonical_user_id" "current" {}

module "s3_one" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 2.0"

  bucket        = "${local.domain_suffix}-ui-deploy"
  force_destroy = true
}

module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 2.0"

  bucket = "logs-${local.domain_suffix}-${var.env_name}"
  acl    = null
  grant = [
    {
      type = "CanonicalUser"
      permissions = [
      "FULL_CONTROL"]
      id = data.aws_canonical_user_id.current.id
    },
    {
      type = "CanonicalUser"
      permissions = [
      "FULL_CONTROL"]
      id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      # Ref. https://github.com/terraform-providers/terraform-provider-aws/issues/12512
      # Ref. https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
  }]
  force_destroy = true
}


##########
# Route53
##########



###########################
# Origin Access Identities
###########################
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
    "s3:GetObject"]
    resources = [
    "${module.s3_one.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_one.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}
