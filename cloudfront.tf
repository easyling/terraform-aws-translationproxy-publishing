resource "aws_cloudfront_distribution" "translations_at_root" {
  count = length(var.domain_to_locale)
  enabled = true
  aliases = [
    var.domain_to_locale[count.index].target,
  ]

  tags = {
    product = "translationproxy",
    project = var.project,
  }

  default_cache_behavior {
    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id = "translationproxy-${var.domain_to_locale[count.index].locale}"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = var.forward_query_strings
      cookies {
        forward = "all"
      }

      headers = [
        "CloudFront-Viewer-Country",
        "Origin",
        "Referer",
        "User-Agent",
        "X-TranslationProxy-CrawlingFor",
      ]
    }

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.domain_classifier.qualified_arn
    }
  }

  origin {
    domain_name = lower("${var.domain_to_locale[count.index].locale}-${var.project}.${var.app_domain}")
    origin_id = "translationproxy-${var.domain_to_locale[count.index].locale}"

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
      value = var.domain_to_locale[count.index].target
    }

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_read_timeout = 60
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
        "TLSv1.1",
        "TLSv1.2"
      ]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "%{ if var.acm_cert_arn == "" }${aws_acm_certificate.dynamic_cert[0].arn}%{ else }${var.acm_cert_arn}%{ endif }"
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "translation_at_prefix" {
  count = length(var.prefix_to_locale) > 0 ? 1 : 0
  enabled = true
  aliases = [
    var.source_domain,
  ]

  tags = {
    product = "translationproxy",
    project = var.project,
  }

  default_cache_behavior {
    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
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
        "Origin",
        "Referer",
        "User-Agent",
        "X-TranslationProxy-CrawlingFor",
      ]
    }
  }

  origin {
    domain_name = lower(var.source_domain)
    origin_id = "origin"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_read_timeout = 60
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = [
        "TLSv1.1",
        "TLSv1.2"
      ]
    }
  }

  dynamic "origin" {
    for_each = var.prefix_to_locale
    iterator = prefix
    content {
      domain_name = lower("${prefix.value.locale}-${var.project}.${var.app_domain}")
      origin_id = "translationproxy-${prefix.value.locale}"

      custom_origin_config {
        http_port = 80
        https_port = 443
        origin_read_timeout = 60
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols = [
          "TLSv1.1",
          "TLSv1.2"
        ]
      }

      custom_header {
        name = "X-TranslationProxy-Cache-Info"
        value = "disable"
      }
      custom_header {
        name = "X-TranslationProxy-EnableDeepRoot"
        value = "true"
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
    for_each = var.prefix_to_locale
    iterator = prefix

    content {
      allowed_methods = [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT",
      ]
      cached_methods = [
        "GET",
        "HEAD",
      ]

      forwarded_values {
        query_string = true
        cookies {
          forward = "all"
        }
        headers = [
          "CloudFront-Viewer-Country",
          "Origin",
          "Referer",
          "User-Agent",
          "X-TranslationProxy-CrawlingFor",
        ]
      }

      viewer_protocol_policy = "allow-all"
      path_pattern = prefix.value.target

      target_origin_id = prefix.value.origin ? "origin" : "translationproxy-${prefix.value.locale}"
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

resource "aws_acm_certificate" "dynamic_cert" {
  count = var.acm_cert_arn == "" ? 1 : 0
  validation_method = "DNS"
  domain_name = sort(var.domain_to_locale[*].target)[0]
  subject_alternative_names = slice(sort(var.domain_to_locale[*].target), 1, length(var.domain_to_locale[*].target))

  tags = {
    product = "translationproxy",
    project = var.project,
    Name = "${var.project}_managed_cert"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      subject_alternative_names,
      domain_name
    ]
  }
}

resource "aws_acm_certificate_validation" "dynamic_cert_validation" {
  count = var.acm_cert_arn == "" ? 1 : 0
  certificate_arn = aws_acm_certificate.dynamic_cert[0].arn
  timeouts {
    create = "1m"
  }
}


output "domains_for_subdomain_publishing" {
  value = [
    aws_cloudfront_distribution.translations_at_root.*.domain_name]
}
output "domains_for_subdirectory_publishing" {
  value = [
    aws_cloudfront_distribution.translation_at_prefix.*.domain_name]
}
output "cert_arn" {
  value = aws_acm_certificate.dynamic_cert[*].arn
}
output "cert_validation_options" {
  value = aws_acm_certificate.dynamic_cert[*].domain_validation_options
}
