terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-auth0"
    }
  }

  required_providers {
    auth0 = {
      source = "auth0/auth0"
      # Floor is 1.51.0 (client_secret_wo on auth0_client_credentials;
      # options_client_secret_wo on auth0_connection landed one minor
      # earlier, in 1.50.0) - both are needed before any resource in this
      # stack backfills a secret via a write-only attribute. Unbounded
      # above so Renovate still owns the version per this repo's convention.
      version = ">= 1.51.0, < 2.0.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
  }

  # Higher than this repo's usual >= 1.5.0 floor: write-only managed-resource
  # attributes (auth0_connection.options_client_secret_wo,
  # auth0_client_credentials.client_secret_wo) require Terraform 1.11+.
  required_version = ">= 1.11"
}
