# Spec: `hookscript` input for `dark-vex/terraform-proxmox-lxc`

This is a handoff spec for a **separate Claude Code session** run directly
against `dark-vex/terraform-proxmox-lxc` — that repo isn't checked out in
`infra-cd`'s workspace, so the module change itself can't be made from here.
Companion to `proxmox-modules-qemu-guest-agent-plan.md` (same handoff
pattern, different module/gap).

## Why

The self-registration design (guest boots → phones home to a Semaphore
webhook → NetBox gets its primary IP) is VM-only for now. LXCs are
architecturally blocked: confirmed by reading the full vendored module
source (`terraform/proxmox/rabbit/.terraform/modules/*_lxc/variables.tf`,
`main.tf`), `dark-vex/terraform-proxmox-lxc` has **no `user_data` /
cloud-init input and no `hookscript` variable at all** — there's no
in-container mechanism to run a callback on first boot, and no
Proxmox-level hook to run one from the host side either.

LXCs don't get a cloud-init equivalent the way VMs do (no cloud-init agent
runs inside a container the way it does inside a QEMU guest), so the
callback has to be driven from the Proxmox host itself, via Proxmox's
native `hookscript` mechanism
(`pct set <vmid> --hookscript <volume-id>:snippets/<script>`, invoked by
`pvedaemon` at `pre-start`/`post-start`/`pre-stop`/`post-stop` phases).

## What to add to `terraform-proxmox-lxc`

A new input variable:

```hcl
variable "hookscript" {
  description = "Proxmox hookscript reference (e.g. \"local:snippets/register.sh\"), run by pvedaemon at container lifecycle phase transitions. Null (default) leaves the container's hookscript unset."
  type        = string
  default     = null
}
```

Wire it straight through to the underlying `proxmox_virtual_environment_container` resource's `hookscript` attribute (`bpg/proxmox` provider) — this is a passthrough, not generated content. The module doesn't need to know or care what the script does; the caller (`infra-cd`) owns the actual registration logic and uploads the snippet itself, the same way the two hand-rolled VM cloud-init snippets (`web1`, `rtmp1`) work today.

Keep it optional and side-effect-free when unset: existing callers who don't set `hookscript` should see no diff in `terraform plan`.

## Acceptance check (in that session)

- `terraform validate` / a plan against a disposable test LXC shows the
  `hookscript` attribute set correctly when the variable is provided.
- With the variable unset (the default), the container's config is
  unchanged from today — no regression for existing callers.
- Tag a new release (SHA + version tag) once merged.

## Follow-up in `infra-cd` (separate, later PR — not part of this handoff)

Once the module ships the new input and a new tag/SHA exists:

1. Bump the pinned module ref in `terraform/proxmox/*/lxc.tf` (and
   `seaweedfs-lxc.tf`) call sites that need self-registration.
2. Author the actual hook script (`post-start` phase — the container needs
   its network interface up first) that mirrors the VM callback client:
   determine the container's own IP, read its baked-in token, POST
   `{token, ip}` to the Semaphore webhook with retry/backoff. This is Proxmox
   host-side shell, not cloud-init `runcmd` — different execution context,
   same payload contract as the VM side (see the self-registration plan's
   §2 for the shape).
3. Upload the snippet to each Proxmox node's snippet storage and reference
   it via `hookscript = "local:snippets/<name>.sh"` per LXC, the same
   unmanaged-snippet pattern the two VM exceptions (`web1`, `rtmp1`) already
   use — decide explicitly whether that's an acceptable amount of
   out-of-Terraform-state content for the LXC fleet, or whether it's worth
   generating the snippet content too once this many callers need it.
4. Extend the registration manifest / Semaphore job to accept LXC entries
   (they already appear in the abandoned `dhcp_guest_manifest` shape keyed
   by `type = "lxc"` vs `"qemu"` — the distinction carries over cleanly).

This is intentionally a distinct, separately sequenced PR from the VM
self-registration work, since it depends on external repo work landing
first — same relationship the qemu-guest-agent doc has to its own module
change.
