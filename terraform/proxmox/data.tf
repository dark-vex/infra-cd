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

# SSH keys
data "onepassword_item" "ssh_key" {
  vault = local.onepassword_vault
  uuid  = "fg6utxhi7yzuxmheo3a4dpqcaq"
}

data "onepassword_item" "ssh_key_new" {
  vault = local.onepassword_vault
  uuid  = "duivcbljdj4nufcxr6wgwcnsrq"
}

# API token retrieval for rabbit-01-psp (uses API token auth)
data "external" "rabbit_01_psp_token" {
  program = ["${path.module}/setup-rabbit.sh"]
}

# LXC access password (generated)
resource "onepassword_item" "lxc_access" {
  vault = local.onepassword_vault

  title    = "Proxmox LXC Access"
  category = "password"
}
