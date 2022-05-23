terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

#resource "cloudflare_zone" "owendavies-net" {
# zone= var.cloudflare_domain
#}

# Create a record
resource "cloudflare_record" "harbor" {
  zone_id = var.ddlns_net_zone_id
  name    = "harbor"
  value   = var.hm_ip
  type    = "A"
  proxied = true
  #allow_overwrite = true
}

resource "cloudflare_record" "jenkins" {
  zone_id = var.ddlns_net_zone_id
  name    = "jenkins"
  value   = var.khnuc_ip
  type    = "A"
  #allow_overwrite = true
}

resource "cloudflare_record" "notary_harbor" {
  zone_id = var.ddlns_net_zone_id
  name    = "notary.harbor"
  value   = var.khnuc_ip
  type    = "A"
  #allow_overwrite = true
}

resource "cloudflare_record" "arl_fail" {
  name    = "arl.fail"
  proxied = true
  type    = "A"
  value   = var.eu_aws_free_ip
  zone_id = var.arl_fail_zone_id
}

resource "cloudflare_record" "arl_fail_www" {
  name    = "www"
  proxied = true
  type    = "CNAME"
  value   = "arl.fail"
  zone_id = var.arl_fail_zone_id
}

resource "cloudflare_record" "arlo_fail" {
  name    = "arlo.fail"
  proxied = true
  type    = "A"
  value   = var.eu_aws_free_ip
  zone_id = var.arlo_fail_zone_id
}

resource "cloudflare_record" "arlo_fail_www" {
  name    = "www"
  proxied = true
  type    = "CNAME"
  value   = "arlo.fail"
  zone_id = var.arlo_fail_zone_id
}