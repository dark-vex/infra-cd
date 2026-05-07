module "bioadventures_eu" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.bioadventures_eu.id
  records = local.dns.zones.bioadventures_eu.records
}

module "birrificiosottobisio_ch" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.birrificiosottobisio_ch.id
  records = local.dns.zones.birrificiosottobisio_ch.records
}

module "ddlns_net" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.ddlns_net.id
  records = local.dns.zones.ddlns_net.records
}

module "fastnetserv_com" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.fastnetserv_com.id
  records = local.dns.zones.fastnetserv_com.records
}

module "fastnetserv_net" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.fastnetserv_net.id
  records = local.dns.zones.fastnetserv_net.records
}

module "oasirho_com" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.oasirho_com.id
  records = local.dns.zones.oasirho_com.records
}

module "oasirho_it" {
  source  = "github.com/dark-vex/terraform-cloudflare-dns?ref=v1.0.0"
  zone_id = local.dns.zones.oasirho_it.id
  records = local.dns.zones.oasirho_it.records
}
