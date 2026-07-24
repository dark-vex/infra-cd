locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
  ips               = yamldecode(data.sops_file.ips.raw)
}

data "onepassword_item" "netbox" {
  vault = local.onepassword_vault
  uuid  = "q7b4mjw54keaujuqyqezw7dv7i"
}

data "sops_file" "ips" {
  source_file = "secrets.sops.yaml"
}
