provider "netbird" {
  # API token sourced from 1Password
  token   = data.onepassword_item.netbird_credentials.credential
  api_url = var.netbird_api_url
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
