module "gozzi_mon_lug_lxc" {
  source = "../../modules/proxmox-lxc"
  providers = {
    proxmox = proxmox.gozzi_pve
  }

  hostname    = "mon-lug.ddlns.net"
  vmid        = 801
  node_name   = "gozzi-pve"
  description = "Proxmox monitoring - LUG site (pve-exporter + Grafana Alloy)"

  cpu_cores      = 1
  cpu_limit      = 1
  memory         = 512
  swap           = 0
  disk_size      = 4
  disk_datastore = "local-lvm"

  template_file_id = proxmox_virtual_environment_download_file.gozzi_ubuntu_24_04_lxc.id
  os_type          = "ubuntu"

  network_bridge         = "vmbr5"
  network_interface_name = "eth0"
  ip_config = {
    ipv4_address = "dhcp"
  }

  console = {}

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]
  password     = data.onepassword_item.lxc_access.password
  unprivileged = true

  started       = true
  start_on_boot = true

  manage_user_account = false

  tags = ["automation", "lxc", "monitoring"]
}
