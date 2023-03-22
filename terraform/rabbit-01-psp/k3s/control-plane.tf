resource "proxmox_virtual_environment_vm" "controlplane" {
  name        = "cp${count.index + 1}.ddlns.net"
  description = "cp${count.index + 1} Server"
  tags        = ["automation", "ubuntu", "cp${count.index + 1}"]

  node_name = "rabbit-01-psp"

  count = 0

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/jammy-server-cloudimg-amd64.img"
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
      keys     = [trimspace(tls_private_key.k3s_key.public_key_openssh)]
      password = random_password.k3s_password.result
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
    cores = 2
  }

  memory {
    dedicated = 2048
  }

}

output "controlplane_ip" {
  value = flatten(proxmox_virtual_environment_vm.controlplane[*].ipv4_addresses[1])
}
