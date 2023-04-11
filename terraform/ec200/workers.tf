resource "proxmox_virtual_environment_vm" "k3s_worker_1" {
  name        = "k3s-worker-1.ddlns.net"
  description = "k3s worker 1"
  tags        = ["automation", "ubuntu", "k3s_worker_1"]

  node_name = "pvnode1"

  vm_id = "501"

  count = 1

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/jammy-server-cloudimg-amd64.img"
    interface    = "virtio0"
    size         = 10
    iothread = true
  }

  disk {
    datastore_id = "data-ssd"
    interface    = "virtio1"
    size	 = 300
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
      keys     = [trimspace(tls_private_key.deploy_key.public_key_openssh)]
      password = random_password.k3s_worker_1_password.result
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
    inline = ["sudo hostnamectl set-hostname k3s-worker-1.ddlns.net"]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = local_file.deploy_key_file.id
    }
  }

}

resource "random_password" "k3s_worker_1_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

output "k3s_worker_1_password" {
  value     = random_password.k3s_worker_1_password.result
  sensitive = true
}

output "k3s_worker_1_ip" {
  value = flatten(proxmox_virtual_environment_vm.k3s_worker_1[*].ipv4_addresses[1])
}

resource "proxmox_virtual_environment_vm" "k3s_worker_2" {
  name        = "k3s-worker-2.ddlns.net"
  description = "k3s worker 2"
  tags        = ["automation", "ubuntu", "k3s_worker_2"]

  node_name = "pvnode2"

  vm_id = "502"

  count = 1

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/jammy-server-cloudimg-amd64.img"
    interface    = "virtio0"
    size         = 10
    iothread = true
  }

  disk {
    datastore_id = "data-ssd"
    interface    = "virtio1"
    size	 = 300
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
      keys     = [trimspace(tls_private_key.deploy_key.public_key_openssh)]
      password = random_password.k3s_worker_2_password.result
      username = "ubuntu"
    }

    user_data_file_id = proxmox_virtual_environment_file.ubuntu_cloud_config_2.id
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
    inline = ["sudo hostnamectl set-hostname k3s-worker-2.ddlns.net"]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = local_file.deploy_key_file.id
    }
  }

}

resource "random_password" "k3s_worker_2_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

output "k3s_worker_2_password" {
  value     = random_password.k3s_worker_2_password.result
  sensitive = true
}

output "k3s_worker_2_ip" {
  value = flatten(proxmox_virtual_environment_vm.k3s_worker_2[*].ipv4_addresses[1])
}

resource "proxmox_virtual_environment_vm" "k3s_worker_3" {
  name        = "k3s-worker-3.ddlns.net"
  description = "k3s worker 3"
  tags        = ["automation", "ubuntu", "k3s_worker_3"]

  node_name = "pvnode3"

  vm_id = "503"

  count = 1

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/jammy-server-cloudimg-amd64.img"
    interface    = "virtio0"
    size         = 10
    iothread = true
  }

  disk {
    datastore_id = "data-ssd"
    interface    = "virtio1"
    size	 = 300
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
      keys     = [trimspace(tls_private_key.deploy_key.public_key_openssh)]
      password = random_password.k3s_worker_3_password.result
      username = "ubuntu"
    }

    user_data_file_id = proxmox_virtual_environment_file.ubuntu_cloud_config_3.id
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
    inline = ["sudo hostnamectl set-hostname k3s-worker-3.ddlns.net"]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = local_file.deploy_key_file.id
    }
  }

}

resource "random_password" "k3s_worker_3_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "deploy_key_file" {
  content  = tls_private_key.deploy_key.private_key_pem
  filename = "${path.module}/deploy-ssh.key"
}

output "k3s_worker_3_password" {
  value     = random_password.k3s_worker_1_password.result
  sensitive = true
}

output "k3s_worker_3_ip" {
  value = flatten(proxmox_virtual_environment_vm.k3s_worker_3[*].ipv4_addresses[1])
}


output "deploy_private_key" {
  value     = tls_private_key.deploy_key.private_key_pem
  sensitive = true
}

output "deploy_public_key" {
  value = tls_private_key.deploy_key.public_key_openssh
}
