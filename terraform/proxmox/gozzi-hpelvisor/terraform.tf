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
      version = "~> 0.118"
    }

    # Held below 3.4.0: that release is built for x86-64-v3 and exits with
    # "CPU ISA level is lower than required" on gen8-runner (older Xeon).
    # Upstream: 1Password/terraform-provider-onepassword#412. Relax once a
    # fixed release ships.
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.4.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
  }
}
