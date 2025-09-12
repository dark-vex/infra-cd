resource "onepassword_item" "lxc_access" {
  vault = "66qfxcmgwlhutunx6slav6fyve"

  title    = "Rabbit-01-PSP LXC Access"
  category = "password"

}

resource "proxmox_virtual_environment_container" "haproxy_container" {
  description = "HAProxy Container for reverse proxy and load balancing"

  node_name = "rabbit-01-psp"
  vm_id     = 800

  unprivileged = true

  count     = 1

  initialization {
    hostname = "haproxy${count.index + 1}.ddlns.net"

    ip_config {
      ipv4 {
        address = "10.10.20.172/24"
        gateway = "10.10.20.1"
      }
    }

    user_account {
      keys = [
        // Let's use 1Password here
        data.onepassword_item.ssh_key.public_key,
        data.onepassword_item.ssh_key_new.public_key
      ]
      password = onepassword_item.lxc_access.password
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr1"
    mac_address = "BC:24:11:D1:06:0F"
  }

  disk {
    datastore_id = "data-ssd"
    size         = 20
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_24_04_noble_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "ubuntu"
  }

  cpu {
    cores         = 4
    architecture  = "amd64"
  }

  memory {
    dedicated = 2048
    swap      = 0
  }

  startup {
    order      = "10"
    up_delay   = "60"
    down_delay = "60"
  }

  start_on_boot = true
  started       = true

  tags = ["automation", "ubuntu", "haproxy${count.index + 1}", "lxc", "container"]

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname haproxy${count.index + 1}.ddlns.net && sudo apt update && sudo apt install -y haproxy && sudo systemctl enable haproxy && sudo systemctl start haproxy"]

    connection {
      host        = "10.10.20.172"
      type        = "ssh"
      user        = "root"
      private_key = data.onepassword_item.ssh_key_new.private_key
    }
  }

}

