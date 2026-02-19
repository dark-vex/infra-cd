resource "proxmox_virtual_environment_container" "this" {
  description = var.description

  node_name = var.node_name
  vm_id     = var.vmid

  unprivileged = var.unprivileged

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_config.ipv4_address
        gateway = var.ip_config.ipv4_gateway
      }
      dynamic "ipv6" {
        for_each = var.ip_config.ipv6_address != null ? [1] : []
        content {
          address = var.ip_config.ipv6_address
          gateway = var.ip_config.ipv6_gateway
        }
      }
    }

    dynamic "user_account" {
      for_each = var.manage_user_account ? [1] : []
      content {
        keys     = var.ssh_keys
        password = var.password
      }
    }
  }

  network_interface {
    name        = var.network_interface_name
    bridge      = var.network_bridge
    mac_address = var.network_mac_address
  }

  disk {
    datastore_id = var.disk_datastore
    size         = var.disk_size
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  cpu {
    cores        = var.cpu_cores
    architecture = var.cpu_architecture
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  startup {
    order      = tostring(var.startup_order)
    up_delay   = tostring(var.startup_up_delay)
    down_delay = tostring(var.startup_down_delay)
  }

  start_on_boot = var.start_on_boot
  started       = var.started

  tags = var.tags

  dynamic "features" {
    for_each = var.features.nesting || var.features.fuse || var.features.keyctl || length(var.features.mount) > 0 ? [1] : []
    content {
      nesting = var.features.nesting
      fuse    = var.features.fuse
      keyctl  = var.features.keyctl
      mount   = var.features.mount
    }
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume    = mount_point.value.volume
      path      = mount_point.value.path
      size      = mount_point.value.size
      quota     = mount_point.value.quota
      replicate = mount_point.value.replicate
      shared    = mount_point.value.shared
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore template changes after creation
      operating_system[0].template_file_id,
      initialization[0].user_account,
    ]
    prevent_destroy = true
  }
}
