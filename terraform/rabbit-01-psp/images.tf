# debian 11 cloud image
resource "proxmox_virtual_environment_file" "debian_cloud_image" {

  content_type = "iso"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_file {
    path = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
    file_name = "debian-11-genericcloud-amd64.img"
  }

}

# Ubuntu 20.04
resource "proxmox_virtual_environment_file" "ubuntu2004_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  }
}

# Ubuntu 22.04
resource "proxmox_virtual_environment_file" "ubuntu2204_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_file {
    path = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  }
}
