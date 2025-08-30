resource "proxmox_virtual_environment_container" "proxy_container" {
  description = "Squid Proxy Container for content filtering"

  node_name = "rabbit-01-psp"
  vm_id     = 801

  initialization {
    hostname = "squid.ddlns.net"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [
        // Let's use 1Password here
        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh)
      ]
      password = random_password.ubuntu_container_password.result
    }
  }

  network_interface {
    name = "eth0"
  }

  disk {
    datastore_id = "data-ssd"
    size         = 30
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "ubuntu"
  }

  startup {
    order      = "10"
    up_delay   = "60"
    down_delay = "60"
  }

  start_on_boot = false

  tags = ["automation", "ubuntu", "proxy", "lxc", "container"]
}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "first-node"
  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
}

resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_container_password" {
  value     = random_password.ubuntu_container_password.result
  sensitive = true
}

output "ubuntu_container_private_key" {
  value     = tls_private_key.ubuntu_container_key.private_key_pem
  sensitive = true
}

output "ubuntu_container_public_key" {
  value = tls_private_key.ubuntu_container_key.public_key_openssh
}


resource "proxmox_virtual_environment_container" "rtmp_container" {
  description = "NGINX RTMP Container for streaming"

  node_name = "rabbit-01-psp"
  vm_id     = 803

  initialization {
    hostname = "rtmp${count.index + 1}.ddlns.net"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [
        // Let's use 1Password here
        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh)
      ]
      password = random_password.ubuntu_container_password.result
    }
  }

  network_interface {
    name = "eth0"
  }

  disk {
    datastore_id = "data-ssd"
    size         = 30
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "ubuntu"
  }

  startup {
    order      = "10"
    up_delay   = "60"
    down_delay = "60"
  }

  start_on_boot = false

  tags = ["automation", "ubuntu", "rtmp${count.index + 1}", "lxc", "container"]
}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "first-node"
  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
}

resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_container_password" {
  value     = random_password.ubuntu_container_password.result
  sensitive = true
}

output "ubuntu_container_private_key" {
  value     = tls_private_key.ubuntu_container_key.private_key_pem
  sensitive = true
}

output "ubuntu_container_public_key" {
  value = tls_private_key.ubuntu_container_key.public_key_openssh
}
