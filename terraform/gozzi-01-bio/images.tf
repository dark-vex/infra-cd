#AlmaLinux 8
resource "proxmox_virtual_environment_file" "almalinux_8_cloud_image" {

  content_type = "iso"
  datastore_id = "local"
  node_name    = "gozzi-pve"

  source_file {
    path = "https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2"
    file_name = "AlmaLinux-8-GenericCloud-latest.x86_64.img"
  }

}

# AlmaLinux 8 UEFI
##resource "proxmox_virtual_environment_file" "almalinux_8_uefi_cloud_image" {
##
##  content_type = "iso"
##  datastore_id = "local"
##  node_name    = "gozzi-pve"
##
##  source_file {
##    path = "https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-UEFI-latest.x86_64.qcow2"
##    file_name = "AlmaLinux-8-GenericCloud-UEFI-latest.x86_64.img"
##  }
##
##}

#AlmaLinux 9
##resource "proxmox_virtual_environment_file" "almalinux_9_cloud_image" {
##
##  content_type = "iso"
##  datastore_id = "local"
##  node_name    = "gozzi-pve"
##
##  source_file {
##    path = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
##    file_name = "AlmaLinux-9-GenericCloud-latest.x86_64.img"
##  }
##
##}

# AliLinux 2
#resource "proxmox_virtual_environment_file" "alilinux_cloud_image" {
#
#  content_type = "iso"
#  datastore_id = "local"
#  node_name    = "gozzi-pve"
#
#  source_file {
#    path = "https://alinux2.oss-cn-hangzhou.aliyuncs.com/aliyun_2_1903_x64_20G_nocloud_alibase_20230103.qcow2"
#    file_name = "aliyun_2_1903_x64_20G_nocloud_alibase.img"
#    min_tls = "1.2"
#  }
#
#}

## AliLinux 3
#resource "proxmox_virtual_environment_file" "alilinux3_cloud_image" {
#
#  content_type = "iso"
#  datastore_id = "local"
#  node_name    = "gozzi-pve"
#
#  source_file {
#    path = "https://alinux3.oss-cn-hangzhou.aliyuncs.com/aliyun_3_x64_20G_nocloud_alibase_20220907.qcow2"
#    file_name = "aliyun_3_x64_20G_nocloud_alibase_20220907.img"
#  }
#
#}

# Debian 11 cloud image
resource "proxmox_virtual_environment_file" "debian_cloud_image" {

  content_type = "iso"
  datastore_id = "local"
  node_name    = "gozzi-pve"

  source_file {
    path = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
    file_name = "debian-11-genericcloud-amd64.img"
  }

}

# Fedora CoreOS
resource "proxmox_virtual_environment_file" "fedora_coreos_cloud_image" {

  content_type = "iso"
  datastore_id = "local"
  node_name    = "gozzi-pve"

  source_file {
    path = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230430.3.1/x86_64/fedora-coreos-38.20230430.3.1-openstack.x86_64.qcow2.xz"
    file_name = "fedora-coreos-38.img"
  }

}

# Ubuntu 20.04
resource "proxmox_virtual_environment_file" "ubuntu2004_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "gozzi-pve"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
    file_name = "focal-server-cloudimg-amd64.img"
  }
}

# Ubuntu 22.04
resource "proxmox_virtual_environment_file" "ubuntu2204_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "gozzi-pve"

  source_file {
    path = "http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    file_name = "jammy-server-cloudimg-amd64.img"
  }
}
