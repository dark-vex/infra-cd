module "hpelvisor_seaweedfs_lxc" {
  source = "github.com/dark-vex/terraform-proxmox-lxc?ref=5abfb3f2814be56504b2ad288247db60a2d8cc9c" # v1.0.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  hostname    = "seaweedfs-hpelvisor"
  vmid        = 704
  node_name   = "hpelvisor"
  description = "SeaweedFS storage node - replication 100"

  cpu_cores      = 2
  memory         = 4096
  swap           = 0
  disk_size      = 100
  disk_datastore = "data-hdd"

  template_file_id = proxmox_download_file.hpelvisor_ubuntu_24_04_lxc.id
  os_type          = "ubuntu"

  network_bridge         = "vmbr5"
  network_interface_name = "eth0"
  ip_config = {
    ipv4_address = "dhcp"
  }

  console = {
    enabled = true
  }

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]
  password     = data.onepassword_item.lxc_access.password
  unprivileged = true

  started       = true
  start_on_boot = true

  manage_user_account = true

  tags = ["automation", "lxc", "seaweedfs", "storage", "replication-100"]
}
