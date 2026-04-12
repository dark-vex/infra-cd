terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "tailscale"
    }
  }

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.28"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}
