variable "domain_to_locale" {
  description = "List of published language objects. The two attributes are `domain` for the target language domain, and `locale` for the locale code. MUST be given as list of two-by-two letter locales."
  type = list(object({
    target = string
    locale = string
  }))
  default = []
}
variable "source_domain" {
  description = "The original domain of the site"
  type        = string
  default     = ""
}
variable "prefix_to_locale" {
  default = []
  type = list(object({
    target = string
    locale = string
  }))
}

variable "project" {
  description = "The project ID"
  type        = string
}
variable "app_domain" {
  description = "App domain provided by LSP"
  type        = string
}
variable "acm_cert_arn" {
  description = "ARN of the dynamic certificate provisioned by AWS. Can be left empty, in which case HTTPS will not work!"
  default     = ""
}
