# netbox_primary_ip — wires each VM/LXC's already-registered netbox_ip_address
# as its NetBox-displayed primary IPv4, so the netbox.netbox Ansible dynamic
# inventory plugin can populate ansible_host from NetBox.
#
# Provider note (e-breuninger/netbox 5.3.0): netbox_virtual_machine has no
# writable primary_ip4 attribute (primary_ipv4/primary_ipv6 are read-only,
# computed values) — netbox_primary_ip is the correct, separate resource for
# this, referencing an existing netbox_ip_address + netbox_virtual_machine by
# id. No circular dependency: this resource only ever points at two
# already-created resources, it isn't itself referenced back by either.
#
# SCOPE GAP: this only covers the 11 VMs/LXCs below, which already have a
# netbox_ip_address resource in ipam.tf. It intentionally does NOT cover the
# ~22 DHCP-networked, ip-discovery-pending-tagged guests that
# scripts/netbox-proxmox-ip-discover.py targets (web1_vm, rtmp1_vm, 3cx,
# squid_vm, mail2_bioadventures, k3s_vm, satisfactory_*, rtmp1_lxc,
# mon_bgy_lxc, seaweedfs_rabbit_lxc, okd_singlenode, 3cx_bioadventures,
# pve_backup, mon_lug_lxc, gen8_runner, pelican_game, prod_k3s_worker1,
# prod_k3s_master, amp_game, dolibarr_test, seaweedfs_hpelvisor) — none of
# those have a netbox_ip_address resource yet, sops-encrypted value or not.
# Adding one for each (plus its netbox_primary_ip) is real, mechanical,
# per-guest Terraform work that needs a `terraform plan` against live
# NetBox to verify (interface_id references, correct object_type, etc.) —
# do it as a follow-up PR, not blind from this file.

resource "netbox_primary_ip" "rabbit_runner_vm" {
  ip_address_id      = netbox_ip_address.rabbit_runner_vm.id
  virtual_machine_id = netbox_virtual_machine.rabbit_runner_vm.id
}

resource "netbox_primary_ip" "rabbit_kubenuc_m3" {
  ip_address_id      = netbox_ip_address.rabbit_kubenuc_m3.id
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_m3.id
}

resource "netbox_primary_ip" "rabbit_kubenuc_w3" {
  ip_address_id      = netbox_ip_address.rabbit_kubenuc_w3.id
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_w3.id
}

resource "netbox_primary_ip" "rabbit_kubenuc_w4" {
  ip_address_id      = netbox_ip_address.rabbit_kubenuc_w4.id
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_w4.id
}

resource "netbox_primary_ip" "rabbit_kubenuc_m4" {
  ip_address_id      = netbox_ip_address.rabbit_kubenuc_m4.id
  virtual_machine_id = netbox_virtual_machine.rabbit_kubenuc_m4.id
}

resource "netbox_primary_ip" "rabbit_haproxy1_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_haproxy1.id
  virtual_machine_id = netbox_virtual_machine.rabbit_haproxy1_lxc.id
}

resource "netbox_primary_ip" "rabbit_graylog_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_graylog.id
  virtual_machine_id = netbox_virtual_machine.rabbit_graylog_lxc.id
}

resource "netbox_primary_ip" "rabbit_pbs_01_psp_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_pbs_01_psp.id
  virtual_machine_id = netbox_virtual_machine.rabbit_pbs_01_psp_lxc.id
}

resource "netbox_primary_ip" "rabbit_squid_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_squid_lxc.id
  virtual_machine_id = netbox_virtual_machine.rabbit_squid_lxc.id
}

resource "netbox_primary_ip" "gozzi_kubenuc_m2" {
  ip_address_id      = netbox_ip_address.gozzi_kubenuc_m2.id
  virtual_machine_id = netbox_virtual_machine.gozzi_kubenuc_m2.id
}

resource "netbox_primary_ip" "gozzi_kubenuc_w2" {
  ip_address_id      = netbox_ip_address.gozzi_kubenuc_w2.id
  virtual_machine_id = netbox_virtual_machine.gozzi_kubenuc_w2.id
}

resource "netbox_primary_ip" "hpelvisor_gitlab_lxc" {
  ip_address_id      = netbox_ip_address.hpelvisor_gitlab.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_gitlab_lxc.id
}
