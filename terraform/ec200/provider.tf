terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.8.0"
    }
  }
}

provider "proxmox" {
  virtual_environment {
    endpoint = "https://<fqdn or ip>:8006"
    username = "<username>"
    password = "<password>"
    insecure = true
    #otp = "<string>"
  }
}
