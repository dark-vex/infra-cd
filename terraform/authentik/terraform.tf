terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-authentik"
    }
  }

  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      # Pinned to the live instance's minor (chart authentik 2026.8.x); the
      # provider versions track Authentik releases and a mismatched minor can
      # misread the API schema. Renovate owns bumps.
      version = ">= 2026.8.0, < 2026.9.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3"
    }
  }

  required_version = ">= 1.5.0"
}
