terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-mailserver"
    }
  }
}

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.33.2"
    }

    onepassword = {
      source = "1Password/onepassword"
      version = "1.1.4"
    }
  }
}

provider "hcloud" {
  token = data.onepassword_item.hcloud_token.password
}

provider "onepassword" {
  # Speciry url or token
  url = "http://10.10.8.20:32717"
  token = var.onepassword_token
  
  # The following env variable can be used as alternative of url and token
  # OP_CONNECT_TOKEN
  # OP_CONNECT_HOST
  #token = data.external.login_in_one_password.result.token

}

variable "onepassword_token" {
  sensitive = true
}
