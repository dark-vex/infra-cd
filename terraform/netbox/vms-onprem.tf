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
}

resource "netbox_interface" "rabbit_seaweedfs_lxc_eth0" {
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
  name               = "eth0"
}
