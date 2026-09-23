provider "virtfusion" {
  endpoint  = local.hostbrr_endpoint
  api_token = data.onepassword_item.hostbrr_api.credential
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
