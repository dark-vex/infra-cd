# 1Password provider
provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "sops" {}

# Proxmox provider for gozzi-01-bio (LUG, Switzerland)
# Uses username/password authentication
provider "proxmox" {
  alias    = "gozzi_pve"
  endpoint = data.onepassword_item.gozzi_01_bio.hostname
  #endpoint = "https://100.69.111.69:8006"
  #username = data.onepassword_item.gozzi_01_bio.username
  #password = data.onepassword_item.gozzi_01_bio.password
  api_token = data.external.gozzi_01_bio_token.result.api_token
  insecure  = true

  ssh {
    agent    = true
    username = "root"
    password = data.onepassword_item.gozzi_01_bio.password
  }
}

# Proxmox provider for hpelvisor (LUG, Switzerland)
# NOTE: prior to CODE-27, this ssh block wrongly referenced
# gozzi_01_bio's password instead of hpelvisor_bio's - dormant because no
# resource in this stack had ever exercised provider SSH auth against
# hpelvisor before (every disk.file_id create here is the first QEMU
# disk-from-image create; every other file_id use is an LXC
# template_file_id, a plain API call with no SSH involved).
# Uses username/password authentication
provider "proxmox" {
  alias    = "hpelvisor"
  endpoint = data.onepassword_item.hpelvisor_bio.hostname
  #endpoint = "https://100.101.188.115:8006"
  #username = data.onepassword_item.hpelvisor_bio.username
  #password = data.onepassword_item.hpelvisor_bio.password
  api_token = data.external.hpelvisor_bio_token.result.api_token
  insecure  = true

  ssh {
    agent    = true
    username = "root"
    password = data.onepassword_item.hpelvisor_bio.password
  }
}
