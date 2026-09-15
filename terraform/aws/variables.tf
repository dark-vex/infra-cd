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
  description = "AWS region these buckets live in (confirmed live via aws s3api get-bucket-location on 2026-09-13)"
  type        = string
  default     = "eu-south-1"
}
