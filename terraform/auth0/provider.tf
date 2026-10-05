provider "auth0" {
  domain        = local.auth0_domain
  client_id     = data.onepassword_item.auth0.username
  client_secret = data.onepassword_item.auth0.password
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "sops" {}
