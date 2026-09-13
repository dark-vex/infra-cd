terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-backblaze"
    }
  }

  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
  }

  required_version = ">= 1.5.0"
}
