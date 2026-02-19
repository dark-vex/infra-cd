# Cloud images and LXC templates for all Proxmox hosts
# Each host needs its own copy of templates

# ============================================================================
# rabbit-01-psp images
# ============================================================================

# Ubuntu 24.04 LXC template
#resource "proxmox_virtual_environment_download_file" "rabbit_ubuntu_24_04_lxc" {
#  provider     = proxmox.rabbit
#  content_type = "vztmpl"
#  datastore_id = "local"
#  node_name    = "rabbit-01-psp"
#  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
#}

# Ubuntu 22.04 LXC template
#resource "proxmox_virtual_environment_download_file" "rabbit_ubuntu_22_04_lxc" {
#  provider     = proxmox.rabbit
#  content_type = "vztmpl"
#  datastore_id = "local"
#  node_name    = "rabbit-01-psp"
#  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#}

# Ubuntu 22.04 cloud image for VMs
#resource "proxmox_virtual_environment_file" "rabbit_ubuntu_22_04_cloud" {
#  provider     = proxmox.rabbit
#  content_type = "iso"
#  datastore_id = "local"
#  node_name    = "rabbit-01-psp"
#
#  source_file {
#    path      = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
#    file_name = "jammy-server-cloudimg-amd64.img"
#  }
#}

# Debian 11 cloud image
resource "proxmox_virtual_environment_file" "rabbit_debian_11_cloud" {
  provider     = proxmox.rabbit
  content_type = "iso"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_file {
    path      = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
    file_name = "debian-11-genericcloud-amd64.img"
  }
}

# ============================================================================
# gozzi-01-bio images
# ============================================================================

# Ubuntu 24.04 LXC template
#resource "proxmox_virtual_environment_download_file" "gozzi_ubuntu_24_04_lxc" {
#  provider     = proxmox.gozzi
#  content_type = "vztmpl"
#  datastore_id = "local"
#  node_name    = "gozzi-01-bio"
#  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
#}
#
## Ubuntu 22.04 LXC template
#resource "proxmox_virtual_environment_download_file" "gozzi_ubuntu_22_04_lxc" {
#  provider     = proxmox.gozzi
#  content_type = "vztmpl"
#  datastore_id = "local"
#  node_name    = "gozzi-01-bio"
#  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#}
#
## Ubuntu 22.04 cloud image for VMs
#resource "proxmox_virtual_environment_file" "gozzi_ubuntu_22_04_cloud" {
#  provider     = proxmox.gozzi
#  content_type = "iso"
#  datastore_id = "local"
#  node_name    = "gozzi-01-bio"
#
#  source_file {
#    path      = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
#    file_name = "jammy-server-cloudimg-amd64.img"
#  }
#}
#
## ============================================================================
## ec200 images
## ============================================================================
#
## Ubuntu 24.04 LXC template
#resource "proxmox_virtual_environment_download_file" "ec200_ubuntu_24_04_lxc" {
#  provider     = proxmox.ec200
#  content_type = "vztmpl"
#  datastore_id = "local"
#  node_name    = "pve-ec200"
#  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
#}
#
## Ubuntu 22.04 LXC template
#resource "proxmox_virtual_environment_download_file" "ec200_ubuntu_22_04_lxc" {
#  provider     = proxmox.ec200
#  content_type = "vztmpl"
#  datastore_id = "local"
#  node_name    = "pve-ec200"
#  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#}
#
## Ubuntu 22.04 cloud image for VMs
#resource "proxmox_virtual_environment_file" "ec200_ubuntu_22_04_cloud" {
#  provider     = proxmox.ec200
#  content_type = "iso"
#  datastore_id = "local"
#  node_name    = "pve-ec200"
#
#  source_file {
#    path      = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
#    file_name = "jammy-server-cloudimg-amd64.img"
#  }
#}
