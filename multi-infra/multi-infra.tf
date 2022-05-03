# Author: Luis Angel Vanegas Martinez (xlavm)
# Version: 1.0

/* 
this implementation is for multi infra and domains 
with multi buckets and multi CDN of cloudfront 
*/

# DOMAINS LIST VARIABLE
/* 
I declared the list of domains in variable
*/
variable "domain_names" {
  default = ["luisvanegas.co", "test.luisvanegas.co"]
}

# LOCALS CONSTANTS
/* 
I declared the local constants
*/
locals {
  DOMAIN_NAMES_FOR_SSL = [for domain in var.domain_names : "*.${domain}"]
  HOSTED_ZONE_ID       = "Z037462919PCGJ91EZV5G"
  PRINCIPAL_DOMAIN     = "luisvanegas.co"
}


# HOSTED ZONE
/* 
// Not create the Zone because the NS record is change  
resource "aws_route53_zone" "hosted_zone" {
  name = local.PRINCIPAL_DOMAIN
} 
*/

# WWW RECORDS
/* 
# count: this attrib defined the number of times the resource will be executed.

This resource create the record for the subdomain www of the principal domain: luisvanegas.co and other 
subdomains defined initially for example test.luisvanegas.co and this record redirect 
the traffic of all www subdomains to  all principal domains defined initially into domain_names
NOTE: there will be one WWW per domain defined into variable domain_names
*/
resource "aws_route53_record" "www_records" {
  zone_id = local.HOSTED_ZONE_ID
  count   = length(var.domain_names)
  name    = "www.${element(var.domain_names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${element(var.domain_names, count.index)}"]
}

# BUCKECTS S3
/* 
# count: this attrib defined the number of times the resource will be executed.

This resource create the bucket for the all domains defined initially into domain_names and this 
buckets is where the resources of pages is save or deployed for all domians.
NOTE: there will be one BUCKET per domain defined into variable domain_names
*/
resource "aws_s3_bucket" "buckets" {
  count  = length(var.domain_names)
  bucket = element(var.domain_names, count.index)
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# CERTIFICATE MANAGER
/* 
This resource create the certificate for all subdomains and domain of luisvanegas.co, for this I use the expression: *.
this resources create the CNAMES record for validate the certificate. in this case I use the local 
constant DOMAIN_NAMES_FOR_SSL defined initially into locals for all domains and subdomains. 
this create one certificate, no more!!!
*/
resource "aws_acm_certificate" "certs" {
  domain_name               = local.PRINCIPAL_DOMAIN
  validation_method         = "DNS"
  subject_alternative_names = local.DOMAIN_NAMES_FOR_SSL
}
resource "aws_route53_record" "certs_records" {
  for_each = {
    for dvo in aws_acm_certificate.certs.domain_validation_options : dvo.domain_name => {
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
resource "aws_acm_certificate_validation" "certs_validations" {
  certificate_arn         = aws_acm_certificate.certs.arn
  validation_record_fqdns = [for record in aws_route53_record.certs_records : record.fqdn]
}

# DISTRIBUTIONS
/* 
# count: this attrib defined the number of times the resource will be executed.

This resource create the distribution for the domains and subdomains www corresponding to the buckets 
created here, this are defined with the attribute "aliases".
this distribution serve the content of s3 bucket called from some domain defined initially into domain_names
NOTE: there will be one DISTRIBUTION per domain defined into variable domain_names
*/
resource "aws_cloudfront_distribution" "s3_distros" {
  count               = length(aws_s3_bucket.buckets)
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["${element(aws_s3_bucket.buckets, count.index).id}", "www.${element(aws_s3_bucket.buckets, count.index).id}"]
  origin {
    domain_name = element(aws_s3_bucket.buckets, count.index).website_endpoint
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
    acm_certificate_arn = aws_acm_certificate.certs.arn
  }
}

# PRINCIPAL RECORDS
/* 
# count: this attrib defined the number of times the resource will be executed.

This resource create the principal records of type A for the domains or subdomains defined initially into domain_names
This resource record redirects the traffic of each record created here to the corresponding distribution
NOTE: there will be one RECORD per domain defined into variable domain_names
*/
resource "aws_route53_record" "principals_records" {
  zone_id = local.HOSTED_ZONE_ID
  count   = length(var.domain_names)
  name    = element(var.domain_names, count.index)
  type    = "A"
  alias {
    name                   = element(aws_cloudfront_distribution.s3_distros, count.index).domain_name
    zone_id                = element(aws_cloudfront_distribution.s3_distros, count.index).hosted_zone_id
    evaluate_target_health = true
  }
}
