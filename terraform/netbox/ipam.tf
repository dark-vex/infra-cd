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
  prefix      = local.ips.prefixes.bergamo.mgmt
  status      = "active"
  site_id     = netbox_site.bgy.id
  description = "Legacy home addressing kept by rabbit-01-psp. The same /24 is also in use on the MXP home LAN (dcknuc), see devices.tf."
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

resource "netbox_ip_address" "rabbit_k3s_mitm" {
  ip_address   = local.ips.vms.k3s_mitm_vm
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_k3s_mitm_eth0.id
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

resource "netbox_ip_address" "gozzi_kubenuc_w2" {
  ip_address   = local.ips.vms.kubenuc_w2
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_kubenuc_w2_eth0.id
}

resource "netbox_ip_address" "gozzi_dolibarr" {
  ip_address   = local.ips.vms.dolibarr
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_dolibarr_eth0.id
}

resource "netbox_ip_address" "gozzi_mail1" {
  ip_address   = local.ips.vms.mail1
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_mail1_eth0.id
}

resource "netbox_ip_address" "hpelvisor_gitlab" {
  ip_address   = local.ips.vms.gitlab
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_gitlab_lxc_eth0.id
}

# ── Static IPs for guests previously covered by the primary-ips.tf SCOPE GAP ─
# Values come from the repo owner's host inventory; the prod-k3s node IPs
# were additionally confirmed live (k8s-vms-daniele node hostIPs).

resource "netbox_ip_address" "gozzi_web1" {
  ip_address   = local.ips.vms.web1
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_web1_eth0.id
}

resource "netbox_ip_address" "gozzi_dckbio_1" {
  ip_address   = local.ips.vms.dckbio_1
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_dckbio_1_net0.id
}

resource "netbox_ip_address" "rabbit_mail2_bioadventures" {
  ip_address   = local.ips.vms.mail2_bioadventures
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_mail2_bioadventures_eth0.id
}

resource "netbox_ip_address" "hpelvisor_prod_k3s_master" {
  ip_address   = local.ips.vms.prod_k3s_master
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_prod_k3s_master_eth0.id
}

resource "netbox_ip_address" "hpelvisor_prod_k3s_worker1" {
  ip_address   = local.ips.vms.prod_k3s_worker1
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_prod_k3s_worker1_eth0.id
}

# ── Overlay (NetBird / Tailscale) addresses ──────────────────────────────────
# Never primary. dckbio-1 is the subnet router for both overlays towards the
# agentless LUG hosts; dcknuc is the MXP Docker host. rmon-vpn hosts the
# NetBird control plane; the Hetzner mail2 is a direct NetBird peer.

resource "netbox_ip_address" "dckbio_1_netbird" {
  ip_address   = local.ips.overlay.netbird.dckbio_1
  status       = "active"
  description  = "NetBird overlay (subnet router)"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_dckbio_1_wt0.id
}

resource "netbox_ip_address" "dckbio_1_tailscale" {
  ip_address   = local.ips.overlay.tailscale.dckbio_1
  status       = "active"
  description  = "Tailscale overlay (subnet router)"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_dckbio_1_tailscale0.id
}

resource "netbox_ip_address" "dcknuc_netbird" {
  ip_address   = local.ips.overlay.netbird.dcknuc
  status       = "active"
  description  = "NetBird overlay"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.dcknuc_wt0.id
}

resource "netbox_ip_address" "dcknuc_tailscale" {
  ip_address   = local.ips.overlay.tailscale.dcknuc
  status       = "active"
  description  = "Tailscale overlay"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.dcknuc_tailscale0.id
}

resource "netbox_ip_address" "rmon_vpn_netbird" {
  ip_address   = local.ips.overlay.netbird.rmon_vpn
  status       = "active"
  description  = "NetBird overlay (control plane host)"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hostbrr_rmon_vpn_wt0.id
}

resource "netbox_ip_address" "mail2_hetzner_netbird" {
  ip_address   = local.ips.overlay.netbird.mail2_hetzner
  status       = "active"
  description  = "NetBird overlay"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.mail2_wt0.id
}

# ── CODE-91: running guests with confirmed addresses ─────────────────────────
# satisfactory / satisfactory-shared were read live from their containers.
# The VMs' addresses were confirmed by the repo owner on the hosts.
# Dual-homed 3cx (LUG) and pve-backup use net0 (vmbr1, the LAN bridge).

resource "netbox_ip_address" "rabbit_satisfactory_lxc" {
  ip_address   = local.ips.vms.satisfactory_lxc
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_satisfactory_lxc_eth0.id
}

resource "netbox_ip_address" "rabbit_satisfactory_shared_lxc" {
  ip_address   = local.ips.vms.satisfactory_shared_lxc
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_satisfactory_shared_lxc_eth0.id
}

resource "netbox_ip_address" "rabbit_3cx" {
  ip_address   = local.ips.vms["3cx"]
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_3cx_eth0.id
}

resource "netbox_ip_address" "rabbit_k3s_vm" {
  ip_address   = local.ips.vms.k3s_vm
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_k3s_vm_eth0.id
}

resource "netbox_ip_address" "gozzi_okd_singlenode" {
  ip_address   = local.ips.vms.okd_singlenode
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_okd_singlenode_eth0.id
}

resource "netbox_ip_address" "gozzi_3cx_bioadventures" {
  ip_address   = local.ips.vms["3cx_bioadventures"]
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_3cx_bioadventures_net0.id
}

resource "netbox_ip_address" "gozzi_pve_backup" {
  ip_address   = local.ips.vms.pve_backup
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_pve_backup_net0.id
}

resource "netbox_ip_address" "hpelvisor_gen8_runner" {
  ip_address   = local.ips.vms.gen8_runner
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_gen8_runner_eth0.id
}

# ── CODE-91: stopped guests and test-mail ────────────────────────────────────
# web1 (BGY), rtmp1, mon-lug and dolibarr-test are stopped: their addresses are
# the stored discovery values, recorded at the repo owner's request and not
# verifiable live. test-mail's address was supplied by the repo owner (its
# container reports no IPv4 on eth0).

resource "netbox_ip_address" "rabbit_web1" {
  ip_address   = local.ips.vms.web1_vm
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_web1_eth0.id
}

resource "netbox_ip_address" "rabbit_rtmp1_lxc" {
  ip_address   = local.ips.vms.rtmp1_lxc
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_rtmp1_lxc_eth0.id
}

resource "netbox_ip_address" "gozzi_mon_lug_lxc" {
  ip_address   = local.ips.vms.mon_lug_lxc
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.gozzi_mon_lug_lxc_eth0.id
}

resource "netbox_ip_address" "hpelvisor_dolibarr_test_lxc" {
  ip_address   = local.ips.vms.dolibarr_test
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_dolibarr_test_lxc_eth0.id
}

resource "netbox_ip_address" "rabbit_test_mail_lxc" {
  ip_address   = local.ips.vms.test_mail
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_test_mail_lxc_eth0.id
}

# ── dcknuc (MXP) ─────────────────────────────────────────────────────────────

resource "netbox_ip_address" "dcknuc_eth0" {
  ip_address   = local.ips.devices.dcknuc.eth0
  status       = "active"
  object_type  = "dcim.interface"
  interface_id = netbox_device_interface.dcknuc_eth0.id
}

# ── SeaweedFS — closes part of the primary-ips.tf SCOPE GAP ─────────────────
# Real IPs sourced from ansible/seaweedfs/inventory.yml, not guessed.

resource "netbox_ip_address" "rabbit_seaweedfs_lxc_eth0" {
  ip_address   = local.ips.vms.seaweedfs_rabbit_lxc
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.rabbit_seaweedfs_lxc_eth0.id
}

resource "netbox_ip_address" "hpelvisor_seaweedfs_lxc_eth0" {
  ip_address   = local.ips.vms.seaweedfs_hpelvisor
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = netbox_interface.hpelvisor_seaweedfs_lxc_eth0.id
}
