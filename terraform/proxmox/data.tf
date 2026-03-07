# 1Password vault ID (shared across all items)
locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
}

# Proxmox host credentials
data "onepassword_item" "rabbit_01_psp" {
  vault = local.onepassword_vault
  uuid  = "h7fhsftvpum7r4b3rnqznz4lym"
}

data "onepassword_item" "gozzi_01_bio" {
  vault = local.onepassword_vault
  uuid  = "mfukjucb7uuljtldpncj3erlz4"
}

data "onepassword_item" "ec200" {
  vault = local.onepassword_vault
  uuid  = "gdotpytorvezveilqiq7t7ae3e"
}

# SSH public keys (stored as Secure Notes to avoid OpenSSH format parsing issues)
# Create two Secure Note items in 1Password, each with the public key in the note content
data "onepassword_item" "ssh_public_key" {
  vault = local.onepassword_vault
  uuid  = "mdroj6xsbartnjo6f5atpyxfsy"
}

data "onepassword_item" "ssh_public_key_new" {
  vault = local.onepassword_vault
  uuid  = "ej2xghg37546ix5tclkkwse2l4"
}

# Extract public keys from note content
locals {
  ssh_public_key     = data.onepassword_item.ssh_public_key.note_value
  ssh_public_key_new = data.onepassword_item.ssh_public_key_new.note_value
}

# API token retrieval for rabbit-01-psp (uses API token auth)
data "external" "rabbit_01_psp_token" {
  program = ["${path.module}/setup-rabbit.sh"]
}

# LXC access password (generated)
#resource "onepassword_item" "lxc_access" {
#  vault = local.onepassword_vault
#
#  title    = "Proxmox LXC Access"
#  category = "password"
#}
