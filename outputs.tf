output "cf_domain" {
//  value = aws_cloudfront_distribution.translations_at_root[*].domain_name
  value = split("," , trim("%{ for distro in aws_cloudfront_distribution.translations_at_root[*] }%{ for alias in distro.aliases[*]}${alias} 300 IN CNAME ${distro.domain_name},%{ endfor }%{ endfor }", ","))
}
