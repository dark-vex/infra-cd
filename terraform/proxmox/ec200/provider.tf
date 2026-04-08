# 1Password provider
provider "onepassword" {
  url   = var.onepassword_endpoint
  token = var.onepassword_token
}

# Proxmox provider for ec200
# Uses username/password authentication
provider "proxmox" {
  alias    = "ec200"
  endpoint = data.onepassword_item.ec200.hostname
  username = data.onepassword_item.ec200.username
  password = data.onepassword_item.ec200.password
  insecure = true

  ssh {
    agent    = true
    username = "root"
    password = data.onepassword_item.ec200.password
  }
}
