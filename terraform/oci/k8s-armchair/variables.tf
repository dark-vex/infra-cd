variable "onepassword_token" {
  description = "1Password Connect token"
  type        = string
  sensitive   = true
}

variable "onepassword_endpoint" {
  description = "1Password Connect endpoint URL"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region (e.g. eu-zurich-1)"
  type        = string
  default     = "eu-zurich-1"
}
