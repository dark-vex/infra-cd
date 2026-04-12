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

variable "netbird_api_url" {
  description = "Netbird management API URL (e.g. https://api.netbird.io)"
  type        = string
  default     = "https://api.netbird.io"
}
