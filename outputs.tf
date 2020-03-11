output "cf_domain" {
  value = aws_cloudfront_distribution.translations_at_root[*].domain_name
}
