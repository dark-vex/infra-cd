terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "oci-teleport"
    }
  }

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 8.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}
