resource "proxmox_virtual_environment_vm" "alicloud3" {
  name        = "alicloud3${count.index + 1}.ddlns.net"
  description = "alicloud3${count.index + 1} Server"
  tags        = ["automation", "ubuntu", "alicloud3${count.index + 1}"]

  node_name = "rabbit-01-psp"

  vm_id = "80${count.index + 1}"

  count = 1

  agent {
    enabled = false
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/aliyun_3_x64_20G_nocloud_alibase_20220907.img"
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
      keys     = [trimspace(tls_private_key.alicloud3_key.public_key_openssh)]
      password = random_password.alicloud3_password.result
      username = "alinux"
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_alicloud3.id
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

resource "random_password" "alicloud3_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "alicloud3_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "alicloud3_key_file" {
  content  = tls_private_key.alicloud3_key.private_key_pem
  filename = "${path.module}/alicloud3-ssh.key"
  file_permission = 0600
}

output "alicloud3_password" {
  value     = random_password.alicloud3_password.result
  sensitive = true
}

output "alicloud3_private_key" {
  value     = tls_private_key.alicloud3_key.private_key_pem
  sensitive = true
}

output "alicloud3_public_key" {
  value = tls_private_key.alicloud3_key.public_key_openssh
}

#output "alicloud3_ip" {
#  value = flatten(proxmox_virtual_environment_vm.alicloud3[*].ipv4_addresses[1])
#}

output "alicloud3_image_id" {
  value = proxmox_virtual_environment_file.ubuntu2204_cloud_image.id
}
