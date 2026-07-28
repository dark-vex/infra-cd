# Spec: cloud-init handoff for `dark-vex/terraform-proxmox-vm`

This is a handoff spec for a **separate Claude Code session** run directly
against `dark-vex/terraform-proxmox-vm` — that repo isn't checked out in
`infra-cd`'s workspace, so neither change below can be made from here.

Batched as **one combined spec, not two**: `additional_runcmd` (this doc's
new content) and `install_qemu_guest_agent` (this doc's prior content) are
both cloud-init-generation changes to the same module, both need the same
version bump and SHA re-pin across all three stacks (`rabbit`, `ec200`,
`gozzi-hpelvisor`) once merged. Shipping them separately would mean bumping
twice and re-litigating the zero-diff regression check (Verification
step 3 of the self-registration plan) a second time for no benefit.

## Why this exists

Two independent needs converge on the same module change:

1. **Self-registration callback** (new): a Proxmox guest needs to POST its
   own IP to a Semaphore webhook once, at first boot, so NetBox/Ansible
   inventory can pick it up without polling or `qemu-guest-agent`. See the
   self-registration plan (Design §2) for the full mechanism and the
   security/injection rationale — this doc only covers the module-side
   plumbing needed to deliver the callback script.
2. **qemu-guest-agent** (carried over from the original, narrower version of
   this doc): still worth installing on every VM, but **no longer for IP
   discovery**. The polling pipeline this doc originally supported
   (`scripts/netbox-proxmox-ip-discover.py` +
   `.github/workflows/netbox-ip-discovery.yml`) was abandoned before merge —
   it didn't scale (a hand-invented sops key per guest, re-decrypted on
   every scheduled run) and used the wrong trigger (polling can only ever
   discover an IP *some time after* boot, and depends on the agent
   answering `/nodes/{node}/qemu/{vmid}/agent/network-get-interfaces` in the
   first place). The agent's role is now scoped purely to graceful
   shutdown/reboot from the Proxmox UI/API, filesystem freeze/thaw for
   consistent snapshots and backups, and `fstrim` for thin-provisioned
   storage — independent of IP delivery.

LXCs aren't in scope for either change: `dark-vex/terraform-proxmox-lxc` has
no `user_data`/cloud-init input at all today (confirmed by reading the full
vendored module source), and its guests expose their IP via the host-visible
`/nodes/{node}/lxc/{vmid}/interfaces` endpoint regardless — see the
companion `proxmox-lxc-hookscript-plan.md` doc for the separate LXC
follow-up (blocked on that module gaining a `hookscript` input).

## Scoping: new VMs only, never a retrofit

**Both changes below apply only to VMs newly created going forward** —
cloud-init settings established at a VM's initial `apply` (a `create`
action), never retrofitted onto an already-existing VM via `update`.

This isn't a style preference — it's load-bearing. Live-tested against real
TFC-backed state in `terraform/proxmox/rabbit` (see the self-registration
plan's Design §2 "Gate 3 finding" for the full test log): setting
`user_data_file_id` (what `cloud_init_file_id` maps to under the hood) for
the first time on an *already-existing* VM forces destroy+recreate — a live
provider plan-modifier invisible in static schema (`terraform providers
schema -json` shows no `force_new` on that attribute; only a real `terraform
plan` against real state surfaces it as `replace_paths`). The same test
against `vendor_data_file_id` (the separate cloud-init source the
`additional_runcmd` input below uses) hit the identical wall — the
ForceNew-on-first-set behavior applies to the whole `initialization` block's
file attributes, not just one of them. The module's own
`lifecycle { prevent_destroy = true }` caught both attempts before they
could apply (`terraform plan` hard-errored: "Instance cannot be destroyed").

A brand-new resource has no "before" state to be force-replaced away from,
so scoping to genuinely new VMs sidesteps the problem by construction
rather than by workaround. Do not set either new input on an existing
`terraform/proxmox/*/vm.tf` module block without re-running that live-plan
test first.

## Change 1: `additional_runcmd` — self-registration callback delivery

Read directly from the vendored module source: the `initialization` block
sets `user_account { keys, password, username }` only when
`var.cloud_init_file_id == null`, and sets `user_data_file_id =
var.cloud_init_file_id` only when it's set — there is no field today for
injecting arbitrary `runcmd` content into the module-generated path, and no
existing inline user-data render that a new list could be appended into.

**Add a new input:**

```hcl
variable "additional_runcmd" {
  description = "Extra runcmd entries rendered into a separate vendor-data cloud-init source, merged with the module's own generated user-data at boot. Empty list = no vendor-data snippet uploaded, zero behavior change for existing callers."
  type        = list(string)
  default     = []
}
```

**Render into a separate vendor-data snippet, not the existing user-data
path.** When `additional_runcmd` is non-empty:

1. Render a small cloud-config document containing just `runcmd:
   <additional_runcmd>`.
2. Upload it via a new `proxmox_virtual_environment_file` resource (a
   distinct provider-native cloud-init data source from `user_data_file_id`)
   — only created when the list is non-empty, so callers who never set this
   input get zero new resources in their plan.
3. Set `vendor_data_file_id` to that upload's id.

This is purely additive: the existing `user_account`/`user_data_file_id`
logic is completely untouched, so there's zero regression surface for the
13 already-cloud-init'd VMs even under the version bump — unlike the
alternative (having the module render its own `user_data_file_id` snippet),
which would displace the native `user_account` block for every existing
caller, not just new ones.

**Prerequisite already satisfied, nothing new needed:** snippet uploads need
the bpg provider's `ssh` block (all three `provider.tf` files in `infra-cd`
already have one) and a snippets-enabled datastore (already proven working
today — the `web1`/`rtmp1` VMs reference `local:snippets/*.yaml`).

