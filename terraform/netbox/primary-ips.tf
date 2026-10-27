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
# SCOPE GAP: this only covers the VMs/LXCs below, which have a
# netbox_ip_address resource in ipam.tf. Guests with no primary IP on purpose
# or for lack of a known address: the stopped guests with no stored value
# (rtmp1 VM, openstack x2, the two desktops, docker, pbs-gen8/gen9, the two
# sensor VMs, hpelvisor-teleport), the multi-NIC SophosXG VM (the firewall
# device holds its ports and addresses), mon-mxp, and the cloud/public VPS
# records. Tracked in CODE-91.
#
# The LUG web1, dckbio-1, mail2_bioadventures, prod_k3s_master and
# prod_k3s_worker1 were closed out below with static values (the discovery
# script no longer targets mail2_bioadventures and the two prod_k3s nodes, so
# it cannot overwrite them).
#
# CODE-91 closed out the running guests: satisfactory, satisfactory-shared,
# 3cx (BGY), 3cx (LUG), k3s, okd-singlenode, pve-backup and gen8-runner.
# They are no longer targeted by the discovery script. The stopped guests
# (web1 BGY, rtmp1, mon-lug, dolibarr-test) and test-mail followed, and squid
# now has its address on the running VM (the LXC takes over later, see ipam.tf).
#
# seaweedfs_rabbit_lxc and seaweedfs_hpelvisor were closed out below —
# their real IPs were already sitting in local.ips.vms unused; sourced
# from ansible/seaweedfs/inventory.yml, not guessed.

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

resource "netbox_primary_ip" "rabbit_k3s_mitm" {
  ip_address_id      = netbox_ip_address.rabbit_k3s_mitm.id
  virtual_machine_id = netbox_virtual_machine.rabbit_k3s_mitm.id
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

# squid: the running VM (104) is canonical for now; the LXC (801) takes over
# later (see the note on netbox_ip_address.rabbit_squid_lxc in ipam.tf).
resource "netbox_primary_ip" "rabbit_squid_vm" {
  ip_address_id      = netbox_ip_address.rabbit_squid_lxc.id
  virtual_machine_id = netbox_virtual_machine.rabbit_squid_vm.id
}

resource "netbox_primary_ip" "gozzi_kubenuc_m2" {
  ip_address_id      = netbox_ip_address.gozzi_kubenuc_m2.id
  virtual_machine_id = netbox_virtual_machine.gozzi_kubenuc_m2.id
}

resource "netbox_primary_ip" "gozzi_kubenuc_w2" {
  ip_address_id      = netbox_ip_address.gozzi_kubenuc_w2.id
  virtual_machine_id = netbox_virtual_machine.gozzi_kubenuc_w2.id
}

resource "netbox_primary_ip" "gozzi_dolibarr" {
  ip_address_id      = netbox_ip_address.gozzi_dolibarr.id
  virtual_machine_id = netbox_virtual_machine.gozzi_dolibarr.id
}

resource "netbox_primary_ip" "gozzi_mail1" {
  ip_address_id      = netbox_ip_address.gozzi_mail1.id
  virtual_machine_id = netbox_virtual_machine.gozzi_mail1.id
}

resource "netbox_primary_ip" "hpelvisor_gitlab_lxc" {
  ip_address_id      = netbox_ip_address.hpelvisor_gitlab.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_gitlab_lxc.id
}

resource "netbox_primary_ip" "rabbit_seaweedfs_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_seaweedfs_lxc_eth0.id
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
}

resource "netbox_primary_ip" "hpelvisor_seaweedfs_lxc" {
  ip_address_id      = netbox_ip_address.hpelvisor_seaweedfs_lxc_eth0.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_seaweedfs_lxc.id
}

resource "netbox_primary_ip" "gozzi_web1" {
  ip_address_id      = netbox_ip_address.gozzi_web1.id
  virtual_machine_id = netbox_virtual_machine.gozzi_web1.id
}

resource "netbox_primary_ip" "gozzi_dckbio_1" {
  ip_address_id      = netbox_ip_address.gozzi_dckbio_1.id
  virtual_machine_id = netbox_virtual_machine.gozzi_dckbio_1.id
}

