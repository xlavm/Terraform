provider "aws" {
  access_key = "<YOUR_AWS_ACCESS_KEY_ID>"
  secret_key = "<YOUR_AWS_SECRET_ACCESS_KEY>"
  region = "us-east-1"
}

# Bucket S3
resource "aws_s3_bucket" "bucket-luis" {
  bucket = "bucket-luisvanegas"
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# Route 53
resource "aws_route53_zone" "luisvanegas" {
  name = "luisvanegas.co"
}
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.luisvanegas.zone_id
  name    = "www.luisvanegas.co"
  type    = "CNAME"
  ttl     = "300"
  records = ["luisvanegas.co"]
}

# Certificate Manager
resource "aws_acm_certificate" "cert" {
  domain_name       = "luisvanegas.co"
  validation_method = "DNS"
  subject_alternative_names = [
      "www.luisvanegas.co"
      ]
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = aws_route53_zone.luisvanegas.zone_id
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}
resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
}

# Cloud Front
locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket-luis.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"
  aliases = ["www.luisvanegas.co"]
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    viewer_protocol_policy = "redirect-to-https"
  }
 restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
    acm_certificate_arn = aws_acm_certificate.cert.arn
 }
}

# Route 53
resource "aws_route53_record" "luisvanegas" {
  zone_id = aws_route53_zone.luisvanegas.zone_id
  name    = "luisvanegas.co"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

