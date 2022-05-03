# Author: Luis Angel Vanegas Martinez (xlavm)
# Version: 1.0

# LOCALS CONSTANTS
/* 
I declared the local constants
*/
locals {
  PRINCIPAL_DOMAIN = "luisvanegas.co"
  HOSTED_ZONE_ID   = "Z037462919PCGJ91EZV5G"
}


# HOSTED ZONE
/* 
// Not create the Zone because the NS record is change  
resource "aws_route53_zone" "hosted_zone" {
  name = local.PRINCIPAL_DOMAIN
} 
*/

# WWW RECORD
/* 
This resource create the record for the subdomain www of the principal domain: luisvanegas.co
and this record redirect the traffic to principal domain luisvanegas.co
*/
resource "aws_route53_record" "www" {
  zone_id = local.HOSTED_ZONE_ID
  name    = "www.${local.PRINCIPAL_DOMAIN}"
  type    = "CNAME"
  ttl     = "300"
  records = [local.PRINCIPAL_DOMAIN]
}

# BUCKECT S3
/* 
This resource create the bucket where the resources of page is save or deployed and the bucket is will  named luisvanegas.co
*/
resource "aws_s3_bucket" "bucket" {
  bucket = local.PRINCIPAL_DOMAIN
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# CERTIFICATE MANAGER
/* 
This resource create the certificate for all subdomains and domain of luisvanegas.co, for this I use the expression: *.
this resources create the CNAMES record for validate the certificate
*/
resource "aws_acm_certificate" "cert" {
  domain_name               = local.PRINCIPAL_DOMAIN
  validation_method         = "DNS"
  subject_alternative_names = ["*.${local.PRINCIPAL_DOMAIN}"]
}
resource "aws_route53_record" "cert_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = local.HOSTED_ZONE_ID
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_record : record.fqdn]
}

# DISTRIBUTION
/* 
This resource create the distribution for the domains www.luisvanegas.co and luisvanegas.co and 
this distribution serve the content of s3 bucket called luisvanegas.co
*/
resource "aws_cloudfront_distribution" "s3_distro" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["www.${local.PRINCIPAL_DOMAIN}", "${local.PRINCIPAL_DOMAIN}"]
  origin {
    domain_name = aws_s3_bucket.bucket.website_endpoint
    origin_id   = local.PRINCIPAL_DOMAIN
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.PRINCIPAL_DOMAIN
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    ssl_support_method  = "sni-only"
    acm_certificate_arn = aws_acm_certificate.cert.arn
  }
}

# PRINCIPAL RECORD
/* 
This resource create the record for redirect the traffic to distribution from luisvanegas.co 
*/
resource "aws_route53_record" "principal_record" {
  zone_id = local.HOSTED_ZONE_ID
  name    = local.PRINCIPAL_DOMAIN
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distro.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distro.hosted_zone_id
    evaluate_target_health = true
  }
}
