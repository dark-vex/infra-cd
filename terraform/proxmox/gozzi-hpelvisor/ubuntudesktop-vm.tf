# CODE-14: adopt VM 951 (UbuntuDesktop). One interactive desktop session
# on 2026-05-13, dormant since; no tags or automation markers. Live state
# can't distinguish "abandoned" from "someone's occasional desktop" -
# repo owner chose to adopt it. No FQDN/SOPS key: matches the existing
# kubenuc-w2 precedent of hardcoding a plain, non-network-identifying
# display name directly.
#
# No cloud-init drive and no `ipconfig0` live at all - this is a manually
# installed desktop OS, not cloud-init provisioned. cloud_init_datastore_id
# is deliberately omitted (module disables the whole `initialization`
# block when null) so importing doesn't add a cloud-init drive that never
# existed.
module "hpelvisor_ubuntu_desktop_vm" {
  source = "github.com/dark-vex/terraform-proxmox-vm?ref=1302f332cf44d3ec261c50663ba64c74ae7513b5" # v1.0.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  name        = "UbuntuDesktop"
  vmid        = 951
  node_name   = "hpelvisor"
  description = "UbuntuDesktop"

  cpu_cores   = 2
  cpu_sockets = 2
  cpu_type    = "x86-64-v2-AES"
  memory      = 8192

  disks = {
    boot = {
      datastore_id = "data-hdd"
      interface    = "scsi0"
      size         = 50
      ssd          = false
      discard      = "ignore"
    }
  }

  boot_order = ["scsi0", "net0"]

  network_devices = {
    net0 = { bridge = "vmbr5", mac_address = "BC:24:11:FB:81:2F" }
  }

  agent_enabled = false

  started       = false
  start_on_boot = false

  tags = ["automation", "vm"]
}
