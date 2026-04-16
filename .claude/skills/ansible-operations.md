---
name: ansible-operations
description: Ansible playbook/role conventions, Molecule testing patterns, and ansible-agent invocation for the infra-cd repository.
when_to_invoke: Any edit under ansible/ — new playbook, new role, task modifications, template changes, or adding a new playbook directory.
---

# Ansible Operations

## Hard rule: Molecule is mandatory

**Every** playbook or role directory under `ansible/` MUST ship a Molecule scenario before merging. No exceptions.

Required structure for each playbook directory:

```
ansible/{playbook-name}/
├── playbook.yml              # thin wrapper: import_tasks + import handlers
├── tasks/main.yml            # all tasks extracted here (reusable by Molecule)
├── handlers/main.yml         # all handlers extracted here
├── group_vars/               # non-secret defaults
├── templates/                # Jinja2 templates
├── inventory.yml             # production inventory
└── molecule/
    └── default/
        ├── molecule.yml      # docker driver + platform config
        ├── converge.yml      # stub secrets + import_tasks ../../tasks/main.yml
        └── verify.yml        # assertions (files, permissions, packages, service enabled)
```

PRs that add or modify tasks without a Molecule scenario should not be approved.

---

## Canonical examples

| Playbook | Molecule location | Notes |
|---|---|---|
| `ansible/falco/` | `ansible/falco/molecule/default/` | Simple pattern, no systemd services started |
| `ansible/pve-monitoring/` | `ansible/pve-monitoring/molecule/default/` | Full systemd pattern (pve-exporter + alloy) |
| `ansible/iredmail/iredapd/` | `ansible/iredmail/iredapd/molecule/default/` | Service-specific scenario |

---

## Molecule scenario template

### `molecule/default/molecule.yml`

```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: {playbook-name}-test
    image: geerlingguy/docker-debian12-ansible:latest
    pre_build_image: true
    privileged: true
    command: /lib/systemd/systemd
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    tmpfs:
      - /run
      - /tmp
provisioner:
  name: ansible
  playbooks:
    converge: converge.yml
  inventory:
    host_vars:
      {playbook-name}-test:
        ansible_python_interpreter: /usr/bin/python3
        # add any host_vars that normally live in inventory.yml
verifier:
  name: ansible
```

**Always use** `geerlingguy/docker-debian12-ansible:latest` as the test image — it has systemd, Python, and common Ansible prerequisites pre-installed. Use `privileged: true` + `cgroupns_mode: host` + cgroup volume whenever the play manages `ansible.builtin.systemd`.

### `molecule/default/converge.yml`

```yaml
---
- name: Converge
  hosts: all
  become: true
  gather_facts: true

  vars:
    # Template base dir — templates/ is at playbook root, two levels up from molecule/default/
    pve_templates_dir: "{{ playbook_dir }}/../../templates"
    # Stub secrets — never use real values in Molecule
    secret_var: "test-stub-value"

  vars_files:
    - ../../group_vars/{group}.yml   # load non-secret defaults

  tasks:
    - name: Run tasks
      ansible.builtin.import_tasks: ../../tasks/main.yml

  handlers:
    - import_tasks: ../../handlers/main.yml
```

Key rules:
- **Never** reference real secrets — use clearly fake stubs.
- **Always** load `group_vars/*.yml` via `vars_files` so defaults match production.
- Use `import_tasks` (static, not `include_tasks`) for full idempotency checking.
- **Template path resolution**: `ansible.builtin.template` resolves `src:` relative to the invoking playbook's directory, not the tasks file. Use a `{playbook}_templates_dir` variable in `tasks/main.yml` and set it to `{{ playbook_dir }}/templates` in `playbook.yml` and `{{ playbook_dir }}/../../templates` in `converge.yml`.

### `molecule/default/verify.yml`

```yaml
---
- name: Verify {playbook-name} installation
  hosts: all
  become: true
  gather_facts: false

  tasks:
    - name: Check config file exists
      ansible.builtin.stat:
        path: /path/to/config
      register: config_file

    - name: Assert config file is present
      ansible.builtin.assert:
        that: config_file.stat.exists

    - name: Check package is installed
      ansible.builtin.package_facts:
        manager: apt

    - name: Assert package is installed
      ansible.builtin.assert:
        that: "'package-name' in ansible_facts.packages"

    - name: Check service is enabled
      ansible.builtin.systemd:
        name: service-name
      register: svc_info

    - name: Assert service is enabled
      ansible.builtin.assert:
        that: svc_info.status.UnitFileState == "enabled"
```

Verify **file existence + permissions**, **package installation**, and **service enabled state**. Do NOT assert `active` service state — services that depend on external infrastructure (PVE, Grafana, databases) will not actually connect in test containers.

---

## Running Molecule via ansible-agent

The `ansible-agent` container has `molecule`, `molecule-plugins[docker]`, and Docker CLI pre-installed. The host Docker socket is mounted, so Molecule manages test containers from inside the agent.

```bash
# Start the agent (once per session)
cd /path/to/infra-cd/docker/agents
docker compose up -d ansible-agent

# Full test run (recommended before every PR)
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent \
  molecule test

# Step-by-step (during development)
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule create
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule converge
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule verify
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule idempotence
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule destroy

# Login to test container for debugging
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent \
  molecule login

# Clean slate after a failed run
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule destroy
```

`molecule test` runs the full sequence: dependency → lint → cleanup → destroy → syntax → create → prepare → converge → **idempotence** → side_effect → verify → cleanup → destroy.

The **idempotence** step re-runs converge and asserts zero changed tasks. This is often the hardest to pass — common causes:
- `ansible.builtin.shell` without `creates:` or `changed_when: false`
- `apt` with `state: latest` (use `state: present` + pinned version)
- `lineinfile` with `create: true` (first run creates file → second run is idempotent, OK)

---

## Claude-driven iteration workflow

When tests fail, the iteration pattern is:

1. Run `molecule test`, capture full output.
2. Identify the failing step (converge / idempotency / verify).
3. Edit the task file (`tasks/main.yml`) or scenario file (`molecule/default/{converge,verify}.yml`).
4. If the container state is dirty after a crash, run `molecule destroy` first.
5. Re-run `molecule test`. Cap at 8 iterations; surface root cause to user if still failing.

---

## Secrets in tests

- Set stub values as plain vars inside `converge.yml` (`vars:` block).
- Never import from 1Password, vault files, or external sources during Molecule runs.
- If a template renders a URL/credential that gets validated at runtime (e.g., `curl` to Grafana), mock with a valid-format fake URL — the service won't connect, but the template renders.

---

## CI integration (future)

Molecule is not yet wired into GitHub Actions. Until it is, scenarios **must** pass locally (via `ansible-agent`) before merge. Track this as follow-up work.

---

## Linting

```bash
# Lint before Molecule (ansible-agent has ansible-lint installed)
docker compose exec ansible-agent ansible-lint /workspace/ansible/{playbook-name}/playbook.yml
```
