# CODE-14: adopt LXC 401 (pbs-gen9), untracked since creation on 2026-05-14.
# Live task log shows exactly one task ever (vzcreate) - never started, no
# repo/NetBox trace. Repo owner chose to adopt rather than decommission
# despite that dormancy.
module "gozzi_pve_pbs_gen9_lxc" {
  source = "github.com/dark-vex/terraform-proxmox-lxc?ref=5abfb3f2814be56504b2ad288247db60a2d8cc9c" # v1.0.0
  providers = {
    proxmox = proxmox.gozzi_pve
  }

  hostname    = local.gozzi_hpelvisor_secrets.gozzi_pve.lxc.pbs_gen9
  vmid        = 401
  node_name   = "gozzi-pve"
  description = local.gozzi_hpelvisor_secrets.gozzi_pve.lxc.pbs_gen9

  cpu_cores      = 2
  memory         = 4096
  swap           = 0
  disk_size      = 2
  disk_datastore = "local-zfs"

  template_file_id = proxmox_download_file.gozzi_ubuntu_24_04_lxc.id
  os_type          = "debian"

  # Live config has no `ip=` key at all on net0 (never configured - this
  # container has never been started). Defaulting to dhcp here is a change
  # from "unset", not from a working static config.
  network_bridge         = "vmbr3"
  network_mac_address    = "BC:24:11:60:3A:2E"
  network_interface_name = "eth0"
  ip_config = {
    ipv4_address = "dhcp"
  }

  # Live config has no `unprivileged` key, which Proxmox treats as
  # privileged (0).
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
