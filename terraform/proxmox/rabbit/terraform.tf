terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "proxmox-rabbit"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.103"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
