# 1Password provider
provider "onepassword" {
  url   = var.onepassword_endpoint
  token = var.onepassword_token
}

# Proxmox provider for rabbit-01-psp (BGY, Italy)
# Uses API token authentication
provider "proxmox" {
  alias    = "rabbit"
  endpoint = data.onepassword_item.rabbit_01_psp.hostname
  #username = data.onepassword_item.rabbit_01_psp.username
  #password = data.onepassword_item.rabbit_01_psp.password
  api_token = data.external.rabbit_01_psp_token.result.api_token
  insecure  = true

  ssh {
    agent    = true
    username = "root"
    password = data.onepassword_item.rabbit_01_psp.password
  }
}
