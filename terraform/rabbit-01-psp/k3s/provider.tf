terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "rabbit-01-psp-k8s"
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
      version = "3.1.2"
    }

  }
}

provider "proxmox" {
  virtual_environment {
    endpoint = data.onepassword_item.rabbit_01_psp_token.hostname
    username = data.onepassword_item.rabbit_01_psp_token.username
    password = data.onepassword_item.rabbit_01_psp_token.password
    otp = data.external.rabbit_01_psp_token_otp.result.otp
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
