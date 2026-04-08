locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
}

data "onepassword_item" "rabbit_01_psp" {
  vault = local.onepassword_vault
  uuid  = "h7fhsftvpum7r4b3rnqznz4lym"
}

data "onepassword_item" "ssh_public_key" {
  vault = local.onepassword_vault
  uuid  = "mdroj6xsbartnjo6f5atpyxfsy"
}

data "onepassword_item" "ssh_public_key_new" {
  vault = local.onepassword_vault
  uuid  = "ej2xghg37546ix5tclkkwse2l4"
}

locals {
  ssh_public_key     = data.onepassword_item.ssh_public_key.note_value
  ssh_public_key_new = data.onepassword_item.ssh_public_key_new.note_value
}

data "external" "rabbit_01_psp_token" {
  program = ["${path.module}/setup-rabbit.sh"]
}

data "onepassword_item" "lxc_access" {
  vault = local.onepassword_vault
  uuid  = "ldva6u4clsjb7ueiydldnpsrc4"
}
