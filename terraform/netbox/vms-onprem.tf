# ── Bergamo VMs — rabbit-01-psp cluster ──────────────────────────────────────
# All 14 QEMU VMs managed in terraform/proxmox/rabbit/vm.tf

resource "netbox_virtual_machine" "rabbit_web1" {
  name         = "web1.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 4
  memory_mb    = 4096
  disk_size_mb = 112640
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_web1_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_web1.id
  name               = "eth0"
  mac_address        = "DA:23:0C:C5:9E:B5"
}

resource "netbox_virtual_machine" "rabbit_rtmp1_vm" {
  name         = "rtmp1.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 8
  memory_mb    = 8192
  disk_size_mb = 30720
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_rtmp1_vm_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_rtmp1_vm.id
  name               = "eth0"
  mac_address        = "62:F1:59:86:4E:CC"
}

resource "netbox_virtual_machine" "rabbit_kubenuc_w4" {
  name         = "kubenuc-w4"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 16384
  disk_size_mb = 542720
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_kubenuc_w4_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_w4.id
  name               = "eth0"
  mac_address        = "BC:24:11:48:EC:DA"
}

resource "netbox_virtual_machine" "rabbit_debian_desktop" {
  name         = "DebianDesktop"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.debian.id
  status       = "offline"
  vcpus        = 2
  memory_mb    = 4096
  disk_size_mb = 32768
  tags         = [netbox_tag.tf_managed.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_debian_desktop_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_debian_desktop.id
  name               = "eth0"
  mac_address        = "52:52:89:53:D8:82"
}

resource "netbox_virtual_machine" "rabbit_3cx" {
  name         = "3cx"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 4096
  disk_size_mb = 40960
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_3cx_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_3cx.id
  name               = "eth0"
  mac_address        = "12:13:D7:17:29:47"
}

resource "netbox_virtual_machine" "rabbit_squid_vm" {
  name         = "squid.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 2048
  disk_size_mb = 32768
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_squid_vm_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_squid_vm.id
  name               = "eth0"
  mac_address        = "02:F9:1D:B5:04:81"
}

resource "netbox_virtual_machine" "rabbit_kubenuc_m4" {
  name         = "kubenuc-m4"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 6144
  disk_size_mb = 20480
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_kubenuc_m4_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_m4.id
  name               = "eth0"
  mac_address        = "BC:24:11:68:17:AE"
}

resource "netbox_virtual_machine" "rabbit_mail2_bioadventures" {
  name         = "mail2.bioadventures.eu"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 6140
  disk_size_mb = 143360
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_mail2_bioadventures_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_mail2_bioadventures.id
  name               = "eth0"
  mac_address        = "52:54:00:A9:D5:FE"
}

# SophosXG VM — 6 NICs across all bridges
resource "netbox_virtual_machine" "rabbit_sophosxg_vm" {
  name         = "SophosXG"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 6144
  disk_size_mb = 98304
  tags         = [netbox_tag.tf_managed.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_sophosxg_net0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_sophosxg_vm.id
  name               = "net0"
  mac_address        = "96:12:B3:18:B2:5F"
}

resource "netbox_interface" "rabbit_sophosxg_net1" {
  virtual_machine_id = netbox_virtual_machine.rabbit_sophosxg_vm.id
  name               = "net1"
  mac_address        = "2E:EF:18:82:EE:E7"
}

resource "netbox_interface" "rabbit_sophosxg_net2" {
  virtual_machine_id = netbox_virtual_machine.rabbit_sophosxg_vm.id
  name               = "net2"
  mac_address        = "7A:C6:CE:5B:72:A9"
}

resource "netbox_interface" "rabbit_sophosxg_net3" {
  virtual_machine_id = netbox_virtual_machine.rabbit_sophosxg_vm.id
  name               = "net3"
  mac_address        = "7E:17:FD:9A:6B:6B"
}

resource "netbox_interface" "rabbit_sophosxg_net4" {
  virtual_machine_id = netbox_virtual_machine.rabbit_sophosxg_vm.id
  name               = "net4"
  mac_address        = "3A:92:BC:01:6B:FB"
}

resource "netbox_interface" "rabbit_sophosxg_net5" {
  virtual_machine_id = netbox_virtual_machine.rabbit_sophosxg_vm.id
  name               = "net5"
  mac_address        = "76:04:05:C4:F0:C7"
}

resource "netbox_virtual_machine" "rabbit_docker_vm" {
  name         = "docker"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "offline"
  vcpus        = 4
  memory_mb    = 8192
  disk_size_mb = 43008
  tags         = [netbox_tag.tf_managed.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_docker_vm_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_docker_vm.id
  name               = "eth0"
  mac_address        = "9A:B3:A9:E3:51:66"
}

resource "netbox_virtual_machine" "rabbit_runner_vm" {
  name         = "runner"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 12
  memory_mb    = 12288
  disk_size_mb = 153600
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_runner_vm_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_runner_vm.id
  name               = "eth0"
  mac_address        = "86:23:03:E6:DA:18"
}

resource "netbox_virtual_machine" "rabbit_k3s_vm" {
  name         = "k3s"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 16192
  disk_size_mb = 32768
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_k3s_vm_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_k3s_vm.id
  name               = "eth0"
  mac_address        = "4A:9C:4A:6C:50:93"
}

resource "netbox_virtual_machine" "rabbit_kubenuc_m3" {
  name         = "kubenuc-m3"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 6144
  disk_size_mb = 20480
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_kubenuc_m3_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_m3.id
  name               = "eth0"
  mac_address        = "BC:24:11:6B:E5:76"
}

resource "netbox_virtual_machine" "rabbit_kubenuc_w3" {
  name         = "kubenuc-w3"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 16384
  disk_size_mb = 542720
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_kubenuc_w3_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_w3.id
  name               = "eth0"
  mac_address        = "BC:24:11:25:10:EA"
}

# ── Bergamo LXCs — rabbit-01-psp cluster ─────────────────────────────────────
# 10 LXCs managed in terraform/proxmox/rabbit/{lxc,seaweedfs-lxc}.tf

resource "netbox_virtual_machine" "rabbit_satisfactory_shared_lxc" {
  name         = "satisfactory-shared.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 12288
  disk_size_mb = 30720
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_satisfactory_shared_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_satisfactory_shared_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:91:18:13"
}

resource "netbox_virtual_machine" "rabbit_haproxy1_lxc" {
  name         = "haproxy1.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 2048
  disk_size_mb = 20480
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_haproxy1_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_haproxy1_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:D1:06:0F"
}

# test-mail: IP collision with graylog (both claim 10.10.20.103/24).
# No IP assigned here until the user reassigns test-mail's IP in TF.
resource "netbox_virtual_machine" "rabbit_test_mail_lxc" {
  name         = "test-mail.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 2048
  disk_size_mb = 30720
  tags         = [netbox_tag.tf_managed.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_test_mail_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_test_mail_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:F4:F9:86"
}

resource "netbox_virtual_machine" "rabbit_satisfactory_lxc" {
  name         = "satisfactory.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 12288
  disk_size_mb = 30720
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_satisfactory_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_satisfactory_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:56:15:A6"
}

resource "netbox_virtual_machine" "rabbit_graylog_lxc" {
  name         = "graylog.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 16384
  disk_size_mb = 81920
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_graylog_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_graylog_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:41:A8:4A"
}

resource "netbox_virtual_machine" "rabbit_pbs_01_psp_lxc" {
  name         = "pbs-01-psp.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.debian.id
  status       = "offline"
  vcpus        = 4
  memory_mb    = 4096
  disk_size_mb = 30720
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_pbs_01_psp_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_pbs_01_psp_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:D1:13:50"
}

resource "netbox_virtual_machine" "rabbit_squid_lxc" {
  name         = "squid-lxc.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 2
  memory_mb    = 2048
  disk_size_mb = 20480
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_squid_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_squid_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:E3:04:A9"
}

resource "netbox_virtual_machine" "rabbit_rtmp1_lxc" {
  name         = "rtmp1-lxc.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 8
  memory_mb    = 8192
  disk_size_mb = 30720
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_rtmp1_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_rtmp1_lxc.id
  name               = "eth0"
}

resource "netbox_virtual_machine" "rabbit_mon_bgy_lxc" {
  name         = "mon-bgy.ddlns.net"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 1
  memory_mb    = 512
  disk_size_mb = 4096
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_mon_bgy_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_mon_bgy_lxc.id
  name               = "eth0"
}

resource "netbox_virtual_machine" "rabbit_seaweedfs_lxc" {
  name         = "seaweedfs-rabbit"
  cluster_id   = netbox_cluster.rabbit_01_psp.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 4096
  disk_size_mb = 102400
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.bgy.id
}

resource "netbox_interface" "rabbit_seaweedfs_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
  name               = "eth0"
}

# ── Bio Rack VMs — gozzi-pve cluster ─────────────────────────────────────────
# 4 VMs managed in terraform/proxmox/gozzi-hpelvisor/gozzi_pve-generated.tf

resource "netbox_virtual_machine" "gozzi_okd_singlenode" {
  name         = "okd-singlenode"
  cluster_id   = netbox_cluster.gozzi_pve.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 32768
  disk_size_mb = 153600
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "gozzi_okd_singlenode_eth0" {
  virtual_machine_id = netbox_virtual_machine.gozzi_okd_singlenode.id
  name               = "eth0"
  mac_address        = "BC:24:11:89:55:B1"
}

# 3cx.bioadventures.eu — dual-homed (vmbr1 + vmbr0)
resource "netbox_virtual_machine" "gozzi_3cx_bioadventures" {
  name         = "3cx.bioadventures.eu"
  cluster_id   = netbox_cluster.gozzi_pve.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 2048
  disk_size_mb = 20480
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "gozzi_3cx_bioadventures_net0" {
  virtual_machine_id = netbox_virtual_machine.gozzi_3cx_bioadventures.id
  name               = "net0"
  mac_address        = "52:54:00:7D:02:28"
}

resource "netbox_interface" "gozzi_3cx_bioadventures_net1" {
  virtual_machine_id = netbox_virtual_machine.gozzi_3cx_bioadventures.id
  name               = "net1"
  mac_address        = "52:54:00:6A:DB:10"
}

resource "netbox_virtual_machine" "gozzi_kubenuc_m2" {
  name         = "kubenuc-m2"
  cluster_id   = netbox_cluster.gozzi_pve.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 6144
  disk_size_mb = 20480
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "gozzi_kubenuc_m2_eth0" {
  virtual_machine_id = netbox_virtual_machine.gozzi_kubenuc_m2.id
  name               = "eth0"
  mac_address        = "BC:24:11:63:66:14"
}

# pve-backup — dual-homed (vmbr1 + vmbr3)
resource "netbox_virtual_machine" "gozzi_pve_backup" {
  name         = "pve-backup"
  cluster_id   = netbox_cluster.gozzi_pve.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 4096
  disk_size_mb = 1056768
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "gozzi_pve_backup_net0" {
  virtual_machine_id = netbox_virtual_machine.gozzi_pve_backup.id
  name               = "net0"
  mac_address        = "BC:24:11:E5:E0:94"
}

resource "netbox_interface" "gozzi_pve_backup_net1" {
  virtual_machine_id = netbox_virtual_machine.gozzi_pve_backup.id
  name               = "net1"
  mac_address        = "BC:24:11:F8:F5:CF"
}

# ── Bio Rack LXCs — gozzi-pve cluster ────────────────────────────────────────
# 1 LXC managed in terraform/proxmox/gozzi-hpelvisor/monitoring-lxc.tf

resource "netbox_virtual_machine" "gozzi_mon_lug_lxc" {
  name         = "mon-lug.ddlns.net"
  cluster_id   = netbox_cluster.gozzi_pve.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 1
  memory_mb    = 512
  disk_size_mb = 4096
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "gozzi_mon_lug_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.gozzi_mon_lug_lxc.id
  name               = "eth0"
}

# ── Bio Rack VMs — hpelvisor cluster ─────────────────────────────────────────
# 9 VMs managed in terraform/proxmox/gozzi-hpelvisor/hpelvisor-generated.tf

resource "netbox_virtual_machine" "hpelvisor_gen8_runner" {
  name         = "gen8-runner"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 16
  memory_mb    = 16400
  disk_size_mb = 141312
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_gen8_runner_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_gen8_runner.id
  name               = "eth0"
  mac_address        = "BC:24:11:D7:3C:0E"
}

resource "netbox_virtual_machine" "hpelvisor_sensor_debian12" {
  name         = "sensor-debian12"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 4096
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_sensor_debian12_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_sensor_debian12.id
  name               = "eth0"
  mac_address        = "BC:24:11:9F:83:9D"
}

resource "netbox_virtual_machine" "hpelvisor_pelican_game" {
  name         = "pelican-game"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 8192
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_pelican_game_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_pelican_game.id
  name               = "eth0"
  mac_address        = "BC:24:11:C2:B8:49"
}

resource "netbox_virtual_machine" "hpelvisor_prod_k3s_worker1" {
  name         = "prod-k3s-worker1"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 12288
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_prod_k3s_worker1_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_prod_k3s_worker1.id
  name               = "eth0"
  mac_address        = "52:54:00:5B:BF:E3"
}

resource "netbox_virtual_machine" "hpelvisor_openstack" {
  name         = "openstack"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 4
  memory_mb    = 16454
  disk_size_mb = 318464
  tags         = [netbox_tag.tf_managed.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_openstack_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_openstack.id
  name               = "eth0"
  mac_address        = "BC:24:11:00:09:6D"
}

resource "netbox_virtual_machine" "hpelvisor_openstack_snap" {
  name         = "openstack-snap"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "offline"
  vcpus        = 4
  memory_mb    = 16454
  disk_size_mb = 11264
  tags         = [netbox_tag.tf_managed.name, netbox_tag.ip_discovery_pending.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_openstack_snap_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_openstack_snap.id
  name               = "eth0"
  mac_address        = "BC:24:11:3F:AC:17"
}

resource "netbox_virtual_machine" "hpelvisor_sensor_ubuntu24" {
  name         = "sensor-ubuntu24"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 8192
  disk_size_mb = 44032
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_sensor_ubuntu24_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_sensor_ubuntu24.id
  name               = "eth0"
  mac_address        = "BC:24:11:6A:1D:97"
}

resource "netbox_virtual_machine" "hpelvisor_prod_k3s_master" {
  name         = "prod-k3s-master"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 6144
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_prod_k3s_master_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_prod_k3s_master.id
  name               = "eth0"
  mac_address        = "52:54:00:50:9E:8B"
}

resource "netbox_virtual_machine" "hpelvisor_amp_game" {
  name         = "amp-game"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 8192
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_amp_game_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_amp_game.id
  name               = "eth0"
  mac_address        = "BC:24:11:03:14:A1"
}

# ── Bio Rack LXCs — hpelvisor cluster ────────────────────────────────────────
# 3 LXCs: gitlab, dolibarr (hpelvisor-generated.tf) + seaweedfs (seaweedfs-lxc.tf)

resource "netbox_virtual_machine" "hpelvisor_gitlab_lxc" {
  name         = "gitlab.ddlns.net"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 8
  memory_mb    = 12288
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_gitlab_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_gitlab_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:CB:4F:4F"
}

resource "netbox_virtual_machine" "hpelvisor_dolibarr_test_lxc" {
  name         = "dolibarr.test.bioadventures.eu"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 2048
  disk_size_mb = 51200
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_dolibarr_test_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_dolibarr_test_lxc.id
  name               = "eth0"
  mac_address        = "BC:24:11:BE:28:FA"
}

resource "netbox_virtual_machine" "hpelvisor_seaweedfs_lxc" {
  name         = "seaweedfs-hpelvisor"
  cluster_id   = netbox_cluster.hpelvisor.id
  role_id      = netbox_device_role.container.id
  platform_id  = netbox_platform.ubuntu.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 4096
  disk_size_mb = 102400
  tags         = [netbox_tag.tf_managed.name, netbox_tag.dhcp.name]
  site_id      = netbox_site.lgu.id
}

resource "netbox_interface" "hpelvisor_seaweedfs_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.hpelvisor_seaweedfs_lxc.id
  name               = "eth0"
}

# ── MAC address objects — one per interface with an inline mac_address ─────────

resource "netbox_mac_address" "rabbit_web1_eth0" {
  mac_address                  = "DA:23:0C:C5:9E:B5"
  interface_id = netbox_interface.rabbit_web1_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_rtmp1_vm_eth0" {
  mac_address                  = "62:F1:59:86:4E:CC"
  interface_id = netbox_interface.rabbit_rtmp1_vm_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_kubenuc_w4_eth0" {
  mac_address                  = "BC:24:11:48:EC:DA"
  interface_id = netbox_interface.rabbit_kubenuc_w4_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_debian_desktop_eth0" {
  mac_address                  = "52:52:89:53:D8:82"
  interface_id = netbox_interface.rabbit_debian_desktop_eth0.id
  object_type                  = "virtualization.vminterface"

}

resource "netbox_mac_address" "rabbit_3cx_eth0" {
  mac_address                  = "12:13:D7:17:29:47"
  interface_id = netbox_interface.rabbit_3cx_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_squid_vm_eth0" {
  mac_address                  = "02:F9:1D:B5:04:81"
  interface_id = netbox_interface.rabbit_squid_vm_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_kubenuc_m4_eth0" {
  mac_address                  = "BC:24:11:68:17:AE"
  interface_id = netbox_interface.rabbit_kubenuc_m4_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_mail2_bioadventures_eth0" {
  mac_address                  = "52:54:00:A9:D5:FE"
  interface_id = netbox_interface.rabbit_mail2_bioadventures_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_sophosxg_net0" {
  mac_address                  = "96:12:B3:18:B2:5F"
  interface_id = netbox_interface.rabbit_sophosxg_net0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_sophosxg_net1" {
  mac_address                  = "2E:EF:18:82:EE:E7"
  interface_id = netbox_interface.rabbit_sophosxg_net1.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_sophosxg_net2" {
  mac_address                  = "7A:C6:CE:5B:72:A9"
  interface_id = netbox_interface.rabbit_sophosxg_net2.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_sophosxg_net3" {
  mac_address                  = "7E:17:FD:9A:6B:6B"
  interface_id = netbox_interface.rabbit_sophosxg_net3.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_sophosxg_net4" {
  mac_address                  = "3A:92:BC:01:6B:FB"
  interface_id = netbox_interface.rabbit_sophosxg_net4.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_sophosxg_net5" {
  mac_address                  = "76:04:05:C4:F0:C7"
  interface_id = netbox_interface.rabbit_sophosxg_net5.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_docker_vm_eth0" {
  mac_address                  = "9A:B3:A9:E3:51:66"
  interface_id = netbox_interface.rabbit_docker_vm_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_runner_vm_eth0" {
  mac_address                  = "86:23:03:E6:DA:18"
  interface_id = netbox_interface.rabbit_runner_vm_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_k3s_vm_eth0" {
  mac_address                  = "4A:9C:4A:6C:50:93"
  interface_id = netbox_interface.rabbit_k3s_vm_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_kubenuc_m3_eth0" {
  mac_address                  = "BC:24:11:6B:E5:76"
  interface_id = netbox_interface.rabbit_kubenuc_m3_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_kubenuc_w3_eth0" {
  mac_address                  = "BC:24:11:25:10:EA"
  interface_id = netbox_interface.rabbit_kubenuc_w3_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_satisfactory_shared_lxc_eth0" {
  mac_address                  = "BC:24:11:91:18:13"
  interface_id = netbox_interface.rabbit_satisfactory_shared_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_haproxy1_lxc_eth0" {
  mac_address                  = "BC:24:11:D1:06:0F"
  interface_id = netbox_interface.rabbit_haproxy1_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_test_mail_lxc_eth0" {
  mac_address                  = "BC:24:11:F4:F9:86"
  interface_id                 = netbox_interface.rabbit_test_mail_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_satisfactory_lxc_eth0" {
  mac_address                  = "BC:24:11:56:15:A6"
  interface_id = netbox_interface.rabbit_satisfactory_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_graylog_lxc_eth0" {
  mac_address                  = "BC:24:11:41:A8:4A"
  interface_id = netbox_interface.rabbit_graylog_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_pbs_01_psp_lxc_eth0" {
  mac_address                  = "BC:24:11:D1:13:50"
  interface_id = netbox_interface.rabbit_pbs_01_psp_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "rabbit_squid_lxc_eth0" {
  mac_address                  = "BC:24:11:E3:04:A9"
  interface_id = netbox_interface.rabbit_squid_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "gozzi_okd_singlenode_eth0" {
  mac_address                  = "BC:24:11:89:55:B1"
  interface_id = netbox_interface.gozzi_okd_singlenode_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "gozzi_3cx_bioadventures_net0" {
  mac_address                  = "52:54:00:7D:02:28"
  interface_id = netbox_interface.gozzi_3cx_bioadventures_net0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "gozzi_3cx_bioadventures_net1" {
  mac_address                  = "52:54:00:6A:DB:10"
  interface_id = netbox_interface.gozzi_3cx_bioadventures_net1.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "gozzi_kubenuc_m2_eth0" {
  mac_address                  = "BC:24:11:63:66:14"
  interface_id = netbox_interface.gozzi_kubenuc_m2_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "gozzi_pve_backup_net0" {
  mac_address                  = "BC:24:11:E5:E0:94"
  interface_id = netbox_interface.gozzi_pve_backup_net0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "gozzi_pve_backup_net1" {
  mac_address                  = "BC:24:11:F8:F5:CF"
  interface_id = netbox_interface.gozzi_pve_backup_net1.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_gen8_runner_eth0" {
  mac_address                  = "BC:24:11:D7:3C:0E"
  interface_id = netbox_interface.hpelvisor_gen8_runner_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_sensor_debian12_eth0" {
  mac_address                  = "BC:24:11:9F:83:9D"
  interface_id = netbox_interface.hpelvisor_sensor_debian12_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_pelican_game_eth0" {
  mac_address                  = "BC:24:11:C2:B8:49"
  interface_id = netbox_interface.hpelvisor_pelican_game_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_prod_k3s_worker1_eth0" {
  mac_address                  = "52:54:00:5B:BF:E3"
  interface_id = netbox_interface.hpelvisor_prod_k3s_worker1_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_openstack_eth0" {
  mac_address                  = "BC:24:11:00:09:6D"
  interface_id = netbox_interface.hpelvisor_openstack_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_openstack_snap_eth0" {
  mac_address                  = "BC:24:11:3F:AC:17"
  interface_id = netbox_interface.hpelvisor_openstack_snap_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_sensor_ubuntu24_eth0" {
  mac_address                  = "BC:24:11:6A:1D:97"
  interface_id = netbox_interface.hpelvisor_sensor_ubuntu24_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_prod_k3s_master_eth0" {
  mac_address                  = "52:54:00:50:9E:8B"
  interface_id = netbox_interface.hpelvisor_prod_k3s_master_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_amp_game_eth0" {
  mac_address                  = "BC:24:11:03:14:A1"
  interface_id = netbox_interface.hpelvisor_amp_game_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_gitlab_lxc_eth0" {
  mac_address                  = "BC:24:11:CB:4F:4F"
  interface_id = netbox_interface.hpelvisor_gitlab_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}

resource "netbox_mac_address" "hpelvisor_dolibarr_test_lxc_eth0" {
  mac_address                  = "BC:24:11:BE:28:FA"
  interface_id = netbox_interface.hpelvisor_dolibarr_test_lxc_eth0.id
  object_type                  = "virtualization.vminterface"
}
