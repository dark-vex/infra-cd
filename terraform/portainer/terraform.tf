terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-portainer"
    }
  }

  required_providers {
    portainer = {
      source = "portainer/portainer"
      # The provider is young (v2.0.0 added many BE resources untested against
      # a live BE server), and the lockfile is gitignored in this repo, so the
      # major cap is explicit. Renovate owns bumps within the range; review
      # each against the import plan before merging.
      version = ">= 2.0.0, < 3.0.0"
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

  required_version = ">= 1.11"
}
