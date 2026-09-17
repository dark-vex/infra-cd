# CODE-14: adopt VM 950 (github.ddlns.net). Task log shows heavy VNC
# activity right after creation, then a clean qmshutdown 2026-05-14 and
# zero activity since - the coldest trail of any of the six CODE-14 items,
# but the repo owner chose to adopt rather than decommission it.
#
# scsi1 is the live boot disk despite the higher interface number (live
# `boot: order=scsi1`) - preserved as-is, not renumbered. The `disks` map
# keys below are named disk0/disk1 (matching scsi0/scsi1, NOT boot/data)
# deliberately: this module's `dynamic "disk"` iterates var.disks in
# lexical key order, and every other multi-disk block in this repo has
# key order agreeing with interface order - this is the first one where
# they'd invert, so keeping them aligned avoids being the first test of
# whether the provider is order-sensitive here.
#
# Live scsi1 reports size=204804M (4 MiB over an even 200G). `size` below
# is set to the nearest whole GB (200) per this module's `number` type -
# check `terraform plan` for a spurious shrink action on this disk before
# ever applying; if one appears, stop and investigate rather than apply.
#
# Live has both a real cloud-init SSH key and a cloud-init password
# (redacted by the Proxmox API, unrecoverable). Not reproduced here -
# this module's `initialization[0].user_account` is in the lifecycle
# ignore_changes list, so the standard repo SSH keys below are never
# actually reconciled against the live VM; existing access is unaffected.
module "hpelvisor_github_ddlns_net_vm" {
  source = "github.com/dark-vex/terraform-proxmox-vm?ref=1302f332cf44d3ec261c50663ba64c74ae7513b5" # v1.0.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  name        = local.gozzi_hpelvisor_secrets.hpelvisor.vm.github_ddlns_net
  vmid        = 950
  node_name   = "hpelvisor"
  description = local.gozzi_hpelvisor_secrets.hpelvisor.vm.github_ddlns_net

  cpu_cores   = 4
  cpu_sockets = 2
  cpu_type    = "host"
  memory      = 32576

  disks = {
    disk0 = {
      datastore_id = "data-hdd"
      interface    = "scsi0"
      size         = 200
      ssd          = false
      discard      = "ignore"
    }

    disk1 = {
      datastore_id = "data-hdd"
      interface    = "scsi1"
      size         = 200
      ssd          = false
      discard      = "ignore"
      backup       = false
    }
  }

  boot_order = ["scsi1"]

  network_devices = {
    net0 = { bridge = "vmbr5", mac_address = "BC:24:11:7B:DF:20" }
  }

  ip_config = {
    ipv4_address = "dhcp"
    ipv6_address = "dhcp"
  }

  cloud_init_datastore_id = "data-hdd"
  cloud_init_user         = "daniele"
  cloud_init_dns = {
    servers = ["10.20.0.254"]
  }

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  agent_enabled = true

  started       = false
  start_on_boot = false

  tags = ["automation", "vm"]
}
