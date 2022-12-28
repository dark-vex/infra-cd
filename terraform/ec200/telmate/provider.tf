# https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=2.9.11"
    }
  }
}

provider "proxmox" {
  # Configuration options
  pm_api_url = "https://10.10.8.10:8006/api2/json"
  pm_user = "root@pam"
  pm_password = "<password>"
  # pm_api_token_id = "automation"
  # pm_api_token_secret = "op://k8s_secrets/ProxMoxAPI/Section_ff4xklwq5prpyje6rdcib76mvq/pm_api_token_secret"
  pm_tls_insecure = true
  # pm_otp = "<string>"
}

resource "proxmox_vm_qemu" "resource-name" {
  name        = "VM-name"
  target_node = "pvnode1"
  iso         = "local:iso/ubuntu-20.04.2-live-server-amd64.iso"

  ### or for a Clone VM operation
  # clone = "template to clone"

  ### or for a PXE boot VM operation
  # pxe = true
  # boot = "net0;scsi0"
  # agent = 0
}
