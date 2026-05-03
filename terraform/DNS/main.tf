# DNS records are sourced entirely from secrets.sops.yaml (encrypted).
# To add a new zone: add an entry under `zones:` in secrets.sops.yaml,
# then add a module block below and an import block in imports.tf for each new record.

module "ddlns_net" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.ddlns_net.id
  records = local.dns.zones.ddlns_net.records
}

module "arl_fail" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.arl_fail.id
  records = local.dns.zones.arl_fail.records
}

module "arlo_fail" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.dns.zones.arlo_fail.id
  records = local.dns.zones.arlo_fail.records
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

moved {
  from = cloudflare_record.arl_fail
  to   = module.arl_fail.cloudflare_record.this["root"]
}

moved {
  from = cloudflare_record.arl_fail_www
  to   = module.arl_fail.cloudflare_record.this["www"]
}

moved {
  from = cloudflare_record.arlo_fail
  to   = module.arlo_fail.cloudflare_record.this["root"]
}

moved {
  from = cloudflare_record.arlo_fail_www
  to   = module.arlo_fail.cloudflare_record.this["www"]
}
