resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vmid

  started = var.started
  on_boot = var.start_on_boot

  protection = var.protection
  bios       = var.bios_type # es. "seabios" o "ovmf"

  # Definisce il controller SCSI (importante per le performance)
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = var.agent_enabled
  }

  cpu {
    cores   = var.cpu_cores
    sockets = var.cpu_sockets
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  # --- GESTIONE DISCHI ---
  dynamic "disk" {
    # Itera sulla mappa (chiave => oggetto)
    for_each = var.disks

    content {
      datastore_id = disk.value.datastore_id
      size         = disk.value.size
      
      # Qui è il trucco: l'interfaccia DEVE essere definita nel valore
      interface    = disk.value.interface 
      
      file_format  = try(disk.value.file_format, "raw")
      file_id      = try(disk.value.file_id, null)
      iothread     = try(disk.value.iothread, true)
      ssd          = try(disk.value.ssd, true)
      discard      = try(disk.value.discard, "on")
    }
  }

  # --- GESTIONE CD-ROM (Opzionale) ---
  # Si attiva solo se la variabile var.cdrom è definita
  dynamic "cdrom" {
    for_each = var.cdrom != null ? [var.cdrom] : []
    content {
      file_id   = cdrom.value.file_id   # es. "local:iso/ubuntu.iso" o "none"
      interface = try(cdrom.value.interface, "ide2")
    }
  }

  # --- GESTIONE EFI (Opzionale) ---
  dynamic "efi_disk" {
    for_each = var.efi_disk != null ? [var.efi_disk] : []
    content {
      datastore_id      = efi_disk.value.datastore_id
      file_format       = try(efi_disk.value.file_format, "raw")
      type              = try(efi_disk.value.type, "4m")
      pre_enrolled_keys = try(efi_disk.value.pre_enrolled_keys, false)
    }
  }

  # --- ORDINE DI AVVIO ---
  # È buona norma esplicitarlo
  boot_order = var.boot_order

  network_device {
    bridge       = var.network_bridge
    mac_address  = var.network_mac_address
    disconnected = var.network_disconnected
  }

  # --- CLOUD-INIT ---
  dynamic "initialization" {
    for_each = var.cloud_init_datastore_id != null ? [1] : []
    
    content {
      datastore_id = var.cloud_init_datastore_id

      # Configurazione DNS
      dynamic "dns" {
        #for_each = var.cloud_init_dns != null ? [var.cloud_init_dns] : []
        for_each = try(var.cloud_init_dns.domain != null || length(var.cloud_init_dns.servers) > 0, false) ? [var.cloud_init_dns] : []
        content {
          domain  = try(dns.value.domain, null)
          servers = try(dns.value.servers, [])
        }
      }

      # Configurazione IP
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

      # User Account (se non c'è il file custom)
      dynamic "user_account" {
        for_each = var.cloud_init_file_id == null ? [1] : []
        content {
          keys     = var.ssh_keys
          password = var.cloud_init_password
          username = var.cloud_init_user
        }
      }

      # File custom (se presente)
      user_data_file_id = var.cloud_init_file_id
    }
  }

  operating_system {
    type = var.os_type # es. "l26"
  }

  serial_device {}

  lifecycle {
    ignore_changes = [
      # Ignora tutti i file_id dei dischi (evita che TF provi a ricreare il disco dopo un clone)
      #disk[*].file_id,
      # Ignora modifiche post-deploy all'account utente cloud-init
      initialization[0].user_account,
      # Spesso utile ignorare lo stato power se gestito manualmente
      started
    ]
    prevent_destroy = true
  }
}
