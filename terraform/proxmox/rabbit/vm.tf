module "rabbit_web1_ddlns_net_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "web1.ddlns.net"
  vmid        = 501
  node_name   = "rabbit-01-psp"
  description = "Web1 Server"

  cpu_cores = 4
  cpu_type  = "host"
  memory    = 4096
  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "virtio0"
      size         = 10
      ssd          = false
      discard      = "ignore"
    }

    data = {
      datastore_id = "data-ssd2"
      interface    = "virtio1"
      size         = 100
      ssd          = false
      discard      = "ignore"
    }
  }

  boot_order = ["virtio0"]

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "DA:23:0C:C5:9E:B5" }
  }

  ip_config = {
    ipv4_address = "dhcp"
  }

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  cloud_init_datastore_id = "data-ssd"
  cloud_init_file_id      = "local:snippets/ubuntu.cloud-config.yaml"

  started       = false
  start_on_boot = true

  tags = ["automation", "ubuntu", "web1"]
}

module "rabbit_rtmp1_ddlns_net_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "rtmp1.ddlns.net"
  vmid        = 601
  node_name   = "rabbit-01-psp"
  description = "rtmp1 Server"

  cpu_cores = 8
  cpu_type  = "host"
  memory    = 8192

  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "virtio0"
      size         = 30
      ssd          = false
      discard      = "ignore"
    }
  }

  boot_order = ["virtio0"]

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "62:F1:59:86:4E:CC" }
  }

  cloud_init_datastore_id = "local"
  cloud_init_file_id      = "local:snippets/ubuntu-rtmp.cloud-config.yaml"

  started       = false
  start_on_boot = true

  tags = ["automation", "rtmp1", "ubuntu"]
}

module "rabbit_kubenuc_w4_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "kubenuc-w4"
  vmid        = 4002
  node_name   = "rabbit-01-psp"
  description = "kubenuc-w4"

  cpu_cores   = 4
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 16384

  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "scsi0"
      size         = 500
      ssd          = true
      discard      = "ignore"
    }

    data = {
      datastore_id = "data-ssd"
      interface    = "scsi1"
      size         = 30
      ssd          = true
      discard      = "ignore"
    }
  }

  boot_order = ["scsi1"]

  network_devices = {
    net0 = { bridge = "vmbr2", mac_address = "BC:24:11:48:EC:DA" }
  }

  ip_config = {
    ipv4_address = "10.10.40.12/24"
    ipv4_gateway = "10.10.40.1"
  }

  cloud_init_datastore_id = "data-ssd"
  cloud_init_dns = {
    servers = ["10.10.40.1"]
  }
  cloud_init_user = "daniele"

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["automation", "vm", "kubernetes"]
}

module "rabbit_debiandesktop_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "DebianDesktop"
  vmid        = 101
  node_name   = "rabbit-01-psp"
  description = "Debian-Desktop"

  cpu_cores = 2
  cpu_type  = "host"
  memory    = 4096

  protection = true

  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "scsi0"
      size         = 32
      discard      = "ignore"
      ssd          = true
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "52:52:89:53:D8:82", firewall = false }
  }

  started       = false
  start_on_boot = false

  tags = ["automation", "debian-desktop", "vm"]
}

module "rabbit_r_3cx_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "3cx"
  vmid        = 105
  node_name   = "rabbit-01-psp"
  description = "3cx"

  cpu_cores = 2
  cpu_type  = "host"
  memory    = 4096

  cdrom = {
    file_id   = "none"
    interface = "ide2"
  }

  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "scsi0"
      size         = 40
      ssd          = false
      discard      = "ignore"
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "12:13:D7:17:29:47", firewall = false }
  }

  ip_config = {
    ipv4_address = "dhcp"
  }

  started       = true
  start_on_boot = true

  tags = ["vm", "automation", "pbx"]
}

module "rabbit_squid_ddlns_net_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "squid.ddlns.net"
  vmid        = 104
  node_name   = "rabbit-01-psp"
  description = "squid.ddlns.net"

  cpu_cores   = 1
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 2048

  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "scsi0"
      size         = 32
      ssd          = false
      discard      = "ignore"
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr2", mac_address = "02:F9:1D:B5:04:81" }
  }

  cloud_init_datastore_id = "local-zfs"
  cloud_init_user         = "daniele"

  started       = true
  start_on_boot = true

  tags = ["proxy"]
}

module "rabbit_kubenuc_m4_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "kubenuc-m4"
  vmid        = 4003
  node_name   = "rabbit-01-psp"
  description = "kubenuc-m4"

  cpu_cores = 2
  cpu_type  = "host"
  memory    = 6144

  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "scsi0"
      size         = 20
      discard      = "ignore"
      ssd          = false
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr2", mac_address = "BC:24:11:68:17:AE" }
  }

  ip_config = {
    ipv4_address = "10.10.40.13/24"
    ipv4_gateway = "10.10.40.1"
  }

  cloud_init_datastore_id = "data-ssd2"
  cloud_init_dns = {
    servers = ["10.10.40.1"]
  }
  cloud_init_user = "daniele"

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["automation", "vm"]
}

