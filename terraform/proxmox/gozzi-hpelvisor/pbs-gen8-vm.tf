# CODE-14: adopt VM 1001 (pbs-gen8). Created 2026-06-12 17:17:29, seven
# minutes after LXC 400's (pbs-gen8-lxc) final start - this VM replaced
# it with a real 1.5TB physical-disk passthrough for the datastore, vs.
# the LXC's plain 2G rootfs. Not the live production backup target
# (that's gozzi_pve_pve_backup_vm / VM 1000, already Terraform-managed
# and running) - task log shows only a single 61-second qmstart/qmstop
# on 2026-08-11 since creation, i.e. an occasional boot-check on a
# slow-moving, not-yet-cutover build, not active use.
module "hpelvisor_pbs_gen8_vm" {
  source = "github.com/dark-vex/terraform-proxmox-vm?ref=a9155a000a4f72cd80385e55e5f5944ca9391498" # v1.2.0
  providers = {
    proxmox = proxmox.hpelvisor
  }

  name        = local.gozzi_hpelvisor_secrets.hpelvisor.vm.pbs_gen8
  vmid        = 1001
  node_name   = "hpelvisor"
  description = local.gozzi_hpelvisor_secrets.hpelvisor.vm.pbs_gen8

  cpu_cores   = 2
  cpu_sockets = 1
  cpu_type    = "host"
  memory      = 4096
  # Live balloon=0 - no memory_floating declared (unlike VM 951, whose
  # non-zero balloon value this field exists to express).

  disks = {
    # ssd=false/discard="ignore" set explicitly per this repo's convention
    # for data-hdd-datastore disks (matches github-vm.tf, ubuntudesktop-vm.tf)
    # - live has no ssd=/discard= key on either disk, same as those siblings.
    # iothread=true matches live (`iothread=1`) and this module's own
    # default, declared here for clarity since it's a real live setting,
    # not a default fallback.
    boot = {
      datastore_id = "data-hdd"
      interface    = "scsi0"
      size         = 10
      iothread     = true
      ssd          = false
      discard      = "ignore"
      backup       = false
    }
    # Raw physical-disk passthrough - the 1.5TB backup datastore LV.
    # backup=false set explicitly to match live; the module's own docs
    # warn this defaults to true and would otherwise show a spurious diff.
    # iothread=false set explicitly too: live has no iothread key on this
    # disk (Proxmox absent-key default is off), but the module defaults
    # passthrough entries to iothread=true - without this override,
    # import would plan to silently enable iothread on a live raw block
    # device, the exact "spurious diff on adoption" this module's docs
    # warn about.
    #
    # file_format=null (not the module's "raw" default) for the same
    # reason: live has no file_format key on this disk either, and any
    # attribute mismatch here forces an update API call against the
    # passthrough path - which Proxmox rejects for non-root tokens
    # ("Only root can pass arbitrary filesystem paths", confirmed via a
    # real failed CI apply on 2026-09-20). try(disk.value.file_format,
    # "raw") in the module only falls back to "raw" when the key is
    # entirely absent, not when it's explicitly null - passing null here
    # keeps it null, matching live, avoiding the update call altogether.
    #
    # No `size` - a passthrough entry only ever imports, never creates.
    pbs_datastore = {
      datastore_id      = "" # module validation requires this exact value whenever path_in_datastore is set
      path_in_datastore = "/dev/disk/by-id/dm-name-data--backup--hdd-pbs--datastore"
      interface         = "scsi1"
      iothread          = false
      file_format       = null
      ssd               = false
      discard           = "ignore"
      backup            = false
    }
  }

  boot_order = ["scsi0"]

  network_devices = {
    net0 = { bridge = "vmbr0", mac_address = "BC:24:11:AC:7B:CC" }
    net1 = { bridge = "vmbr3", mac_address = "BC:24:11:50:C1:A8" }
  }

  # Live has no ipconfig0/ipconfig1 key on either NIC at all - genuinely
  # unconfigured, not confirmed dhcp the way VM 950's explicit
  # `ip=dhcp,ip6=dhcp` was. Treating both as dhcp; verify before apply.
  ip_config = {
    ipv4_address = "dhcp"
  }

  cloud_init_datastore_id = "data-hdd"
  # No ciuser/cipassword set live (unlike VM 950/951) - cloud_init_user
  # deliberately omitted rather than guessed.

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]

  agent_enabled = true

  started       = false
  start_on_boot = false

  tags = ["automation", "vm", "pbs"]
}
