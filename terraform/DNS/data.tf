locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
}

data "onepassword_item" "cloudflare_api_token" {
  vault = local.onepassword_vault
  uuid  = "" # TODO: fill in UUID after creating "Cloudflare DNS API Token" item in 1Password
}

data "onepassword_item" "cloudflare_zones" {
  vault = local.onepassword_vault
  uuid  = "" # TODO: fill in UUID after creating "Cloudflare Zone IDs" item in 1Password
}

data "onepassword_item" "infra_ips" {
  vault = local.onepassword_vault
  uuid  = "" # TODO: fill in UUID after creating "Infrastructure IPs" item in 1Password
}

locals {
  # Zone IDs — sourced from custom fields of the "Cloudflare Zone IDs" 1Password item.
  # Add one entry per zone as you import additional domains.
  ddlns_net_zone_id = one([for f in data.onepassword_item.cloudflare_zones.fields : f.value if f.label == "ddlns_net"])
  arl_fail_zone_id  = one([for f in data.onepassword_item.cloudflare_zones.fields : f.value if f.label == "arl_fail"])
  arlo_fail_zone_id = one([for f in data.onepassword_item.cloudflare_zones.fields : f.value if f.label == "arlo_fail"])

  # IP addresses — sourced from custom fields of the "Infrastructure IPs" 1Password item.
  # Add one entry per unique IP address as you discover them during import.
  hm_ip          = one([for f in data.onepassword_item.infra_ips.fields : f.value if f.label == "hm_ip"])
  khnuc_ip       = one([for f in data.onepassword_item.infra_ips.fields : f.value if f.label == "khnuc_ip"])
  eu_aws_free_ip = one([for f in data.onepassword_item.infra_ips.fields : f.value if f.label == "eu_aws_free_ip"])
}
