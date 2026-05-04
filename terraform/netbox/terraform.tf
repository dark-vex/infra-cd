terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-netbox"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 5.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }
}
