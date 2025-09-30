resource "proxmox_virtual_environment_vm" "k3s_cp_1" {
  name        = "k3s-cp-1.ddlns.net"
  description = "k3s cp 1"
  tags        = ["automation", "ubuntu", "k3s_cp_1"]

  node_name = "pvnode1"

  vm_id = "500"

  count = 0

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/jammy-server-cloudimg-amd64.img"
    interface    = "virtio0"
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
      keys     = [trimspace(tls_private_key.deploy_key.public_key_openssh)]
      password = random_password.k3s_cp_1_password.result
      username = "ubuntu"
    }

    user_data_file_id = proxmox_virtual_environment_file.ubuntu_cloud_config_1.id
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  cpu {
    cores = 8
  }

  memory {
    dedicated = 14384
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname k3s-cp-1.ddlns.net"]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = local_file.deploy_key_file.id
    }
  }

}

resource "random_password" "k3s_cp_1_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

output "k3s_cp_1_password" {
  value     = random_password.k3s_cp_1_password.result
  sensitive = true
}

output "k3s_cp_1_ip" {
  value = flatten(proxmox_virtual_environment_vm.k3s_cp_1[*].ipv4_addresses[1])
}
