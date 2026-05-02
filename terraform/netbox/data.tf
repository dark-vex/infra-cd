locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
}

data "onepassword_item" "netbox" {
  vault = local.onepassword_vault
  uuid  = "q7b4mjw54keaujuqyqezw7dv7i"
}
