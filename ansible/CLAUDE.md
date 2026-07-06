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
