resource "proxmox_virtual_environment_vm" "webserver" {
  name        = "web${count.index + 1}.ddlns.net"
  description = "Web${count.index + 1} Server"
  tags        = ["automation", "ubuntu", "web${count.index + 1}"]

  node_name = "rabbit-01-psp"

  vm_id = "50${count.index + 1}"

  count = 1

  started = false

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/jammy-server-cloudimg-amd64.img"
    interface    = "virtio0"
    file_format  = "raw"
    size         = 10
    iothread = true
  }

  disk {
    datastore_id = "data-ssd"
    interface    = "virtio1"
    file_format  = "raw"
    size	 = 30
    iothread     = true
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

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname web${count.index + 1}.ddlns.net && wget -O - https://get.ispconfig.org | sudo sh -s -- --i-know-what-i-am-doing"]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = local_file.webserver_key_file.id
    }
  }

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

resource "local_file" "webserver_key_file" {
  content  = tls_private_key.webserver_key.private_key_pem
  filename = "${path.module}/webserver-ssh.key"
  file_permission = 0600
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

##output "webserver_ip" {
  #value = flatten(proxmox_virtual_environment_vm.webserver[*].ipv4_addresses)
  ##value = flatten(proxmox_virtual_environment_vm.webserver[*].ipv4_addresses[1])
##}

output "webserver_image_id" {
  value = proxmox_virtual_environment_file.ubuntu2204_cloud_image.id
}