module "rabbit_mail2_bioadventures_eu_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "mail2.bioadventures.eu"
  vmid        = 1001
  node_name   = "rabbit-01-psp"
  description = "mail2.bioadventures.eu"

  bios_type = "ovmf"

  cpu_cores = 4
  cpu_type  = "host"
  memory    = 6140

  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "scsi0"
      size         = 20
      ssd          = false
      discard      = "ignore"
    }

    data = {
      datastore_id = "data-ssd2"
      interface    = "scsi1"
      size         = 120
      ssd          = false
      discard      = "ignore"
    }
  }

  efi_disk = {
    datastore_id      = "data-ssd2"
    file_format       = "raw"
    pre_enrolled_keys = true
    type              = "4m"
  }

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "52:54:00:a9:d5:fe", disconnected = true }
  }

  ip_config = {
    ipv4_address = "dhcp"
  }

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["automation", "vm"]
}

module "rabbit_sophosxg_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "SophosXG"
  vmid        = 100
  node_name   = "rabbit-01-psp"
  description = "SophosXG"

  cpu_cores   = 2
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 6144

  agent_enabled = false
  protection    = true

  boot_order = ["virtio0"]
  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "virtio0"
      size         = 16
      ssd          = false
      discard      = "ignore"
    }

    data = {
      datastore_id = "data-ssd"
      interface    = "virtio1"
      size         = 80
      ssd          = false
      discard      = "ignore"
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr0", mac_address = "96:12:B3:18:B2:5F", firewall = true }
    net1 = { bridge = "vmbr1", mac_address = "2E:EF:18:82:EE:E7" }
    net2 = { bridge = "vmbr2", mac_address = "7A:C6:CE:5B:72:A9" }
    net3 = { bridge = "vmbr3", mac_address = "7E:17:FD:9A:6B:6B" }
    net4 = { bridge = "vmbr4", mac_address = "3A:92:BC:01:6B:FB" }
    net5 = { bridge = "vmbr5", mac_address = "76:04:05:C4:F0:C7" }
  }

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["firewall", "automation", "vm"]
}

module "rabbit_docker_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "docker"
  vmid        = 103
  node_name   = "rabbit-01-psp"
  description = "docker"

  cpu_cores   = 2
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 8192

  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "scsi0"
      size         = 42
      discard      = "ignore"
      ssd          = false
    }
  }

  #cloud_init_datastore_id = "local"

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "9A:B3:A9:E3:51:66" }
  }

  #ip_config = {
  #  ipv4_address = "dhcp"
  #}

  #ssh_keys = [
  #  local.ssh_public_key,
  #  local.ssh_public_key_new
  #]

  started       = false
  start_on_boot = true

  tags = ["automation", "vm"]
}

module "rabbit_runner_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "runner"
  vmid        = 5000
  node_name   = "rabbit-01-psp"
  description = "runner"

  cpu_cores   = 6
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 12288

  disks = {
    boot = {
      datastore_id = "data-ssd"
      interface    = "scsi0"
      size         = 150
      ssd          = false
      discard      = "ignore"
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "86:23:03:E6:DA:18" }
  }

  ip_config = {
    ipv4_address = "10.10.20.21/24"
    ipv4_gateway = "10.10.20.1"
  }

  cloud_init_dns = {
    servers = ["10.10.20.1"]
  }

  cloud_init_datastore_id = "data-ssd"
  cloud_init_user         = "daniele"

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["github"]
}

module "rabbit_k3s_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "k3s"
  vmid        = 102
  node_name   = "rabbit-01-psp"
  description = "k3s"

  cpu_cores   = 4
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 16192

  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "scsi0"
      size         = 32
      ssd          = false
      discard      = "ignore"
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr1", mac_address = "4A:9C:4A:6C:50:93" }
  }

  started       = true
  start_on_boot = false

  tags = ["automation", "vm", "kubernetes"]
}

module "rabbit_kubenuc_m3_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "kubenuc-m3"
  vmid        = 4000
  node_name   = "rabbit-01-psp"
  description = "kubenuc-m3"

  cpu_cores   = 1
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 6144

  protection = true

  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "scsi0"
      size         = 20
      discard      = "ignore"
      ssd          = true
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr2", mac_address = "BC:24:11:6B:E5:76" }
  }

  ip_config = {
    ipv4_gateway = "10.10.40.1"
    ipv4_address = "10.10.40.10/24"
  }

  cloud_init_dns = {
    servers = ["10.10.40.1"]
  }
  cloud_init_datastore_id = "data-ssd2"
  cloud_init_user         = "daniele"

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["automation", "vm", "kubernetes"]
}

module "rabbit_kubenuc_w3_vm" {
  source = "../../modules/proxmox-vm"
  providers = {
    proxmox = proxmox.rabbit
  }

  name        = "kubenuc-w3"
  vmid        = 4001
  node_name   = "rabbit-01-psp"
  description = "kubenuc-w3"

  cpu_cores   = 4
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 16384

  disks = {
    boot = {
      datastore_id = "data-ssd2"
      interface    = "scsi0"
      size         = 30
      discard      = "ignore"
      ssd          = true
    }

    data = {
      datastore_id = "data-ssd2"
      interface    = "scsi3"
      size         = 500
      discard      = "ignore"
      ssd          = true
    }
  }

  network_devices = {
    net0 = { bridge = "vmbr2", mac_address = "BC:24:11:25:10:EA" }
  }

  ip_config = {
    ipv4_address = "10.10.40.11/24"
    ipv4_gateway = "10.10.40.1"
  }

  cloud_init_datastore_id = "data-ssd2"
  cloud_init_dns = {
    servers = ["10.10.40.1"]
  }
  cloud_init_user = "daniele"

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  started       = true
  start_on_boot = true

  tags = ["automation", "vm", "kubernetes"]
}
