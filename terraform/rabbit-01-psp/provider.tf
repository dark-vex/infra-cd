terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "rabbit-01-psp"
    }
  }

  required_version = ">= 1.3.7"

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.60.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "1.1.4"
    }

  }
}

provider "proxmox" {
  endpoint = data.onepassword_item.rabbit_01_psp_token.hostname
  username = data.onepassword_item.rabbit_01_psp_token.username
  password = data.onepassword_item.rabbit_01_psp_token.password
  #otp = data.external.rabbit_01_psp_token.result.otp
  api_token = data.external.rabbit_01_psp_token.result.api_token
  insecure = true

  ssh {
    agent = true
    username = "root"
    password = data.onepassword_item.rabbit_01_psp_token.password
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

#output "test" {
#  value = data.external.rabbit_01_psp_token.result.otp
#}

#output "test" {
#   value = data.external.rabbit_01_psp_token.result.api_token
#}
