provider "portainer" {
  endpoint = local.portainer_url
  api_key  = local.portainer_fields["api_key"]

  # Portainer is published through a Cloudflare Tunnel behind Cloudflare
  # Access; the service token authenticates the Terraform executor.
  custom_headers = {
    "CF-Access-Client-Id"     = local.portainer_fields["cf_access_client_id"]
    "CF-Access-Client-Secret" = local.portainer_fields["cf_access_client_secret"]
  }
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "sops" {}
