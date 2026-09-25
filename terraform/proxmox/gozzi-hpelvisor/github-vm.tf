# CODE-30: decommission VM 950 (github.ddlns.net), reversing the CODE-14
# adoption decision. Tunnel creation (2026-05-13) lines up right before
# this VM's last configuration activity (qmshutdown 2026-05-14) -
# suggests the github.ddlns.net Cloudflare Tunnel was being wired up for
# it before it was shut down mid-setup. See CODE-14 for the adoption note
# being reversed and CODE-30 for the full decommission scope.
#
# Same removed{} pattern as CODE-29/PR #2042: this module hardcodes
# lifecycle { prevent_destroy = true } internally with no override -
# `removed` bypasses it by design (the resource block is no longer
# declared) rather than overriding it. Live Proxmox state confirmed via
# the proxmox-hpelvisor MCP (read-only) before this change: VM 950 is
# stopped, unprotected, no HA resource references it, and its 2 disks
# (200G scsi0 + 200G scsi1, ~400GB total) match what was declared here.
removed {
  from = module.hpelvisor_github_ddlns_net_vm.proxmox_virtual_environment_vm.this

  lifecycle {
    destroy = true
  }
}
