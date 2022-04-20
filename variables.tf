variable "domain_to_locale" {
  description = "List of published language objects. The two attributes are `target` for the target language domain, and `locale` for the locale code. MUST be given as list of two-by-two letter locales."
  type = list(object({
    target = string
    locale = string
  }))
  default = []
}
variable "source_domain" {
  description = "The original domain of the site. Used to create the route for the root and set configuration during subdirectory publishing"
  type        = string
  default     = ""
}
variable "prefix_to_locale" {
  description = "List of published language objects. The two attributes are `target` for the path prefix, and `locale` for the locale code. MUST be given as list of two-by-two letter locales."
  default     = []
  type = list(object({
    target = string
    locale = string
    origin = bool
  }))
}

variable "project" {
  description = "The project ID provided by the LSP"
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
variable "forward_query_strings" {
  description = "Forward query strings to Easyling. CAUTION: may decrease effectiveness of caching, and lead to greater traffic numbers."
  default = false
  type = bool
}
