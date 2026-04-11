terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "cloudflare-dns"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  api_token = data.onepassword_item.cloudflare_api_token.password
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
