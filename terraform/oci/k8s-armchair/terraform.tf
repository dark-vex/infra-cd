terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "oci-k8s-armchair"
    }
  }

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 6.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}
