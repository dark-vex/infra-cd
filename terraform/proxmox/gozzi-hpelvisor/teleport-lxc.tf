# CODE-14: adopt LXC 705 (hpelvisor-teleport). Task log shows a clean
# vzshutdown timed almost exactly with hpelvisor's own last node reboot -
# a "forgot to restart after maintenance" signature, not an abandoned
# experiment. Imported stopped; restarting it is a separate out-of-band
# action (the proxmox-hpelvisor MCP token is read-only, no VM.PowerMgmt).
module "hpelvisor_teleport_lxc" {
  source = "github.com/dark-vex/terraform-proxmox-lxc?ref=49277d5e2d4eb8a5f3173e02965170aecde6711a" # v2.0.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  hostname    = local.gozzi_hpelvisor_secrets.hpelvisor.lxc.teleport
  vmid        = 705
  node_name   = "hpelvisor"
  description = local.gozzi_hpelvisor_secrets.hpelvisor.lxc.teleport

  cpu_cores      = 2
  memory         = 4096
  swap           = 512
  disk_size      = 10
  disk_datastore = "data-hdd"

  template_file_id = proxmox_download_file.hpelvisor_ubuntu_24_04_lxc.id
  os_type          = "ubuntu"

  network_interfaces = {
    eth0 = {
      bridge       = "vmbr0"
      mac_address  = "BC:24:11:A6:9B:D5"
      ipv4_address = "dhcp"
      ipv6_address = "dhcp"
    }
  }

  features = {
    nesting = true
  }

  unprivileged = true

  console = {}

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]
  password = data.onepassword_item.lxc_access.password

  # Deliberately imported stopped, not started - repo owner's explicit
  # choice (adopt it stopped rather than have Terraform start it).
  started       = false
  start_on_boot = false

  tags = ["automation", "lxc", "teleport"]
}
