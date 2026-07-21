# Ansible — Conventions & Molecule Testing

## Molecule: Mandatory Before Merge

Every Ansible playbook or role directory **must** ship `molecule/default/{molecule.yml,converge.yml,verify.yml}` before merging. See the `ansible-operations` skill (`.claude/skills/ansible-operations/SKILL.md`) for full templates.

Run via the docker agent:

```bash
docker compose exec -w /workspace/ansible/{role-name} ansible-agent molecule test
```

---

## Key Patterns

**Template path resolution**: `ansible.builtin.template` `src:` resolves relative to the invoking *playbook*, not the tasks file. When tasks are shared via `import_tasks`, use a variable:
- `pve_templates_dir: "{{ playbook_dir }}/templates"` in `playbook.yml`
- `pve_templates_dir: "{{ playbook_dir }}/../../templates"` in `converge.yml`

**Idempotency and systemd services with external deps**: Services that connect to external infrastructure (Grafana, Proxmox) crash in Molecule containers. Split enable/start into two tasks; add `changed_when: false` to the start task:

```yaml
- name: Enable foo service
  ansible.builtin.systemd:
    name: foo
    enabled: true
    daemon_reload: true

- name: Start foo service
  ansible.builtin.systemd:
    name: foo
    state: started
  changed_when: false
```

**verify.yml**: Assert `UnitFileState == "enabled"` — do NOT assert `active` state for services that depend on external infra.

---

## Role Inventory

| Role | Purpose | Notes |
|---|---|---|
| `pve-monitoring` | prometheus-pve-exporter + Grafana Alloy on Proxmox monitoring LXCs | Model role for apt-repo-pinned installs |
| `teleport-client` | Teleport SSH "node" service on VM hosts (`mon-bgy`, `mon-lug`, `mon-mxp`) | Join token only consumed on first start — see role comments |
| `teleport-server` | Adopts the live Teleport Auth/Proxy config on the OCI `teleport.ddlns.net` VM in place | Config/unit are captured from the running box, never authored fresh — see role comments for the break-glass and `--check --diff` rollout requirements |
| `graylog-cert-renewal` | Certbot renewal follow-through (deploy-hook restarting Graylog) for the LXC `graylog.ddlns.net`'s OTel gRPC input TLS cert | Does not issue or touch any existing cert/ACME client config — live state on the box wasn't accessible when authored; same `--check --diff`-first caution as `teleport-server` |

`teleport-client`/`teleport-server` share a `teleport_version` pin (agents must run at a version <= the Auth server's). Bump the server role first, client second — Renovate does not track apt packages.

---

## 1Password via Ansible (Connect)

`teleport-client`'s join token and proxy address are the first secrets fetched into an Ansible run via 1Password, using the `community.general.onepassword` lookup plugin (already installed in the `ansible-agent` image). Authenticate it via **1Password Connect** (`connect_host`/`connect_token` lookup params, sourced from the `OP_CONNECT_HOST`/`OP_CONNECT_TOKEN` env vars — see `docker/agents/docker-compose.yml`), not the `op` CLI: the repo already runs a Connect server for the Kubernetes 1Password Operator (`clusters/kubenuc/apps/1password`), and the `ansible-agent` image has no `op` binary or `OP_*` auth wired in. Reuse that Connect server for any future Ansible↔1Password need rather than adding a second auth path.

Key pattern, followed by both new roles: the lookup call lives in `playbook.yml`'s `vars:` block (the real-run entrypoint) — never in `group_vars`, a `set_fact` in `tasks/main.yml`, or inline in a template. `tasks/main.yml` and templates only ever reference the resulting plain variables. This keeps Molecule's `converge.yml` (which imports `tasks/main.yml` directly, not `playbook.yml`) off the 1Password code path entirely — it stubs the same variable names with fake values instead of ever calling the lookup.

Note: the 1Password Connect service in `kubenuc` is `serviceType: NodePort` — confirm it's actually reachable from wherever `ansible-playbook` runs for real (the `ansible-agent` container, or a self-hosted runner) before relying on this pattern; it is not a given (confirmed reachable from both a laptop and the self-hosted runner as of the `teleport-server` role's introduction).

---

## SOPS for Inventory Connection Details

