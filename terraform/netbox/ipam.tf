# ── Prefixes ──────────────────────────────────────────────────────────────────
# All CIDR values are stored encrypted in secrets.sops.yaml and accessed
# via local.ips.prefixes.* — no plaintext IPs in this file.

# Bio Rack (ddlns-lgu) — vmbr0=WAN, vmbr1=LAN, vmbr2=DMZ,
#                          vmbr3=MGMT, vmbr4=LAN-Testing, vmbr5=DMZ-Testing

resource "netbox_prefix" "biorack_wan" {
  prefix  = local.ips.prefixes.biorack.wan
  status  = "active"
  site_id = netbox_site.lgu.id
}

resource "netbox_prefix" "biorack_lan" {
  prefix  = local.ips.prefixes.biorack.lan
  status  = "active"
  site_id = netbox_site.lgu.id
}

resource "netbox_prefix" "biorack_dmz" {
  prefix  = local.ips.prefixes.biorack.dmz
  status  = "active"
  site_id = netbox_site.lgu.id
}

resource "netbox_prefix" "biorack_mgmt" {
  prefix  = local.ips.prefixes.biorack.mgmt
  status  = "active"
  site_id = netbox_site.lgu.id
}

resource "netbox_prefix" "biorack_lan_testing" {
  prefix  = local.ips.prefixes.biorack.lan_testing
  status  = "active"
  site_id = netbox_site.lgu.id
}

resource "netbox_prefix" "biorack_dmz_testing" {
  prefix  = local.ips.prefixes.biorack.dmz_testing
  status  = "active"
  site_id = netbox_site.lgu.id
}

# Bergamo (ddlns-bgy) — eno1=Public, eno2=Mgmt, vmbr0=VMs-WAN,
#                         vmbr1=LAN, vmbr2=DMZ, vmbr3=Sophos-Mgmt,
#                         vmbr4=LAN-Testing, vmbr5=DMZ-Testing

resource "netbox_prefix" "bergamo_public" {
  prefix  = local.ips.prefixes.bergamo.public
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_vms_wan" {
  prefix  = local.ips.prefixes.bergamo.vms_wan
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_mgmt" {
  prefix  = local.ips.prefixes.bergamo.mgmt
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_lan" {
  prefix  = local.ips.prefixes.bergamo.lan
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_dmz" {
  prefix  = local.ips.prefixes.bergamo.dmz
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_sophos_mgmt" {
  prefix  = local.ips.prefixes.bergamo.sophos_mgmt
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_lan_testing" {
  prefix  = local.ips.prefixes.bergamo.lan_testing
  status  = "active"
  site_id = netbox_site.bgy.id
}

resource "netbox_prefix" "bergamo_dmz_testing" {
  prefix  = local.ips.prefixes.bergamo.dmz_testing
  status  = "active"
  site_id = netbox_site.bgy.id
}

# ── IP Addresses ──────────────────────────────────────────────────────────────
# All values sourced from local.ips.devices.* (SOPS-encrypted).

# gozzi-01-lug: vmbr0 (WAN), vmbr1 (LAN), vmbr3 (MGMT)

resource "netbox_ip_address" "gozzi_01_lug_vmbr0" {
  ip_address   = local.ips.devices.gozzi_01_lug.vmbr0
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.gozzi_01_lug_vmbr0.id
}

resource "netbox_ip_address" "gozzi_01_lug_vmbr1" {
  ip_address   = local.ips.devices.gozzi_01_lug.vmbr1
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.gozzi_01_lug_vmbr1.id
}

resource "netbox_ip_address" "gozzi_01_lug_vmbr3" {
  ip_address   = local.ips.devices.gozzi_01_lug.vmbr3
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.gozzi_01_lug_vmbr3.id
}

# hpelvisor: vmbr0 (WAN), vmbr3 (MGMT)

resource "netbox_ip_address" "hpelvisor_vmbr0" {
  ip_address   = local.ips.devices.hpelvisor.vmbr0
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.hpelvisor_vmbr0.id
}

resource "netbox_ip_address" "hpelvisor_vmbr3" {
  ip_address   = local.ips.devices.hpelvisor.vmbr3
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.hpelvisor_vmbr3.id
}

# rabbit-01-psp: eno1 (Public), eno2 (Mgmt)

resource "netbox_ip_address" "rabbit_01_psp_eno1" {
  ip_address   = local.ips.devices.rabbit_01_psp.eno1
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.rabbit_01_psp_eno1.id
}

resource "netbox_ip_address" "rabbit_01_psp_eno2" {
  ip_address   = local.ips.devices.rabbit_01_psp.eno2
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.rabbit_01_psp_eno2.id
}

