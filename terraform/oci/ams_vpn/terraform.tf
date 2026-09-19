terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "oci-ams-vpn"
    }
  }

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 9.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
  }

  required_version = ">= 1.5.0"
}
