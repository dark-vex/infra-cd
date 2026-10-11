provider "authentik" {
  url   = local.authentik_url
  token = data.onepassword_item.authentik.password
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "sops" {}
