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
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
  }
}

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from environment; no config needed here
}

provider "sops" {}
