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
    endpoint = "https://10.0.0.2:8006"
    username = "root@pam"
    password = "<password>"
    insecure = true
    #otp = "<string>"
  }
}