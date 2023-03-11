# debian 11 cloud image
#resource "proxmox_virtual_environment_file" "debian_cloud_image" {

#  content_type = "iso"
#  datastore_id = "local"
#  node_name    = "rabbit-01-psp"

#  source_file {
#    path = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.raw"
#  }

#}

# Ubuntu 22.04
resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  }
}
