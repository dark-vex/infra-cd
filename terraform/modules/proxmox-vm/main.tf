resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vmid

  started       = var.started
  on_boot       = var.start_on_boot

  agent {
    enabled = var.agent_enabled
  }

  cpu {
    cores        = var.cpu_cores
    architecture = var.cpu_architecture
    type         = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  dynamic "disk" {
    for_each = var.disks
    content {
      datastore_id = disk.value.datastore_id
      size         = disk.value.size
      interface    = disk.value.interface
      file_format  = disk.value.file_format
      file_id      = disk.value.file_id
      iothread     = disk.value.iothread
    }
  }

  network_device {
    bridge      = var.network_bridge
    mac_address = var.network_mac_address
  }

  initialization {
    datastore_id = var.cloud_init_datastore_id

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

    user_account {
      keys     = var.ssh_keys
      password = var.cloud_init_password
      username = var.cloud_init_user
    }

    user_data_file_id = var.cloud_init_file_id
  }

  operating_system {
    type = var.os_type
  }

  serial_device {}

  lifecycle {
    ignore_changes = [
      # Ignore changes to disk file_id after initial creation
      # as it becomes a reference to the cloned disk
      disk[0].file_id,
    ]
  }
}
