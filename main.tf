resource "aws_cloudfront_distribution" "translations_at_root" {
  count = length(var.locales)
  enabled = true
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "POST",
      "PUT",
      "DELETE",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    target_origin_id = "translationproxy-${var.locales[count.index].language}"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = [
        "*",
      ]
    }
  }

  origin {
    domain_name = "${var.locales[count.index].language}.${var.project}.${var.app_domain}"
    origin_id = "translationproxy-${var.locales[count.index].language}"

    custom_header {
      name = "X-TranslationProxy-Cache-Info"
      value = "disable"
    }
    custom_header {
      name = "X-TranslationProxy-EnableDeepRoot"
      value = "false"
    }
    custom_header {
      name = "X-TranslationProxy-AllowRobots"
      value = "true"
    }
    custom_header {
      name = "X-TranslationProxy-ServingDomain"
      value = var.locales[count.index].domain
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_cert_arn
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method = "sni-only"
  }
}
