resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_raw {
    data = <<EOF
#cloud-config
chpasswd:
  #list: |
  #  ubuntu:example
  expire: false
hostname: web1.ddlns.net
packages:
  - qemu-guest-agent
users:
  - default
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.webserver_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "ubuntu.cloud-config.yaml"
  }
}
