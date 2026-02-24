terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "gozzi-01-bio"
    }
  }

  required_version = ">= 1.3.7"

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.97.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "3.2.1"
    }

  }
}

provider "proxmox" {
  endpoint = data.onepassword_item.gozzi_01_bio_token.hostname
  username = data.onepassword_item.gozzi_01_bio_token.username
  password = data.onepassword_item.gozzi_01_bio_token.password
  #otp = data.external.gozzi_01_bio_token_otp.result.otp
  insecure = true
}

provider "onepassword" {
  # Speciry url or token
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token

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
#  value = data.external.gozzi_01_bio_token_otp.result.otp
#}
