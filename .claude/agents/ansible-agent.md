---
name: ansible-agent
description: Ansible specialist agent. Use for running Ansible playbooks, linting, inventory management, and OS/device configuration tasks. Runs in an isolated Docker container with Ansible and common collections installed. Replaces AWX for ad-hoc automation tasks.
---

# Ansible Agent

This agent specializes in Ansible automation for the infra-cd repository, replacing AWX for ad-hoc tasks.

## Available tools in the container

- `ansible` (v10.x)
- `ansible-playbook`, `ansible-lint`, `ansible-inventory`
- `molecule`, `molecule-plugins[docker]` (Docker driver, host socket mounted)
- Collections: `community.general`, `community.postgresql`, `ansible.posix`, `kubernetes.core`
- `paramiko` (Python SSH library)
- SSH client with host key checking disabled

## How to invoke

```bash
# Start the container (once)
cd docker/agents && docker compose up -d ansible-agent

# Run a playbook
docker compose exec ansible-agent ansible-playbook \
  -i /workspace/ansible/inventory \
  /workspace/ansible/iredmail/deploy/iredmail.yml

# Lint a playbook
docker compose exec ansible-agent ansible-lint /workspace/ansible/iredmail/deploy/iredmail.yml

# Check inventory
docker compose exec ansible-agent ansible-inventory -i /workspace/ansible/inventory --list

# Dry run (check mode)
docker compose exec ansible-agent ansible-playbook \
  -i /workspace/ansible/inventory \
  /workspace/ansible/iredmail/deploy/iredmail.yml \
  --check --diff
```

## Workspace layout

Ansible files mounted read-only at `/workspace/ansible/`:
- `/workspace/ansible/inventory` — host groups: [web], [docker], [k8s], [hzmail], [falco]
- `/workspace/ansible/iredmail/` — iRedMail deployment playbooks
- `/workspace/ansible/falco/` — Falco host-level security deployment (Debian 12/13)
- SSH keys from host `~/.ssh/` available for connections

## Migration from AWX

| AWX feature | Ansible Agent equivalent |
|-------------|--------------------------|
| Job Templates | `ansible-playbook` in container |
| Inventories | `/workspace/ansible/inventory` |
| Scheduling | GitHub Actions cron or Claude Code `/schedule` skill |
| Web UI | Use Semaphore UI (see `clusters/k8s-vms-daniele/apps/semaphore/`) |

## Molecule testing

Run Molecule scenarios from inside the agent (Docker-in-Docker via host socket):

```bash
# Full test run — run this before every PR
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule test

# Step by step
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule create
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule converge
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule idempotence
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule verify
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule destroy

# Clean up a crashed scenario before retrying
docker compose exec -w /workspace/ansible/{playbook-name} ansible-agent molecule destroy
```

Molecule state files go to `MOLECULE_EPHEMERAL_DIRECTORY=/tmp/molecule` (inside the agent container), so the mounted workspace stays clean.

See `.claude/skills/ansible-operations.md` for the full Molecule pattern, scenario templates, and iteration workflow.

## Notes

- SSH agent forwarded from host via `SSH_AUTH_SOCK`
- For scheduled runs, use the `/schedule` skill in Claude Code or GitHub Actions workflows
- Ollama available at `$OLLAMA_HOST` for playbook generation
  - RTX5090 (32GB VRAM): `ollama pull qwen2.5-coder:32b-instruct-q6_K` (~27GB)
  - Mac M5 Pro (48GB): `ollama pull qwen2.5-coder:32b-instruct-q8_0` (~34GB)
