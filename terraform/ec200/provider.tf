terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "pve-ec200"
    }
  }

  required_version = ">= 1.3.7"

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.13.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "1.4.3"
    }

  }
}

provider "proxmox" {
  virtual_environment {
    endpoint = data.onepassword_item.pve_ec200_token.hostname
    username = data.onepassword_item.pve_ec200_token.username
    password = data.onepassword_item.pve_ec200_token.password
    insecure = true
  }
}

provider "onepassword" {
  # Speciry url or token
  url   = var.onepassword_endpoint
  token = var.onepassword_token

  # The following env variable can be used as alternative of url and token
  # OP_CONNECT_TOKEN
  # OP_CONNECT_HOST
  #token = data.external.login_in_one_password.result.token

}

variable "onepassword_token" {
  sensitive = true
}

variable "onepassword_endpoint" {
  sensitive = true
}
