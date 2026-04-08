# 1Password provider
provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

# Proxmox provider for gozzi-01-bio (LUG, Switzerland)
# Uses username/password authentication
provider "proxmox" {
  alias    = "gozzi_pve"
  endpoint = data.onepassword_item.gozzi_01_bio.hostname
  #endpoint = "https://100.69.111.69:8006"
  username = data.onepassword_item.gozzi_01_bio.username
  password = data.onepassword_item.gozzi_01_bio.password
  insecure = true

  ssh {
    agent    = true
    username = "root"
    password = data.onepassword_item.gozzi_01_bio.password
  }
}

# Proxmox provider for hpelvisor (LUG, Switzerland)
# Uses username/password authentication
provider "proxmox" {
  alias    = "hpelvisor"
  endpoint = data.onepassword_item.hpelvisor_bio.hostname
  #endpoint = "https://100.101.188.115:8006"
  username = data.onepassword_item.hpelvisor_bio.username
  password = data.onepassword_item.hpelvisor_bio.password
  insecure = true

  ssh {
    agent    = true
    username = "root"
    password = data.onepassword_item.gozzi_01_bio.password
  }
}
