# DNS records are sourced entirely from secrets.sops.yaml (encrypted).
# To add a new zone: add an entry under `zones:` in secrets.sops.yaml,
# then add a module block below and an import block in imports.tf for each new record.

module "bioadventures_eu" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.bioadventures_eu.id
  records = local.dns.zones.bioadventures_eu.records
}

module "birrificiosottobisio_ch" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.birrificiosottobisio_ch.id
  records = local.dns.zones.birrificiosottobisio_ch.records
}

module "ddlns_net" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.ddlns_net.id
  records = local.dns.zones.ddlns_net.records
}

module "fastnetserv_com" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.fastnetserv_com.id
  records = local.dns.zones.fastnetserv_com.records
}

module "fastnetserv_net" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.fastnetserv_net.id
  records = local.dns.zones.fastnetserv_net.records
}

module "oasirho_com" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.oasirho_com.id
  records = local.dns.zones.oasirho_com.records
}

module "oasirho_it" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.oasirho_it.id
  records = local.dns.zones.oasirho_it.records
}

# State migration: rename flat cloudflare_record.* resources (pre-module) into module addresses.
# These are no-ops once applied; safe to remove after the first successful apply.
moved {
  from = cloudflare_record.harbor
  to   = module.ddlns_net.cloudflare_record.this["harbor"]
}

moved {
  from = cloudflare_record.jenkins
  to   = module.ddlns_net.cloudflare_record.this["jenkins"]
}

moved {
  from = cloudflare_record.notary_harbor
  to   = module.ddlns_net.cloudflare_record.this["notary_harbor"]
}

# arl.fail and arlo.fail zones no longer exist in Cloudflare and have been removed.
# If stale state entries remain from a previous apply, remove them before running plan:
#   terraform state rm cloudflare_record.arl_fail cloudflare_record.arl_fail_www
#   terraform state rm cloudflare_record.arlo_fail cloudflare_record.arlo_fail_www