resource "proxmox_virtual_environment_container" "proxy_container" {
  description = "Squid Proxy Container for content filtering"

  node_name = "rabbit-01-psp"
  vm_id     = 801

  unprivileged = true
  initialization {
    hostname = "squid.ddlns.net"

    ip_config {
      ipv4 {
        address = "10.10.40.100/24"
        gateway = "10.10.40.1"
      }
    }

    user_account {
      keys = [
        // Let's use 1Password here
        data.onepassword_item.ssh_key.public_key,
        data.onepassword_item.ssh_key_new.public_key
      ]
      password = onepassword_item.lxc_access.password
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr2"
    mac_address = "BC:24:11:E3:04:A9"
  }

  disk {
    datastore_id = "data-ssd"
    size         = 20
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_24_04_noble_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "ubuntu"
  }

  cpu {
    cores         = 2
    architecture  = "amd64"
  }

  memory {
    dedicated = 2048
    swap      = 0
  }

  startup {
    order      = "10"
    up_delay   = "60"
    down_delay = "60"
  }

  start_on_boot = false
  started       = false

  tags = ["automation", "ubuntu", "proxy", "lxc", "container"]

  ##provisioner "remote-exec" {
  ##  inline = ["sudo apt update && sudo apt install -y squid-common squid-openssl squid-langpack squidclient && sudo systemctl enable squid && sudo systemctl start squid"]

  ##  ## # Ansible managed
  ##  ## acl localnet src 10.0.0.0/8	        # RFC1918 possible internal network
  ##  ## acl localnet src 172.16.0.0/12	    # RFC1918 possible internal network
  ##  ## acl localnet src 192.168.0.0/16	    # RFC1918 possible internal network
  ##  ## acl localnet src fc00::/7           # RFC 4193 local private network range
  ##  ## acl localnet src fe80::/10          # RFC 4291 link-local (directly plugged) machines
  ##  ## acl haproxy src 10.10.40.101/32
  ##  ## acl squidfabio src 34.237.130.166/32
  ##  ## acl SSL_ports port 443
  ##  ## acl SSL_ports port 6443           # Sysdig collector
  ##  ## acl Safe_ports port 80		        # http
  ##  ## acl Safe_ports port 21		        # ftp
  ##  ## acl Safe_ports port 443		        # https
  ##  ## acl Safe_ports port 6443		      # Sysdig collector
  ##  ## acl Safe_ports port 70		        # gopher
  ##  ## acl Safe_ports port 210		        # wais
  ##  ## acl Safe_ports port 1025-65535	  # unregistered ports
  ##  ## acl Safe_ports port 280		        # http-mgmt
  ##  ## acl Safe_ports port 488		        # gss-http
  ##  ## acl Safe_ports port 591		        # filemaker
  ##  ## acl Safe_ports port 777		        # multiling http
  ##  ## acl CONNECT method CONNECT
  ##  ##
  ##  ## # Blocks connection through direct IP Address
  ##  ## acl allowed_domain dstdomain .quay.io .redhat.io
  ##  ## #acl allowed_ingest dstdomain ingest-us2.app.sysdig.com us2.app.sysdig.com
  ##  ## acl allowed_ingest_eu dstdomain ingest-eu1.app.sysdig.com eu1.app.sysdig.com
  ##  ## acl allowed_ingest_us1 dstdomain collector.sysdigcloud.com secure.sysdig.com app.sysdigcloud.com
  ##  ## acl block_ip dst -n 0.0.0.0/0
  ##  ## http_access allow allowed_domain haproxy
  ##  ## #http_access allow allowed_ingest
  ##  ## http_access allow allowed_ingest_eu squidfabio
  ##  ## http_access allow allowed_ingest_us1
  ##  ## http_access deny block_ip
  ##  ##
  ##  ## http_access deny !Safe_ports
  ##  ## http_access deny CONNECT !SSL_ports
  ##  ## http_access allow localhost manager
  ##  ## http_access deny manager
  ##  ## #http_access allow localnet
  ##  ## http_access allow localhost
  ##  ## http_access deny all
  ##  ## include /etc/squid/conf.d/*
  ##  ## http_port 3128
  ##  ## https_port 3129 tls-cert=/etc/squid/certs/squid-ca-cert-key.pem
  ##  ## coredump_dir /var/spool/squid
  ##  ## refresh_pattern ^ftp:		1440	20%	10080
  ##  ## refresh_pattern ^gopher:	1440	0%	1440
  ##  ## refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
  ##  ## refresh_pattern .		0	20%	4320
  ##  ##
  ##  ## logformat custom %tl.%03tu %>a %Ss/%03>Hs %<st %rm %ru %[un %Sh/%<a %mt
  ##  ## access_log daemon:/var/log/squid/access.log custom

  ##  connection {
  ##    host        = proxmox_virtual_environment_container.proxy_container.initialization[0].ip_config[0].ipv4[0].address
  ##    type        = "ssh"
  ##    user        = "root"
  ##    private_key = data.onepassword_item.ssh_key_new.private_key
  ##  }
  ##}

}

resource "proxmox_virtual_environment_container" "satisfactory_container" {
  description = "Satisfactory Container"

  node_name = "rabbit-01-psp"
  vm_id     = 805

  unprivileged = true

  initialization {
    hostname = "satisfactory.ddlns.net"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [
        // Let's use 1Password here
        data.onepassword_item.ssh_key.public_key,
        data.onepassword_item.ssh_key_new.public_key
      ]
      password = onepassword_item.lxc_access.password
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr1"
  }

  disk {
    datastore_id = "data-ssd2"
    size         = 30
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_24_04_noble_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "ubuntu"
  }

  cpu {
    cores         = 4
    architecture  = "amd64"
  }

  memory {
    dedicated = 12288
    swap      = 0
  }

  startup {
    order      = "10"
    up_delay   = "60"
    down_delay = "60"
  }

  start_on_boot = true
  started       = true

  tags = ["automation", "ubuntu", "satisfactory", "lxc", "container"]

  provisioner "remote-exec" {
    inline = ["apt update; DEBIAN_FRONTEND=noninteractive apt install software-properties-common -y; add-apt-repository multiverse -y; dpkg --add-architecture i386; apt update; echo steam steam/license note '' | debconf-set-selections; echo steam steam/question select \"I AGREE\" | debconf-set-selections; DEBIAN_FRONTEND=noninteractive apt install steamcmd -y; steamcmd +login anonymous +app_update 1690800 +quit"]

    connection {
      host        = values(self.ipv4)[0]
      type        = "ssh"
      user        = "root"
      private_key = data.onepassword_item.ssh_key_new.private_key
    }
  }

}

resource "proxmox_virtual_environment_container" "satisfactory_shared_container" {
  description = "Satisfactory shared Container"

  node_name = "rabbit-01-psp"
  vm_id     = 806

  unprivileged = true

  initialization {
    hostname = "satisfactory-shared.ddlns.net"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [
        // Let's use 1Password here
        data.onepassword_item.ssh_key.public_key,
        data.onepassword_item.ssh_key_new.public_key
      ]
      password = onepassword_item.lxc_access.password
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr1"
  }

  disk {
    datastore_id = "data-ssd2"
    size         = 30
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_24_04_noble_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "ubuntu"
  }

  cpu {
    cores         = 4
    architecture  = "amd64"
  }

  memory {
    dedicated = 12288
    swap      = 0
  }

  startup {
    order      = "10"
    up_delay   = "60"
    down_delay = "60"
  }

  start_on_boot = true
  started       = true

  tags = ["automation", "ubuntu", "satisfactory", "lxc", "container"]

  provisioner "remote-exec" {
    inline = ["apt update; DEBIAN_FRONTEND=noninteractive apt install software-properties-common -y; add-apt-repository multiverse -y; dpkg --add-architecture i386; apt update; echo steam steam/license note '' | debconf-set-selections; echo steam steam/question select \"I AGREE\" | debconf-set-selections; DEBIAN_FRONTEND=noninteractive apt install steamcmd -y; steamcmd +login anonymous +app_update 1690800 +quit"]

    connection {
      host        = values(self.ipv4)[0]
      type        = "ssh"
      user        = "root"
      private_key = data.onepassword_item.ssh_key_new.private_key
    }
  }

}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_24_04_noble_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"
  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_04_jammy_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "rabbit-01-psp"
  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

output "lxc_container_password" {
  value     = onepassword_item.lxc_access.password
  sensitive = true
}

output "satisfactory_container_ip" {
  value = proxmox_virtual_environment_container.satisfactory_container.ipv4["eth0"]
}

output "satisfactory_shared_container_ip" {
  value = proxmox_virtual_environment_container.satisfactory_shared_container.ipv4["eth0"]
}

#resource "proxmox_virtual_environment_container" "rtmp_container" {
#  description = "NGINX RTMP Container for streaming"
#
#  node_name = "rabbit-01-psp"
#  vm_id     = 803
#
#  initialization {
#    hostname = "rtmp${count.index + 1}.ddlns.net"
#
#    ip_config {
#      ipv4 {
#        address = "dhcp"
#      }
#    }
#
#    user_account {
#      keys = [
#        // Let's use 1Password here
#        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh)
#      ]
#      password = random_password.ubuntu_container_password.result
#    }
#  }
#
#  network_interface {
#    name = "eth0"
#  }
#
#  disk {
#    datastore_id = "data-ssd"
#    size         = 30
#  }
#
#  operating_system {
#    template_file_id = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_lxc_img.id
#    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
#    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
#    type             = "ubuntu"
#  }
#
#  startup {
#    order      = "10"
#    up_delay   = "60"
#    down_delay = "60"
#  }
#
#  start_on_boot = false
#
#  tags = ["automation", "ubuntu", "rtmp${count.index + 1}", "lxc", "container"]
#}
