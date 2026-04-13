# Resources for ec200 (pve-ec200)
# Proxmox cluster node

# ============================================================================
# LXC Containers
# ============================================================================

# Add containers here after running the discovery script
# Example:
#
# module "ec200_example" {
#   source = "../modules/proxmox-lxc"
#   providers = {
#     proxmox = proxmox.ec200
#   }
#
#   hostname        = "example.ddlns.net"
#   vmid            = 100
#   node_name       = "pve-ec200"
#   description     = "Example container"
#
#   cpu_cores       = 2
#   memory          = 2048
#   disk_size       = 20
#   disk_datastore  = "local-lvm"
#
#   template_file_id = proxmox_virtual_environment_download_file.ec200_ubuntu_24_04_lxc.id
#   os_type          = "ubuntu"
#
#   network_bridge = "vmbr0"
#   ip_config = {
#     ipv4_address = "dhcp"
#   }
#
#   ssh_keys     = [
#     data.onepassword_item.ssh_key.public_key,
#     data.onepassword_item.ssh_key_new.public_key
#   ]
#   password     = onepassword_item.lxc_access.password
#   unprivileged = true
#
#   tags = ["automation", "ubuntu", "lxc"]
# }

module "ec200_mon_mxp_lxc" {
  source = "../../modules/proxmox-lxc"
  providers = {
    proxmox = proxmox.ec200
  }

  hostname    = "mon-mxp.ddlns.net"
  vmid        = 100
  node_name   = "pve-ec200"
  description = "Proxmox monitoring - MXP site (pve-exporter + Grafana Alloy)"

  cpu_cores      = 1
  cpu_limit      = 1
  memory         = 512
  swap           = 0
  disk_size      = 4
  disk_datastore = "local-lvm"

  template_file_id = proxmox_virtual_environment_download_file.ec200_ubuntu_24_04_lxc.id
  os_type          = "ubuntu"

  network_bridge         = "vmbr0"
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

# ============================================================================
# VMs
# ============================================================================

# Add VMs here after running the discovery script
