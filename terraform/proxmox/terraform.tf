terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "proxmox"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.83"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.1"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
