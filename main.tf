resource "aws_cloudfront_distribution" "translations_at_root" {
  count   = length(var.domain_to_locale)
  enabled = true
  aliases = [
    var.domain_to_locale[count.index].target,
  ]
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
    target_origin_id       = "translationproxy-${var.domain_to_locale[count.index].locale}"
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
    domain_name = "${var.domain_to_locale[count.index].locale}.${var.project}.${var.app_domain}"
    origin_id   = "translationproxy-${var.domain_to_locale[count.index].locale}"

    custom_header {
      name  = "X-TranslationProxy-Cache-Info"
      value = "disable"
    }
    custom_header {
      name  = "X-TranslationProxy-EnableDeepRoot"
      value = "false"
    }
    custom_header {
      name  = "X-TranslationProxy-AllowRobots"
      value = "true"
    }
    custom_header {
      name  = "X-TranslationProxy-ServingDomain"
      value = var.domain_to_locale[count.index].target
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_cert_arn
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "translation_at_prefix" {
  count   = length(var.prefix_to_locale)
  enabled = true
  aliases = [
    var.source_domain,
  ]
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
    target_origin_id       = "origin"
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
    origin_id   = "origin"
  }

  dynamic "origin" {
    for_each = var.prefix_to_locale
    iterator = prefix
    content {
      domain_name = "${prefix.value.locale}.${var.project}.${var.app_domain}"
      origin_id   = "translationproxy-${prefix.value.locale}"

      custom_header {
        name  = "X-TranslationProxy-Cache-Info"
        value = "disable"
      }
      custom_header {
        name  = "X-TranslationProxy-EnableDeepRoot"
        value = "true"
      }
      custom_header {
        name  = "X-TranslationProxy-AllowRobots"
        value = "true"
      }
      custom_header {
        name  = "X-TranslationProxy-ServingDomain"
        value = var.source_domain
      }
    }
  }
  dynamic "ordered_cache_behavior" {
    for_each = var.prefix_to_locale
    iterator = prefix

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
      path_pattern           = prefix.value.target

      target_origin_id = "translationproxy-${prefix.value.locale}"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_cert_arn
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method       = "sni-only"
  }
}
