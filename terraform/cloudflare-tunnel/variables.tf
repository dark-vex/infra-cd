variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "ddlns_net_zone_id" {
  description = "Zone ID for ddlns.net domain"
  type        = string
}

variable "tunnel_secret" {
  description = "Cloudflare tunnel secret (base64 encoded)"
  type        = string
  sensitive   = true
}

variable "tunnel_hostnames" {
  description = "List of hostnames to route through the tunnel"
  type        = list(string)
  default = [
    "harbor",
    "jenkins",
    "tv",
    "portainer",
    "sso",
    "unifi",
  ]
}
