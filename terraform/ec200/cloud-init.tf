resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pvnode1"

  source_raw {
    data = <<EOF
#cloud-config
chpasswd:
  list: |
    ubuntu:example
  expire: false
hostname: example-hostname
packages:
  - qemu-guest-agent
users:
  - default
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "example.cloud-config.yaml"
  }
}
