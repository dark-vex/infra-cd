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
hostname: PLACEHOLDER.ddlns.net
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

resource "proxmox_virtual_environment_file" "cloud_config_rtmp" {
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
hostname: PLACEHOLDER.ddlns.net
packages:
  - qemu-guest-agent
users:
  - default
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.rtmp_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "ubuntu-rtmp.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_config_alicloud" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_raw {
    data = <<EOF
#cloud-config
#vim:syntax=yaml

packages:
  - qemu-guest-agent
# Create an account named alinux who is authorized to run sudo commands.
users:
  - default
  - name: alinux
    sudo: ['ALL=(ALL)   ALL']
    plain_text_passwd: aliyun
    lock_passwd: false
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.alicloud_key.public_key_openssh)}

# Create a YUM repository for Alibaba Cloud Linux 2.
yum_repos:
    base:
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/os/$basearch/
        enabled: true
        gpgcheck: true
        gpgkey: https://mirrors.aliyun.com/alinux/RPM-GPG-KEY-ALIYUN
        name: Aliyun Linux - $releasever - Base - mirrors.aliyun.com
    updates:
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/updates/$basearch/
        enabled: true
        gpgcheck: true
        gpgkey: https://mirrors.aliyun.com/alinux/RPM-GPG-KEY-ALIYUN
        name: Aliyun Linux - $releasever - Updates - mirrors.aliyun.com
    extras:
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/extras/$basearch/
        enabled: true
        gpgcheck: true
        gpgkey: https://mirrors.aliyun.com/alinux/RPM-GPG-KEY-ALIYUN
        name: Aliyun Linux - $releasever - Extras - mirrors.aliyun.com
    plus:
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/plus/$basearch/
        enabled: true
        gpgcheck: true
        gpgkey: https://mirrors.aliyun.com/alinux/RPM-GPG-KEY-ALIYUN
        name: Aliyun Linux - $releasever - Plus - mirrors.aliyun.com
runcmd:
  #- systemctl start qemu-guest-agent
  - yum install qemu-guest-agent -y && systemctl start qemu-guest-agent
EOF

    file_name = "alicloud.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_config_alicloud3" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"

  source_raw {
    data = <<EOF
#cloud-config
#vim:syntax=yaml

packages:
  - qemu-guest-agent
# Create an account named alinux who is authorized to run sudo commands.
users:
  - default
  - name: alinux
    sudo: ['ALL=(ALL)   ALL']
    plain_text_passwd: aliyun
    lock_passwd: false
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.alicloud3_key.public_key_openssh)}

# Create a YUM repository for Alibaba Cloud Linux 3.
yum_repos:
    alinux3-module:
        name: alinux3-module
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/module/$basearch/
        enabled: 1
        gpgcheck: 1
        gpgkey: https://mirrors.aliyun.com/alinux/$releasever/RPM-GPG-KEY-ALINUX-3
    alinux3-updates:
        name: alinux3-updates
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/updates/$basearch/
        enabled: 1
        gpgcheck: 1
        gpgkey: https://mirrors.aliyun.com/alinux/$releasever/RPM-GPG-KEY-ALINUX-3
    alinux3-plus:
        name: alinux3-plus
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/plus/$basearch/
        enabled: 1
        gpgcheck: 1
        gpgkey: https://mirrors.aliyun.com/alinux/$releasever/RPM-GPG-KEY-ALINUX-3
    alinux3-powertools:
        name: alinux3-powertools
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/powertools/$basearch/
        gpgcheck: 1
        enabled: 1
        gpgkey: https://mirrors.aliyun.com/alinux/$releasever/RPM-GPG-KEY-ALINUX-3
    alinux3-os:
        name: alinux3-os
        baseurl: https://mirrors.aliyun.com/alinux/$releasever/os/$basearch/
        gpgcheck: 1
        enabled: 1
        gpgkey: https://mirrors.aliyun.com/alinux/$releasever/RPM-GPG-KEY-ALINUX-3
EOF

    file_name = "alicloud3.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_config_okd" {
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
hostname: PLACEHOLDER.ddlns.net
packages:
  - qemu-guest-agent
users:
  - default
  - name: coreos
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace(tls_private_key.okd_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
runcmd:
  - systemctl start qemu-guest-agent
EOF

    file_name = "fedoracoreos.cloud-config.yaml"
  }
}
