# CODE-27 follow-up: throwaway 30-day trial VirtFusion control-server VM.
# Purpose is provider-fork mechanics familiarity, NOT Hostbrr API parity -
# a fresh self-hosted VirtFusion install exposes the standard admin API
# shape (/api/v1/servers/{int}), not Hostbrr's patched shape (/api/server,
# UUID), confirmed by reading EZSCALE/terraform-provider-virtfusion's
# source directly. No hypervisor node is attached to this control server
# in this pass - verification is read-only API calls only.
#
# Fresh create, not an adopted VM - the first time this stack has created
# a disk from a cloud image rather than importing an existing one. VMID
# 952 picked to sit next to VM 950/951 in hpelvisor's own VM numbering,
# confirmed free via get_next_vmid.
#
# cloud_init_user = "debian": the Debian 13 generic cloud image's native
# default account (passwordless sudo), not "root" - this module puts
# initialization[0].user_account in its lifecycle ignore_changes list, so
# a wrong choice here is a one-shot that no later `terraform apply` can
# repair. If first boot doesn't yield SSH access, the fix is a Proxmox
# console session + update_vm_cloudinit + regenerate + reboot, not a
# re-apply.
#
# No backup/snapshot (backup=false, no scheduled job) - accepted
# consequence is a full rebuild (and a fresh 30-day trial) if this VM is
# lost. Do not put irreplaceable data on it.
#
# Decommissioning after the 30-day trial: this module hardcodes
# `lifecycle { prevent_destroy = true }` unconditionally (main.tf:159 at
# the pinned ref) - a plain revert PR will NOT work. Teardown needs a
# `removed { from = module.hpelvisor_virtfusion_vm }` block (declarative,
# reviewable in the same PR that deletes this file) rather than a manual
# `terraform state rm` against shared TFC state.
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