resource "netbox_primary_ip" "rabbit_mail2_bioadventures" {
  ip_address_id      = netbox_ip_address.rabbit_mail2_bioadventures.id
  virtual_machine_id = netbox_virtual_machine.rabbit_mail2_bioadventures.id
}

resource "netbox_primary_ip" "hpelvisor_prod_k3s_master" {
  ip_address_id      = netbox_ip_address.hpelvisor_prod_k3s_master.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_prod_k3s_master.id
}

resource "netbox_primary_ip" "hpelvisor_prod_k3s_worker1" {
  ip_address_id      = netbox_ip_address.hpelvisor_prod_k3s_worker1.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_prod_k3s_worker1.id
}

resource "netbox_primary_ip" "rabbit_satisfactory_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_satisfactory_lxc.id
  virtual_machine_id = netbox_virtual_machine.rabbit_satisfactory_lxc.id
}

resource "netbox_primary_ip" "rabbit_satisfactory_shared_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_satisfactory_shared_lxc.id
  virtual_machine_id = netbox_virtual_machine.rabbit_satisfactory_shared_lxc.id
}

resource "netbox_primary_ip" "rabbit_3cx" {
  ip_address_id      = netbox_ip_address.rabbit_3cx.id
  virtual_machine_id = netbox_virtual_machine.rabbit_3cx.id
}

resource "netbox_primary_ip" "rabbit_k3s_vm" {
  ip_address_id      = netbox_ip_address.rabbit_k3s_vm.id
  virtual_machine_id = netbox_virtual_machine.rabbit_k3s_vm.id
}

resource "netbox_primary_ip" "gozzi_okd_singlenode" {
  ip_address_id      = netbox_ip_address.gozzi_okd_singlenode.id
  virtual_machine_id = netbox_virtual_machine.gozzi_okd_singlenode.id
}

resource "netbox_primary_ip" "gozzi_3cx_bioadventures" {
  ip_address_id      = netbox_ip_address.gozzi_3cx_bioadventures.id
  virtual_machine_id = netbox_virtual_machine.gozzi_3cx_bioadventures.id
}

resource "netbox_primary_ip" "gozzi_pve_backup" {
  ip_address_id      = netbox_ip_address.gozzi_pve_backup.id
  virtual_machine_id = netbox_virtual_machine.gozzi_pve_backup.id
}

resource "netbox_primary_ip" "hpelvisor_gen8_runner" {
  ip_address_id      = netbox_ip_address.hpelvisor_gen8_runner.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_gen8_runner.id
}

resource "netbox_primary_ip" "rabbit_web1" {
  ip_address_id      = netbox_ip_address.rabbit_web1.id
  virtual_machine_id = netbox_virtual_machine.rabbit_web1.id
}

resource "netbox_primary_ip" "rabbit_rtmp1_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_rtmp1_lxc.id
  virtual_machine_id = netbox_virtual_machine.rabbit_rtmp1_lxc.id
}

resource "netbox_primary_ip" "gozzi_mon_lug_lxc" {
  ip_address_id      = netbox_ip_address.gozzi_mon_lug_lxc.id
  virtual_machine_id = netbox_virtual_machine.gozzi_mon_lug_lxc.id
}

resource "netbox_primary_ip" "hpelvisor_dolibarr_test_lxc" {
  ip_address_id      = netbox_ip_address.hpelvisor_dolibarr_test_lxc.id
  virtual_machine_id = netbox_virtual_machine.hpelvisor_dolibarr_test_lxc.id
}

resource "netbox_primary_ip" "rabbit_test_mail_lxc" {
  ip_address_id      = netbox_ip_address.rabbit_test_mail_lxc.id
  virtual_machine_id = netbox_virtual_machine.rabbit_test_mail_lxc.id
}

# dcknuc is a dcim.device, not a VM — netbox_device_primary_ip is the
# separate provider resource for that (netbox_primary_ip only takes
# virtual_machine_id, no device_id).
resource "netbox_device_primary_ip" "dcknuc" {
  ip_address_id = netbox_ip_address.dcknuc_eth0.id
  device_id     = netbox_device.dcknuc.id
}
