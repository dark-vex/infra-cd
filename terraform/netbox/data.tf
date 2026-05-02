locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
}

data "onepassword_item" "netbox" {
  vault = local.onepassword_vault
  uuid = "5nqy6wpltkh7b4qqbbfb3z773i"
}
