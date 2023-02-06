resource "proxmox_virtual_environment_vm" "webserver" {
  name        = "web${count.index + 1}.ddlns.net"
  description = "Web${count.index + 1} Server"
  tags        = ["automation", "ubuntu", "web${count.index + 1}"]

  node_name = "rabbit-01-psp"

  count = 2

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    #file_format  = "raw"
    size         = 10
  }

  initialization {
    datastore_id = "data-ssd"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = [trimspace(tls_private_key.webserver_key.public_key_openssh)]
      password = random_password.webserver_password.result
      username = "ubuntu"
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge = "vmbr1"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}

resource "random_password" "webserver_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "webserver_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "webserver_password" {
  value     = random_password.webserver_password.result
  sensitive = true
}

output "webserver_private_key" {
  value     = tls_private_key.webserver_key.private_key_pem
  sensitive = true
}

output "webserver_public_key" {
  value = tls_private_key.webserver_key.public_key_openssh
}

output "webserver_ip" {
  value = flatten(proxmox_virtual_environment_vm.webserver[*].ipv4_addresses)
}
