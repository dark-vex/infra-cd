terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "netbird"
    }
  }

  required_providers {
    netbird = {
      source  = "netbirdio/netbird"
      version = "~> 0.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}
