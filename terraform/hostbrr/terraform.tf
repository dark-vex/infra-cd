terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "hostbrr"
    }
  }

  required_providers {
    virtfusion = {
      source  = "registry.terraform.io/dark-vex/virtfusion"
      version = "1.1.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}
