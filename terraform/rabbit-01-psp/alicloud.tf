resource "proxmox_virtual_environment_vm" "alicloud" {
  name        = "alicloud${count.index + 1}.ddlns.net"
  description = "alicloud${count.index + 1} Server"
  tags        = ["automation", "ubuntu", "alicloud${count.index + 1}"]

  node_name = "rabbit-01-psp"

  vm_id = "70${count.index + 1}"

  count = 1

  agent {
    enabled = false
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/aliyun_2_1903_x64_20G_nocloud_alibase_20220525.img"
    interface    = "virtio0"
    #file_format  = "raw"
    size         = 30
    iothread = true
  }

  initialization {
    datastore_id = "data-ssd"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = [trimspace(tls_private_key.alicloud_key.public_key_openssh)]
      password = random_password.alicloud_password.result
      username = "alinux"
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_alicloud.id
  }

  network_device {
    bridge = "vmbr1"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
  }

}

resource "random_password" "alicloud_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "alicloud_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "alicloud_key_file" {
  content  = tls_private_key.alicloud_key.private_key_pem
  filename = "${path.module}/alicloud-ssh.key"
  file_permission = 0600
}

output "alicloud_password" {
  value     = random_password.alicloud_password.result
  sensitive = true
}

output "alicloud_private_key" {
  value     = tls_private_key.alicloud_key.private_key_pem
  sensitive = true
}

output "alicloud_public_key" {
  value = tls_private_key.alicloud_key.public_key_openssh
}

#output "alicloud_ip" {
#  value = flatten(proxmox_virtual_environment_vm.alicloud[*].ipv4_addresses[1])
#}

output "alicloud_image_id" {
  value = proxmox_virtual_environment_file.ubuntu2204_cloud_image.id
}
