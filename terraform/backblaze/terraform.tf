terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-backblaze"
    }
  }

  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.13"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}
