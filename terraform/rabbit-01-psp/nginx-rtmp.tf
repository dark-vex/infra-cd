resource "proxmox_virtual_environment_vm" "rtmp" {
  name        = "rtmp${count.index + 1}.ddlns.net"
  description = "rtmp${count.index + 1} Server"
  tags        = ["automation", "ubuntu", "rtmp${count.index + 1}"]

  node_name = "rabbit-01-psp"

  vm_id = "60${count.index + 1}"

  count = 1

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = proxmox_virtual_environment_file.ubuntu2204_cloud_image.id
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
      keys     = [trimspace(tls_private_key.rtmp_key.public_key_openssh)]
      password = random_password.rtmp_password.result
      username = "ubuntu"
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_rtmp.id
  }

  network_device {
    bridge = "vmbr1"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  cpu {
    cores = 8
  }

  memory {
    dedicated = 8192
  }

  provisioner "local-exec" {
    command = "terraform output rtmp_private_key > ssh_key_priv_rtmp && chmod 600 ssh_key_priv_rtmp"
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname rtmp${count.index + 1}.ddlns.net"]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("ssh_key_priv_rtmp")
    }
  }

}

resource "random_password" "rtmp_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "rtmp_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "rtmp_password" {
  value     = random_password.rtmp_password.result
  sensitive = true
}

output "rtmp_private_key" {
  value     = tls_private_key.rtmp_key.private_key_pem
  sensitive = true
}

output "rtmp_public_key" {
  value = tls_private_key.rtmp_key.public_key_openssh
}

output "rtmp_ip" {
  value = flatten(proxmox_virtual_environment_vm.rtmp[*].ipv4_addresses[1])
}

output "rtmp_image_id" {
  value = proxmox_virtual_environment_file.ubuntu2204_cloud_image.id
}
