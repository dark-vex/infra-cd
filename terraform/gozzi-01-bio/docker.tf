resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "gozzi-pve"

  source_raw {
    data = <<EOF
      #cloud-config
      chpasswd:
        #list: |
        #  ubuntu:example
        expire: false
      hostname: PLACEHOLDER.ddlns.net
      packages:
        - qemu-guest-agent
      users:
        - default
        - name: daniele
          groups: sudo
          shell: /bin/bash
          ssh-authorized-keys:
            - ${trimspace(tls_private_key.docker_key.public_key_openssh)}
          sudo: ALL=(ALL) NOPASSWD:ALL
          lock_passwd: false
      runcmd:
        - systemctl start qemu-guest-agent
      EOF

    file_name = "debian.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "docker" {
  name        = "dckbio-${count.index + 1}"
  description = "Docker Bio ${count.index + 1} Server"
  tags        = ["automation", "bckbio-${count.index + 1}", "debian"]

  node_name = "gozzi-pve"

  vm_id = "50${count.index + 1}"

  count = 1

  agent {
    enabled = true
  }

  disk {
    datastore_id = "data-ssd"
    file_id      = "local:iso/debian-12-genericcloud-amd64.img"
    interface    = "virtio0"
    file_format  = "raw"
    size         = 20
    iothread = true
  }

  disk {
    datastore_id = "data-ssd"
    interface    = "virtio1"
    file_format  = "raw"
    size	       = 100
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
      keys     = [trimspace(tls_private_key.docker_key.public_key_openssh)]
      password = random_password.docker_password.result
      username = "daniele"
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
    cores = 8
    type = "host"
  }

  memory {
    dedicated = 8192
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname dckbio-${count.index + 1}",
      "sudo apt-get update",
      "sudo apt-get install ca-certificates curl -y",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y"
      ]

    connection {
      host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
      type        = "ssh"
      user        = "daniele"
      private_key = "${file(local_file.docker_key_file.filename)}"
    }
  }

}

resource "random_password" "docker_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "docker_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "docker_key_file" {
  content  = tls_private_key.docker_key.private_key_pem
  filename = "${path.module}/docker-ssh.key"
  file_permission = 0600
}

output "docker_password" {
  value     = random_password.docker_password.result
  sensitive = true
}

output "docker_private_key" {
  value     = tls_private_key.docker_key.private_key_pem
  sensitive = true
}

output "docker_public_key" {
  value = tls_private_key.docker_key.public_key_openssh
}

output "docker_ip" {
  #value = flatten(proxmox_virtual_environment_vm.docker[*].ipv4_addresses)
  value = flatten(proxmox_virtual_environment_vm.docker[*].ipv4_addresses[1])
}

#output "docker_image_id" {
#  value = proxmox_virtual_environment_file.ubuntu2204_cloud_image.id
#}
