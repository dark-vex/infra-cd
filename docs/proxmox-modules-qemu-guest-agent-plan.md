# Spec: qemu-guest-agent install for `dark-vex/terraform-proxmox-vm`

This is a handoff spec for a **separate Claude Code session** run directly
against `dark-vex/terraform-proxmox-vm` (and, more briefly,
`dark-vex/terraform-proxmox-lxc`) — those repos aren't checked out in
`infra-cd`'s workspace, so the module change itself can't be made from here.

## Why

**This no longer solves an IP-discovery problem.** The polling-based NetBox
IP discovery pipeline this doc originally supported
(`scripts/netbox-proxmox-ip-discover.py`,
`.github/workflows/netbox-ip-discovery.yml`) was abandoned before being
merged — it didn't scale (a hand-invented sops key per guest, re-decrypted
on every scheduled run) and used the wrong trigger (polling can only ever
discover an IP *some time after* boot, and depends on `qemu-guest-agent`
being installed to answer
`/nodes/{node}/qemu/{vmid}/agent/network-get-interfaces` in the first
place). It's replaced by a self-registration design: the guest phones home
once, at boot, via a custom cloud-init `runcmd`/`curl` callback straight to
a Semaphore webhook — see the self-registration plan for the current
mechanism. That design does not depend on `qemu-guest-agent` at all.

`qemu-guest-agent` is still independently worth installing for what it
actually does well: graceful shutdown/reboot from the Proxmox UI/API
(instead of a hard power-off), filesystem freeze/thaw for consistent
snapshots and backups, and `fstrim` support for thin-provisioned storage.
Everything below about the module change itself (the new
`install_qemu_guest_agent` input, the runcmd it should render, migration of
the two hand-rolled `cloud_init_file_id` snippets) still stands on those
merits alone — just don't read it as blocking IP discovery, because nothing
does anymore.

LXCs aren't in scope here either way: `dark-vex/terraform-proxmox-lxc`
guests expose their IP via the host-visible
`/nodes/{node}/lxc/{vmid}/interfaces` endpoint, independent of any in-guest
agent, and the self-registration design doesn't cover LXCs yet regardless
(see the companion `proxmox-lxc-hookscript-plan.md` doc — LXC
self-registration is blocked on that module gaining a `hookscript` input).

## What to add to `terraform-proxmox-vm`

A new input variable, e.g.:

```hcl
variable "install_qemu_guest_agent" {
  description = "Install and enable qemu-guest-agent via cloud-init on first boot"
  type        = bool
  default     = true
}
```

When `true` (and cloud-init is in use — i.e. the module isn't relying purely
on a caller-supplied `cloud_init_file_id` that bypasses the module's own
cloud-init generation), render an additional `runcmd` entry into the
module's default cloud-init user-data, distro-appropriately:

- Debian/Ubuntu family: `apt-get update && apt-get install -y qemu-guest-agent && systemctl enable --now qemu-guest-agent`
- Anything else the module already special-cases (if it special-cases distros
  at all today) should get an equivalent branch; otherwise document that this
  flag assumes a Debian-family image and should be set `false` for others.

Keep the flag skippable: callers using a fully custom `cloud_init_file_id`
snippet (bypassing the module's generated cloud-init entirely) or a non-
cloud-init image should be able to set this `false` without side effects —
don't make the module fail or silently no-op in a confusing way for that
combination; a clear validation error or doc note is enough.

## Acceptance check (in that session)

- `terraform validate` / a plan against a disposable test VM shows the new
  `runcmd` entry rendering correctly with the flag on.
- With the flag off, cloud-init output is unchanged from today (no
  regression for existing callers who don't set it, given the `default =
  true` above — confirm this default is actually what's wanted before
  merging, since it changes behavior for every existing caller that doesn't
  pin `install_qemu_guest_agent = false`).
- Tag a new release (SHA + version tag) once merged.

## Follow-up in `infra-cd` (separate, later PR — not part of this handoff)

Once the module ships the new input and a new tag/SHA exists:

1. Bump the pinned `ref=<sha>` in each `terraform/proxmox/*/vm.tf` module
   call (currently all pinned to `1302f332cf44d3ec261c50663ba64c74ae7513b5`
   # v1.0.0).
2. Set `install_qemu_guest_agent` explicitly at call sites where the default
   wouldn't be correct (non-Debian-family guests, e.g. `SophosXG`, or any VM
   intentionally not using the module's own cloud-init).
3. Migrate the VMs currently using an unmanaged custom `cloud_init_file_id`
   snippet (e.g. `rabbit_web1_ddlns_net_vm`'s
   `local:snippets/ubuntu.cloud-config.yaml`,
   `rabbit_rtmp1_ddlns_net_vm`'s `ubuntu-rtmp.cloud-config.yaml`) onto the
   module-native flag where that snippet's only job was agent installation —
   check each snippet's actual contents first; if it does more than install
   the agent, keep the snippet and just confirm no double-install conflict.

This is intentionally a distinct, separately sequenced PR from the
self-registration work, since it depends on external repo work landing
first.