# sophos-xg-lug: port_1 (WAN), port_2 (LAN), port_3 (DMZ),
#                 port_4 (LAN-Testing), port_5 (DMZ-Testing)

resource "netbox_ip_address" "sophos_xg_lug_port_1" {
  ip_address   = local.ips.devices.sophos_xg_lug.port_1
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_lug_port_1.id
}

resource "netbox_ip_address" "sophos_xg_lug_port_2" {
  ip_address   = local.ips.devices.sophos_xg_lug.port_2
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_lug_port_2.id
}

resource "netbox_ip_address" "sophos_xg_lug_port_3" {
  ip_address   = local.ips.devices.sophos_xg_lug.port_3
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_lug_port_3.id
}

resource "netbox_ip_address" "sophos_xg_lug_port_4" {
  ip_address   = local.ips.devices.sophos_xg_lug.port_4
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_lug_port_4.id
}

resource "netbox_ip_address" "sophos_xg_lug_port_5" {
  ip_address   = local.ips.devices.sophos_xg_lug.port_5
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_lug_port_5.id
}

# sophos-xg-bgy: port_a (VMs-WAN), port_b (LAN), port_c (DMZ),
#                 port_d (Sophos-Mgmt), port_e (LAN-Testing), port_f (DMZ-Testing)

resource "netbox_ip_address" "sophos_xg_bgy_port_a" {
  ip_address   = local.ips.devices.sophos_xg_bgy.port_a
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_bgy_port_a.id
}

resource "netbox_ip_address" "sophos_xg_bgy_port_b" {
  ip_address   = local.ips.devices.sophos_xg_bgy.port_b
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_bgy_port_b.id
}

resource "netbox_ip_address" "sophos_xg_bgy_port_c" {
  ip_address   = local.ips.devices.sophos_xg_bgy.port_c
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_bgy_port_c.id
}

resource "netbox_ip_address" "sophos_xg_bgy_port_d" {
  ip_address   = local.ips.devices.sophos_xg_bgy.port_d
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_bgy_port_d.id
}

resource "netbox_ip_address" "sophos_xg_bgy_port_e" {
  ip_address   = local.ips.devices.sophos_xg_bgy.port_e
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_bgy_port_e.id
}

resource "netbox_ip_address" "sophos_xg_bgy_port_f" {
  ip_address   = local.ips.devices.sophos_xg_bgy.port_f
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.sophos_xg_bgy_port_f.id
}

# ── Bergamo VM/LXC static IP addresses (rabbit-01-psp) ───────────────────────
# Values sourced from local.ips.vms.* (SOPS-encrypted).

resource "netbox_ip_address" "rabbit_runner_vm" {
  ip_address   = local.ips.vms.runner
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_runner_vm_eth0.id
}

resource "netbox_ip_address" "rabbit_kubenuc_m3" {
  ip_address   = local.ips.vms.kubenuc_m3
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_kubenuc_m3_eth0.id
}

resource "netbox_ip_address" "rabbit_kubenuc_w3" {
  ip_address   = local.ips.vms.kubenuc_w3
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_kubenuc_w3_eth0.id
}

resource "netbox_ip_address" "rabbit_kubenuc_w4" {
  ip_address   = local.ips.vms.kubenuc_w4
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_kubenuc_w4_eth0.id
}

resource "netbox_ip_address" "rabbit_kubenuc_m4" {
  ip_address   = local.ips.vms.kubenuc_m4
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_kubenuc_m4_eth0.id
}

resource "netbox_ip_address" "rabbit_haproxy1" {
  ip_address   = local.ips.vms.haproxy1
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_haproxy1_lxc_eth0.id
}

resource "netbox_ip_address" "rabbit_graylog" {
  ip_address   = local.ips.vms.graylog
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_graylog_lxc_eth0.id
}

resource "netbox_ip_address" "rabbit_pbs_01_psp" {
  ip_address   = local.ips.vms.pbs_01_psp
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_pbs_01_psp_lxc_eth0.id
}

resource "netbox_ip_address" "rabbit_squid_lxc" {
  ip_address   = local.ips.vms.squid_lxc
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_squid_lxc_eth0.id
}

# ── Bio Rack VM/LXC static IP addresses ──────────────────────────────────────

resource "netbox_ip_address" "gozzi_kubenuc_m2" {
  ip_address   = local.ips.vms.kubenuc_m2
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_kubenuc_m2_eth0.id
}

resource "netbox_ip_address" "hpelvisor_gitlab" {
  ip_address   = local.ips.vms.gitlab
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_gitlab_lxc_eth0.id
}
