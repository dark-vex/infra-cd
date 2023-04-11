terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}

provider "libvirt" {
    uri = "qemu+ssh://tf@hpelvisor/system?sshauth=privkey"
}
