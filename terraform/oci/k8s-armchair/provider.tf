terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "1.1.4"
    }
  }
}

provider "oci" {
   auth = "ResourcePrincipal"
   region = "${var.region}"
}
