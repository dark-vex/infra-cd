variable "cloudflare_email" {
  description = "email of your cloudflare account"
  type        = string
  default     = ""
}

variable "cloudflare_api_key" {
  description = "API key of of your cloudflare account"
  type        = string
  default     = ""
}


variable "ddlns_net_zone_id" {
  description = "Zone ID of your cloudflare domain"
  type        = string
  default     = ""
}

variable "arl_fail_zone_id" {
  description = "Zone ID of your cloudflare domain"
  type        = string
  default     = ""
}

variable "arlo_fail_zone_id" {
  description = "Zone ID of your cloudflare domain"
  type        = string
  default     = ""
}

variable "cloudflare_domain" {
  description = "domain that you want to manage"
  type        = string
  default = ""
}

variable "hm_ip" {
  description = "Home IP"
  type        = string
  default = ""
}

variable "khnuc_ip" {
  description = "Kube NUC Home IP"
  type        = string
  default = ""
}

variable "eu_aws_free_ip" {
  description = "AWS free tier IP"
  type        = string
  default = ""
}
