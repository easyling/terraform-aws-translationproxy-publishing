resource "aws_cloudfront_distribution" "translations_at_root" {
  count = length(var.locales)
  enabled = true
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "OPTIONS",
      "HEAD",
      "POST",
      "PUT",
      "DELETE",
    ]
    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    target_origin_id = "translationproxy-${var.locales[count.index].language}"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = [
        "CloudFront-Viewer-Country",
        "Host",
        "Origin",
        "Referer",
        "User-Agent",
        "X-TranslationProxy-CrawlingFor",
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

resource "aws_cloudfront_distribution" "translation_at_prefix" {
  count = length(var.prefix_to_language)
  enabled = true
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "OPTIONS",
      "HEAD",
      "POST",
      "PUT",
      "DELETE",
    ]
    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    target_origin_id = "origin"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = [
        "CloudFront-Viewer-Country",
        "Host",
        "Origin",
        "Referer",
        "User-Agent",
        "X-TranslationProxy-CrawlingFor",
      ]
    }
  }

  origin {
    domain_name = var.source_domain
    origin_id = "origin"
  }

  dynamic "origin" {
    for_each = var.prefix_to_language
    iterator = prefix
    content {
      domain_name = "${prefix.value.language}.${var.project}.${var.app_domain}"
      origin_id = "translationproxy-${prefix.value.language}"

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
          value = var.source_domain
        }
    }
  }
  dynamic "ordered_cache_behavior" {
    for_each = var.prefix_to_language
    iterator = path_object

    content {
      allowed_methods = [
        "GET",
        "OPTIONS",
        "HEAD",
        "POST",
        "PUT",
        "DELETE",
      ]
      cached_methods = [
        "GET",
        "HEAD",
        "OPTIONS",
      ]

      forwarded_values {
        query_string = true
        cookies {
          forward = "all"
        }
        headers = [
          "CloudFront-Viewer-Country",
          "Host",
          "Origin",
          "Referer",
          "User-Agent",
          "X-TranslationProxy-CrawlingFor",
        ]
      }

      viewer_protocol_policy = "allow-all"
      path_pattern = path_object.value.prefix

      target_origin_id = "translationproxy-${path_object.value.language}"
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
