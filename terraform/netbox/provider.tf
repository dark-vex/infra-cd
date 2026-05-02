provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "netbox" {
  server_url = data.onepassword_item.netbox.url
  api_token  = data.onepassword_item.netbox.password
}
