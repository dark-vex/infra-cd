terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "proxmox-gozzi-hpelvisor"
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
  }
}
