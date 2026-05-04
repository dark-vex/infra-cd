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
