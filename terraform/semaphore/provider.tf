provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "semaphoreui" {
  api_base_url = "https://${data.onepassword_item.semaphore.url}/api"
  api_token    = data.onepassword_item.semaphore.password
}
