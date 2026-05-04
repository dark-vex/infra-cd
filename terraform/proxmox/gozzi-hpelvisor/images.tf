# Cloud images and LXC templates for gozzi-01-bio and hpelvisor

# ============================================================================
# gozzi-01-bio images
# ============================================================================

# Ubuntu 24.04 LXC template
resource "proxmox_download_file" "gozzi_ubuntu_24_04_lxc" {
  provider     = proxmox.gozzi_pve
  content_type = "vztmpl"
  datastore_id = "local"
  #node_name    = "gozzi-01-bio"
  node_name = "gozzi-pve"
  url       = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

## Ubuntu 22.04 LXC template
resource "proxmox_download_file" "gozzi_ubuntu_22_04_lxc" {
  provider     = proxmox.gozzi_pve
  content_type = "vztmpl"
  datastore_id = "local"
  #node_name    = "gozzi-01-bio"
  node_name = "gozzi-pve"
  url       = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

moved {
  from = proxmox_virtual_environment_download_file.gozzi_ubuntu_24_04_lxc
  to   = proxmox_download_file.gozzi_ubuntu_24_04_lxc
}

moved {
  from = proxmox_virtual_environment_download_file.gozzi_ubuntu_22_04_lxc
  to   = proxmox_download_file.gozzi_ubuntu_22_04_lxc
}

## Ubuntu 22.04 cloud image for VMs
resource "proxmox_virtual_environment_file" "gozzi_ubuntu_22_04_cloud" {
  provider     = proxmox.gozzi_pve
  content_type = "iso"
  datastore_id = "local"
  #node_name    = "gozzi-01-bio"
  node_name = "gozzi-pve"

  source_file {
    path      = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    file_name = "jammy-server-cloudimg-amd64.img"
  }
}

# ============================================================================
# hpelvisor images
# ============================================================================

# Ubuntu 24.04 LXC template
resource "proxmox_download_file" "hpelvisor_ubuntu_24_04_lxc" {
  provider     = proxmox.hpelvisor
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "hpelvisor"
  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

## Ubuntu 22.04 LXC template
resource "proxmox_download_file" "hpelvisor_ubuntu_22_04_lxc" {
  provider     = proxmox.hpelvisor
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "hpelvisor"
  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

moved {
  from = proxmox_virtual_environment_download_file.hpelvisor_ubuntu_24_04_lxc
  to   = proxmox_download_file.hpelvisor_ubuntu_24_04_lxc
}

moved {
  from = proxmox_virtual_environment_download_file.hpelvisor_ubuntu_22_04_lxc
  to   = proxmox_download_file.hpelvisor_ubuntu_22_04_lxc
}

## Ubuntu 22.04 cloud image for VMs
resource "proxmox_virtual_environment_file" "hpelvisor_ubuntu_22_04_cloud" {
  provider     = proxmox.hpelvisor
  content_type = "iso"
  datastore_id = "local"
  node_name    = "hpelvisor"

  source_file {
    path      = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    file_name = "jammy-server-cloudimg-amd64.img"
  }
}
