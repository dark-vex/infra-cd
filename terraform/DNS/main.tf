module "bioadventures_eu" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.bioadventures_eu.id
  records = local.dns.zones.bioadventures_eu.records
}

module "birrificiosottobisio_ch" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.birrificiosottobisio_ch.id
  records = local.dns.zones.birrificiosottobisio_ch.records
}

module "ddlns_net" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.ddlns_net.id
  records = local.dns.zones.ddlns_net.records
}

# Released from Terraform management in favor of external-dns, which has
# adopted (and solely manages) these hosts' DNS records via each app's
# Ingress annotations - see Confluence "External DNS" > "Retiring a record
# from Terraform". Confirmed zero drift between the Terraform-declared and
# live Cloudflare values for all seven immediately before this release
# (2026-10-07). destroy = false: the live record stays exactly as-is,
# ownership just passes to external-dns's own upsert-only reconciliation.
#
# A bare `removed` block can't target a single for_each instance (only a
# whole resource, or a whole for_each matching the original expression) -
# confirmed via `terraform validate`, not assumed. Each instance is first
# `moved` to a standalone address with no corresponding resource block in
# config, then `removed` from that address - the documented pattern for
# per-instance for_each removal without `terraform state rm`.
moved {
  from = module.ddlns_net.cloudflare_dns_record.this["cloud_cname"]
  to   = cloudflare_dns_record.released_cloud_cname
}
removed {
  from = cloudflare_dns_record.released_cloud_cname
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.ddlns_net.cloudflare_dns_record.this["harbor"]
  to   = cloudflare_dns_record.released_harbor
}
removed {
  from = cloudflare_dns_record.released_harbor
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.ddlns_net.cloudflare_dns_record.this["jenkins"]
  to   = cloudflare_dns_record.released_jenkins
}
removed {
  from = cloudflare_dns_record.released_jenkins
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.ddlns_net.cloudflare_dns_record.this["s3_api_cname"]
  to   = cloudflare_dns_record.released_s3_api_cname
}
removed {
  from = cloudflare_dns_record.released_s3_api_cname
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.ddlns_net.cloudflare_dns_record.this["portainer_cname"]
  to   = cloudflare_dns_record.released_portainer_cname
}
removed {
  from = cloudflare_dns_record.released_portainer_cname
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.ddlns_net.cloudflare_dns_record.this["sso_cname"]
  to   = cloudflare_dns_record.released_sso_cname
}
removed {
  from = cloudflare_dns_record.released_sso_cname
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.ddlns_net.cloudflare_dns_record.this["test_sso_cname"]
  to   = cloudflare_dns_record.released_test_sso_cname
}
removed {
  from = cloudflare_dns_record.released_test_sso_cname
  lifecycle {
    destroy = false
  }
}

module "fastnetserv_com" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.fastnetserv_com.id
  records = local.dns.zones.fastnetserv_com.records
}

module "fastnetserv_net" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.fastnetserv_net.id
  records = local.dns.zones.fastnetserv_net.records
}

module "oasirho_com" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.oasirho_com.id
  records = local.dns.zones.oasirho_com.records
}

module "oasirho_it" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=074101b589b327eb612e07c38899fa1ee44087d9" # v1.0.0
  zone_id = local.dns.zones.oasirho_it.id
  records = local.dns.zones.oasirho_it.records
}
