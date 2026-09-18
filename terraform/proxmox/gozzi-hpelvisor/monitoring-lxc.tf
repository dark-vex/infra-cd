module "gozzi_mon_lug_lxc" {
  source = "github.com/dark-vex/terraform-proxmox-lxc?ref=49277d5e2d4eb8a5f3173e02965170aecde6711a" # v2.0.0
  providers = {
    proxmox = proxmox.gozzi_pve
  }

  hostname    = local.gozzi_hpelvisor_secrets.gozzi_pve.lxc.mon_lug_lxc
  vmid        = 801
  node_name   = "gozzi-pve"
  description = "Proxmox monitoring - LUG site (pve-exporter + Grafana Alloy)"

  cpu_cores      = 1
  cpu_limit      = 1
  memory         = 512
  swap           = 0
  disk_size      = 4
  disk_datastore = "local-zfs"

  template_file_id = proxmox_download_file.gozzi_ubuntu_24_04_lxc.id
  os_type          = "ubuntu"

  network_interfaces = {
    eth0 = {
      bridge       = "vmbr5"
      ipv4_address = "dhcp"
    }
  }

  console = {}

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]
  password     = data.onepassword_item.lxc_access.password
  unprivileged = true

  started       = false
  start_on_boot = false

  manage_user_account = true

  tags = ["automation", "lxc", "monitoring"]
}
