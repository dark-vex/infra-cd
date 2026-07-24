# Cloud images and LXC templates for pve-ec200

# Ubuntu 24.04 LXC template
resource "proxmox_download_file" "ec200_ubuntu_24_04_lxc" {
  provider     = proxmox.ec200
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve-ec200"
  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

moved {
  from = proxmox_virtual_environment_download_file.ec200_ubuntu_24_04_lxc
  to   = proxmox_download_file.ec200_ubuntu_24_04_lxc
}
