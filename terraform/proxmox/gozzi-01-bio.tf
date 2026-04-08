# Resources for gozzi-01-bio (LUG, Switzerland)
# HP ProLiant DL360 Gen9

# ============================================================================
# LXC Containers
# ============================================================================

# Add containers here after running the discovery script
# Example:
#
# module "gozzi_example" {
#   source = "../modules/proxmox-lxc"
#   providers = {
#     proxmox = proxmox.gozzi
#   }
#
#   hostname        = "example.ddlns.net"
#   vmid            = 100
#   node_name       = "gozzi-01-bio"
#   description     = "Example container"
#
#   cpu_cores       = 2
#   memory          = 2048
#   disk_size       = 20
#   disk_datastore  = "local-lvm"
#
#   template_file_id = proxmox_virtual_environment_download_file.gozzi_ubuntu_24_04_lxc.id
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

# ============================================================================
# VMs
# ============================================================================

# Add VMs here after running the discovery script
