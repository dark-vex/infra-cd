# CODE-14: adopt LXC 400 (pbs-gen8-lxc). Task log shows its final-ever
# vzstart at 2026-06-12 17:10:15 - 7 minutes before VM 1001 (pbs-gen8)
# was created - direct evidence this LXC was superseded by that VM, not
# just an inference from static config. Both prior start attempts logged
# WARNINGS:1; never confirmed healthy before the cutover.
#
# Live `hostname` is `pbs-gen8.bioadventures.eu` - identical to VM 1001's
# live `name`, not a `-lxc`-suffixed variant (verified via a fresh MCP
# live pull 2026-09-20; the squid/squid-lxc precedent has genuinely
# distinct Proxmox-side hostnames, this pair does not). The SOPS value
# for hpelvisor.lxc.pbs_gen8 must match VM 1001's exactly to avoid a
# hostname-change diff on import.
module "hpelvisor_pbs_gen8_lxc" {
  source = "github.com/dark-vex/terraform-proxmox-lxc?ref=49277d5e2d4eb8a5f3173e02965170aecde6711a" # v2.0.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  hostname    = local.gozzi_hpelvisor_secrets.hpelvisor.lxc.pbs_gen8
  vmid        = 400
  node_name   = "hpelvisor"
  description = local.gozzi_hpelvisor_secrets.hpelvisor.lxc.pbs_gen8

  cpu_cores      = 2
  memory         = 4096
  swap           = 0
  disk_size      = 2
  disk_datastore = "data-hdd"

  template_file_id = proxmox_download_file.hpelvisor_ubuntu_24_04_lxc.id
  os_type          = "debian"

  network_interfaces = {
    eth0 = {
      bridge       = "vmbr0"
      mac_address  = "BC:24:11:1F:F7:4B"
      ipv4_address = "dhcp"
    }
    # Live static IP in the PBS management subnet, adjacent to the real
    # pve-backup PBS server (10.50.0.5) - no gateway key present live,
    # not added here.
    eth1 = {
      bridge       = "vmbr3"
      mac_address  = "BC:24:11:B2:24:66"
      ipv4_address = "10.50.0.6/29"
    }
  }

  # Live config has no `unprivileged` key, which Proxmox treats as
  # privileged (0) - same situation as pbs-gen9-lxc.tf.
  unprivileged = false

  console = {}

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]
  password = data.onepassword_item.lxc_access.password

  started       = false
  start_on_boot = false

  tags = ["automation", "lxc", "pbs"]
}
