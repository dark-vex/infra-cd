terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-aws"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