**Confirm at module-change time, not blocking:** cloud-init merges
user-data and vendor-data at boot on standard cloud images. This fleet's
`images.tf` files use stock Ubuntu 22.04/Debian 11/13 genericcloud images,
none of which are known to disable vendor-data processing — worth a
one-line confirmation against the actual image, not a gate.

### Precondition this creates for `infra-cd` callers (document at the call site)

**A VM using a custom `cloud_init_file_id` snippet instead of the module's
own `cloud_init_datastore_id` generation is incompatible with
`additional_runcmd` and must never be given a self-registration
token/manifest entry.** cloud-init's default merge behavior for `runcmd` is
**replace, not concatenate**, and user-data takes precedence over
vendor-data — if a VM's `cloud_init_file_id` supplies its own `runcmd` (the
`web1`/`rtmp1`-style unmanaged-snippet path), that user-data `runcmd`
silently wins and the vendor-data callback never fires, with **no error
anywhere**. This is exactly why `web1`/`rtmp1` stay out of scope for
self-registration. Document this constraint at the point where a new VM
module block is authored, not just here.

### `instance-id` guard (only matters if provisioning ever changes)

`runcmd` fires once per cloud-init `instance-id`. This fleet's images are
pristine, never-booted upstream cloud images imported fresh per VM, not
Proxmox linked-clones from a shared, previously-booted template — so
nothing needs guarding today. It would become a real gap if this fleet's
provisioning ever moves to clone-from-template (a common Proxmox pattern):
a cloned instance can retain the template's original `instance-id` and skip
`runcmd` entirely, silently, with no error. Add a one-line note in the new
module's README/CHANGELOG flagging this so it isn't rediscovered the hard
way if clone-based provisioning is adopted later.

## Change 2: `install_qemu_guest_agent`

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
snippet or a non-cloud-init image should be able to set this `false` without
side effects — don't make the module fail or silently no-op in a confusing
way for that combination; a clear validation error or doc note is enough.

Set `agent { enabled = true }` on the VM resource itself alongside this
input when it's true — the package alone doesn't make Proxmox use the QMP
guest-agent channel.

**Existing VMs are explicitly out of scope for this input too, but for a
different, still-unverified reason than the `additional_runcmd` case
above**: whether `agent.enabled` is itself force-replace-safe on an
already-existing VM has not been live-tested (only `user_data_file_id`,
`vendor_data_file_id`, and `hook_script_file_id` were). The
self-registration plan's Design §7 calls for that live test — mirroring
this doc's own "Gate 3" test methodology — before applying the flag to any
of the 27 existing VMs. Even if that test comes back safe, cloud-init does
not re-run on an already-booted guest, so the *package* install for existing
VMs needs an Ansible task against the live fleet regardless, not a
Terraform/cloud-init change.

## Acceptance check (in that session)

- `terraform validate` / a plan against a disposable test VM shows both new
  inputs rendering correctly when set, and the vendor-data snippet resource
  only appears in the plan when `additional_runcmd` is non-empty.
- With both flags at their defaults (`additional_runcmd = []`,
  `install_qemu_guest_agent = true`), confirm the *only* new thing in the
  plan for an existing caller who doesn't touch either input is the
  guest-agent `runcmd` entry — re-confirm this default is actually wanted
  before merging, since it changes behavior for every existing caller that
  doesn't pin `install_qemu_guest_agent = false`.
- Tag a new release (SHA + version tag) once merged.

## Follow-up in `infra-cd` (separate, later PR — not part of this handoff)

Once the module ships both inputs and a new tag/SHA exists:

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
   module-native `install_qemu_guest_agent` flag where that snippet's only
   job was agent installation — check each snippet's actual contents first;
   if it does more than install the agent, keep the snippet and just
   confirm no double-install conflict. These two VMs stay ineligible for
   `additional_runcmd`/self-registration regardless (see the precondition
   above), agent migration is independent of that.
4. Confirm the zero-diff plan across all 27 existing VMs before merging the
   SHA bump (Verification step 3 of the self-registration plan) — the new
   inputs must be genuinely additive/opt-in.
5. Only after 1–4: author the first genuinely new self-registering VM using
   `additional_runcmd` (see the self-registration plan's Design §1 for the
   `registration_manifest` entry it needs alongside).

This is intentionally a distinct, separately sequenced PR from the
self-registration work itself, since it depends on this external repo
change landing first.
