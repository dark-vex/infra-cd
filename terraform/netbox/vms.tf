# ── Cluster Types ────────────────────────────────────────────────────────────

resource "netbox_cluster_type" "hetzner_cloud" {
  name = "Hetzner Cloud"
  slug = "hetzner-cloud"
}

resource "netbox_cluster_type" "proxmox_ve" {
  name = "Proxmox VE"
  slug = "proxmox-ve"
}

resource "netbox_cluster_type" "oci" {
  name = "Oracle Cloud Infrastructure"
  slug = "oci"
}

# ── Clusters (one per provider + region) ─────────────────────────────────────

resource "netbox_cluster" "gozzi_pve" {
  name            = "gozzi-pve"
  cluster_type_id = netbox_cluster_type.proxmox_ve.id
  site_id         = netbox_site.lgu.id
}

resource "netbox_cluster" "hpelvisor" {
  name            = "hpelvisor"
  cluster_type_id = netbox_cluster_type.proxmox_ve.id
  site_id         = netbox_site.lgu.id
}

resource "netbox_cluster" "rabbit_01_psp" {
  name            = "rabbit-01-psp"
  cluster_type_id = netbox_cluster_type.proxmox_ve.id
  site_id         = netbox_site.bgy.id
}

resource "netbox_cluster" "hetzner_nbg" {
  name            = "hetzner-nbg"
  cluster_type_id = netbox_cluster_type.hetzner_cloud.id
  site_id         = netbox_site.nbg.id
}

resource "netbox_cluster" "hetzner_zrh" {
  name            = "hetzner-zrh"
  cluster_type_id = netbox_cluster_type.hetzner_cloud.id
  site_id         = netbox_site.zrh.id
}

resource "netbox_cluster" "hetzner_nl" {
  name            = "hetzner-nl"
  cluster_type_id = netbox_cluster_type.hetzner_cloud.id
  site_id         = netbox_site.nl.id
}

resource "netbox_cluster" "oci_zrh" {
  name            = "oci-zrh"
  cluster_type_id = netbox_cluster_type.oci.id
  site_id         = netbox_site.zrh.id
}

# ── Virtual Machines (Hetzner VPS) ───────────────────────────────────────────

resource "netbox_virtual_machine" "mail2" {
  name         = "mail2"
  cluster_id   = netbox_cluster.hetzner_nbg.id
  role_id      = netbox_device_role.vps.id
  platform_id  = netbox_platform.debian.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 4096
  disk_size_mb = 40960
  site_id      = 5
}

resource "netbox_virtual_machine" "reverse01" {
  name       = "reverse01"
  cluster_id = netbox_cluster.hetzner_zrh.id
  role_id    = netbox_device_role.vps.id
  status     = "active"
  vcpus      = 1
  memory_mb  = 1024
  site_id    = 6
}

resource "netbox_virtual_machine" "reverse02" {
  name       = "reverse02"
  cluster_id = netbox_cluster.hetzner_zrh.id
  role_id    = netbox_device_role.vps.id
  status     = "active"
  vcpus      = 1
  memory_mb  = 1024
  site_id    = 6
}

resource "netbox_virtual_machine" "k8s_arm" {
  name       = "k8s-arm"
  cluster_id = netbox_cluster.hetzner_zrh.id
  role_id    = netbox_device_role.vps.id
  status     = "active"
  vcpus      = 4
  memory_mb  = 12288
  site_id    = 6
}

resource "netbox_virtual_machine" "vpn_01" {
  name       = "vpn-01"
  cluster_id = netbox_cluster.hetzner_nl.id
  role_id    = netbox_device_role.vps.id
  status     = "active"
  vcpus      = 1
  memory_mb  = 1024
  site_id    = 7
}

resource "netbox_virtual_machine" "vpn_02" {
  name       = "vpn-02"
  cluster_id = netbox_cluster.hetzner_nl.id
  role_id    = netbox_device_role.vps.id
  status     = "active"
  vcpus      = 1
  memory_mb  = 1024
  site_id    = 7
}

# ── Virtual Machines (OCI eu-zurich-1) ───────────────────────────────────────

resource "netbox_virtual_machine" "oci_kubearm" {
  name         = "kubearm"
  cluster_id   = netbox_cluster.oci_zrh.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 4
  memory_mb    = 24576
  disk_size_mb = 51200
  site_id      = netbox_site.zrh.id
}

resource "netbox_virtual_machine" "oci_teleport" {
  name         = "teleport"
  cluster_id   = netbox_cluster.oci_zrh.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 1
  memory_mb    = 1024
  disk_size_mb = 48128
  site_id      = netbox_site.zrh.id
}

resource "netbox_virtual_machine" "oci_test_vpn" {
  name         = "test-vpn"
  cluster_id   = netbox_cluster.oci_zrh.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 1
  memory_mb    = 1024
  disk_size_mb = 48128
  site_id      = netbox_site.zrh.id
}
