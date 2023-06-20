resource "proxmox_virtual_environment_vm" "okd" {
  name        = "okd${count.index + 1}.ddlns.net"
  description = "okd${count.index + 1} Server"
  tags        = ["automation", "fedoracoreos", "okd${count.index + 1}"]

  node_name = "rabbit-01-psp"

  vm_id = "80${count.index + 1}"

  count = 1

  # start/stop a VM
  started = false

  agent {
    enabled = false
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/fedora-coreos-38.img"
    interface    = "virtio0"
    #file_format  = "raw"
    size         = 200
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
      keys     = [trimspace(tls_private_key.okd_key.public_key_openssh)]
      password = random_password.okd_password.result
      username = "coreos"
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_okd.id
  }

  network_device {
    bridge = "vmbr2"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  cpu {
    cores = 8
  }

  memory {
    dedicated = 16384
  }

}

resource "random_password" "okd_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "okd_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "okd_key_file" {
  content  = tls_private_key.okd_key.private_key_pem
  filename = "${path.module}/okd-ssh.key"
  file_permission = 0600
}

output "okd_password" {
  value     = random_password.okd_password.result
  sensitive = true
}

output "okd_private_key" {
  value     = tls_private_key.okd_key.private_key_pem
  sensitive = true
}

output "okd_public_key" {
  value = tls_private_key.okd_key.public_key_openssh
}

#output "okd_ip" {
#  value = flatten(proxmox_virtual_environment_vm.okd[*].ipv4_addresses[1])
#}

output "okd_image_id" {
  value = proxmox_virtual_environment_file.fedora_coreos_cloud_image.id
}
