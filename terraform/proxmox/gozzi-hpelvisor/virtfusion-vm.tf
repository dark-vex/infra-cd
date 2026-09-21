module "hpelvisor_virtfusion_vm" {
  source = "github.com/dark-vex/terraform-proxmox-vm?ref=ea5d8f8c164aded71538a45ab978f574bbbbe5b4" # v1.3.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  name        = local.gozzi_hpelvisor_secrets.hpelvisor.vm.virtfusion
  vmid        = 952
  node_name   = "hpelvisor"
  description = local.gozzi_hpelvisor_secrets.hpelvisor.vm.virtfusion

  cpu_cores   = 2
  cpu_sockets = 1
  cpu_type    = "host"
  memory      = 4096

  disks = {
    boot = {
      datastore_id = "data-hdd"
      interface    = "scsi0"
      size         = 30
      file_id      = proxmox_virtual_environment_file.hpelvisor_debian_13_cloud.id
      iothread     = true
      ssd          = false
      discard      = "ignore"
      backup       = false
    }
  }

  boot_order = ["scsi0"]

  network_devices = {
    net0 = { bridge = "vmbr5", mac_address = "BC:24:11:8A:5D:19" }
  }

  ip_config = {
    ipv4_address = "dhcp"
  }

  cloud_init_datastore_id = "data-hdd"
  cloud_init_user         = "debian"

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  agent_enabled = true

  started       = true
  start_on_boot = true

  tags = ["automation", "vm", "virtfusion"]
}
