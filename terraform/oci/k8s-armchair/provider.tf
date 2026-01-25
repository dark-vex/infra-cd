terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "3.1.2"
    }
  }
}

provider "oci" {
   auth = "ResourcePrincipal"
   region = "${var.region}"
}
