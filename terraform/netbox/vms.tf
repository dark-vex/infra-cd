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

resource "netbox_cluster_type" "hostbrr" {
  name = "Hostbrr"
  slug = "hostbrr"
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

moved {
  from = netbox_cluster.hetzner_nl
  to   = netbox_cluster.oci_nl
}

resource "netbox_cluster" "oci_nl" {
  name            = "oci-nl"
  cluster_type_id = netbox_cluster_type.oci.id
  site_id         = netbox_site.nl.id
}

resource "netbox_cluster" "oci_zrh" {
  name            = "oci-zrh"
  cluster_type_id = netbox_cluster_type.oci.id
  site_id         = netbox_site.zrh.id
}

resource "netbox_cluster" "hostbrr_fra" {
  name            = "hostbrr-fra"
  cluster_type_id = netbox_cluster_type.hostbrr.id
  site_id         = netbox_site.fra.id
}

# ── Virtual Machines (Hetzner / OCI VPS) ─────────────────────────────────────

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

resource "netbox_virtual_machine" "vpn_01" {
  name       = "vpn-01"
  cluster_id = netbox_cluster.oci_nl.id
  role_id    = netbox_device_role.vps.id
  status     = "active"
  vcpus      = 1
  memory_mb  = 1024
  site_id    = 7
}

resource "netbox_virtual_machine" "vpn_02" {
  name       = "vpn-02"
  cluster_id = netbox_cluster.oci_nl.id
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

# ── Virtual Machines (Hostbrr / VirtFusion) ──────────────────────────────────

# CODE-18: onboarded via the VirtFusion customer API (GET /api/server,
# not the /api/v1/servers path the 3 candidate Terraform providers all
# assume - none of them actually match this account's real API surface,
# see CODE-18 comments). NetBox-only for now; Terraform management of
# the VPS itself is deferred pending a working provider. platform_id
# omitted - the customer API exposes no OS field, matching vpn_01/02's
# precedent of leaving it unconfirmed rather than guessed.
resource "netbox_virtual_machine" "hostbrr_rmon_vpn" {
  name         = "rmon-vpn"
  cluster_id   = netbox_cluster.hostbrr_fra.id
  role_id      = netbox_device_role.vps.id
  status       = "active"
  vcpus        = 2
  memory_mb    = 10240
  disk_size_mb = 81920
  site_id      = netbox_site.fra.id
}
