resource "proxmox_virtual_environment_file" "ubuntu_cloud_config_1" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pvnode1"

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
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.deploy_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "ubuntu.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_config_2" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pvnode2"

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
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.deploy_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "ubuntu.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_config_3" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pvnode3"

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
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.deploy_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "ubuntu.cloud-config.yaml"
  }
}
