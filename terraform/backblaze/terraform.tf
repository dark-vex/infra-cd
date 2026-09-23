terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-backblaze"
    }
  }

  required_providers {
    b2 = {
      source  = "registry.terraform.io/dark-vex/b2"
      version = "0.14.0-fix.1"
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
