provider "tailscale" {
  api_key = data.onepassword_item.tailscale_credentials.credential
  tailnet = data.onepassword_item.tailscale_credentials.username
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
