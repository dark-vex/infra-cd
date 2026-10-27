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
#   hostname        = "example.invalid"
#   vmid            = 100
#   node_name       = "pve-ec200"
#   description     = "Example container"
#
#   cpu_cores       = 2
#   memory          = 2048
#   disk_size       = 20
#   disk_datastore  = "local-lvm"
#
#   template_file_id = proxmox_download_file.ec200_ubuntu_24_04_lxc.id
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

# CODE-91: decommission mon-mxp (VMID 100), the MXP monitoring LXC, at the repo
# owner's request. It ran the MXP pve-exporter and Grafana Alloy and was a
# Teleport node: MXP hypervisor metrics in Grafana Cloud stop with it, and a
# replacement is a separate follow-up. Live state could not be confirmed from
# the agent session (no read-only Proxmox access for ec200), so review the
# plan: it must show exactly one destroy, the container on pve-ec200.
#
# Same removed{} pattern as CODE-29/CODE-30/CODE-32 (PR #2042, #2056, #2073):
# the module hardcodes lifecycle { prevent_destroy = true } internally with no
# override - `removed` bypasses it by design (the resource block is no longer
# declared) rather than overriding it.
removed {
  from = module.ec200_mon_mxp_lxc.proxmox_virtual_environment_container.this

  lifecycle {
    destroy = true
  }
}

# ============================================================================
# VMs
# ============================================================================

# Add VMs here after running the discovery script