`teleport-client` and `teleport-server` commit real `ansible_host` values (VM IPs/hostnames) to git, encrypted with SOPS/age rather than left as plaintext or as the never-committed placeholder token `pve-monitoring` uses. This is a narrower, distinct mechanism from [1Password via Ansible (Connect)](#1password-via-ansible-connect) above — know which one applies:

| | SOPS (`community.sops`) | 1Password Connect |
|---|---|---|
| Scope | Connection-level: where to SSH (`ansible_host`) | Service-level: join tokens, proxy FQDN, ACME email |
| Lives in | `host_vars/<hostname>.sops.yaml` per host | `playbook.yml` `vars:` lookup, fetched at run time |
| Why | Matches this repo's existing SOPS pattern (`cluster-vars.sops.yaml`, `terraform/*/secrets.sops.yaml`) for "real value, must be in git, must not be plaintext" | Already-established secrets store; not duplicated for connection data |

Do not blend the two — new service secrets go through 1Password Connect, not SOPS; new connection/inventory values for other roles follow this SOPS pattern, not a new placeholder-token convention.

**Key**: a single age keypair scoped to all of `ansible/**` (`.sops.yaml` root, `path_regex: ansible/.*\.sops\.(yaml|yml|json)$`), following this repo's one-keypair-per-stack convention. Broader than the per-cluster keys elsewhere in `.sops.yaml`, acceptable because content under this key is limited to low-sensitivity connection data (IPs/hostnames) — don't let scope creep past that without reconsidering a split. Unlike `OP_CONNECT_TOKEN`, this key can't be rotated cheaply: rotation means re-encrypting every file under it.

**`vars_plugins_enabled` gotcha**: this setting *replaces* Ansible's default vars plugin list, it does not append to it. It must always be `host_group_vars, community.sops.sops` — dropping `host_group_vars` silently breaks loading of plain (non-SOPS) `group_vars`/`host_vars` files. Set two ways for redundancy:
- **Primary** (cwd-independent): `ANSIBLE_VARS_ENABLED=host_group_vars,community.sops.sops` env var on the `ansible-agent` service in `docker/agents/docker-compose.yml`.
- **Belt-and-suspenders**: `ansible.cfg` in each role directory. Only takes effect if `ansible-playbook` is invoked with that exact directory as cwd — harmless when redundant with the env var, but it's why the env var is primary and not the other way around.

**Local (non-container) prerequisites**: `ANSIBLE_VARS_ENABLED` is only set inside the `ansible-agent` container. Running these playbooks with a local Ansible install requires: `ansible-galaxy collection install community.sops`, the real `sops` binary in `PATH`, the same `vars_plugins_enabled` setting (covered by each role's `ansible.cfg` as long as cwd matches), and either `SOPS_AGE_KEY_FILE` set or the key appended to SOPS's own default lookup path `~/.config/sops/age/keys.txt`.

**NetBox/Terraform remains the IP source of truth.** These `host_vars/*.sops.yaml` files are a manual mirror with no automated drift check against `terraform/netbox/secrets.sops.yaml` (a different age key). If a host's real address changes, update both by hand.

**`:ro` mount**: `docker/agents/docker-compose.yml` mounts `ansible/` read-only into the container, so `sops edit`/re-encryption of these files must happen host-side (real `sops` binary + `SOPS_AGE_KEY_FILE` on your machine), never inside `ansible-agent`.

**Manual version pins, not Renovate-tracked**: `SOPS_VERSION` in `docker/agents/ansible/Dockerfile` and the `community.sops` collection version are both unmanaged by Renovate (same as `teleport_version` above). Re-pin explicitly if either needs a bump.

**`ansible/.ansible-lint`**: excludes `*/host_vars/*.sops.yaml` from `yaml[line-length]` — SOPS's MAC/age-recipient lines are long ciphertext, not authored YAML, and there's nothing to reformat. This is the first `.ansible-lint` config in the repo; keep it scoped to this one exclusion rather than growing it into a general lint-suppression file.

---

## Gotchas

**Teleport's `rpm.releases.teleport.dev/teleport.repo` is a stale legacy repo** — it resolves and looks valid (200, well-formed `.repo` file) but is frozen at v14.x (see `gravitational/teleport#20978`). The current repo needs the full per-distro/arch/channel path: `https://yum.releases.teleport.dev/rhel/<major-version>/Teleport/<arch>/stable/v<major>/teleport.repo` — use `rhel` literally for all RHEL-family distros (RHEL/Rocky/Oracle/Alma), not the distro's own `/etc/os-release` `ID`. Found by testing the install for real in Molecule, not from documentation alone — a repo file 200'ing is not evidence it carries current packages.

**`docker/agents/ansible/Dockerfile` pinned `ansible==10.*`**, which installs ansible-core 2.17 — incompatible with the image's Python 3.14 base (`ansible-compat` requires ansible-core >= 2.20 there) and broke `molecule`/`ansible-lint` from even starting. Fixed by unpinning to latest `ansible`. If this recurs after a Renovate-style bump, re-pin explicitly rather than leaving the image broken.
