# Ubuntu 20.04 cloud image
resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pvnode1"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pvnode2"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pvnode3"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  }
}