---
name: ansible-agent
description: Ansible specialist agent. Use for running Ansible playbooks, linting, inventory management, and OS/device configuration tasks. Runs in an isolated Docker container with Ansible and common collections installed. Replaces AWX for ad-hoc automation tasks.
---

# Ansible Agent

This agent specializes in Ansible automation for the infra-cd repository, replacing AWX for ad-hoc tasks.

## Available tools in the container

- `ansible` (v10.x)
- `ansible-playbook`, `ansible-lint`, `ansible-inventory`
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
- `/workspace/ansible/inventory` — host groups: [web], [docker], [k8s], [hzmail]
- `/workspace/ansible/iredmail/` — iRedMail deployment playbooks
- SSH keys from host `~/.ssh/` available for connections

## Migration from AWX

| AWX feature | Ansible Agent equivalent |
|-------------|--------------------------|
| Job Templates | `ansible-playbook` in container |
| Inventories | `/workspace/ansible/inventory` |
| Scheduling | GitHub Actions cron or Claude Code `/schedule` skill |
| Web UI | Use Semaphore UI (see `clusters/k8s-vms-daniele/apps/semaphore/`) |

## Notes

- SSH agent forwarded from host via `SSH_AUTH_SOCK`
- For scheduled runs, use the `/schedule` skill in Claude Code or GitHub Actions workflows
- Ollama available at `$OLLAMA_HOST` for playbook generation (recommended: `qwen2.5-coder:7b` locally on Mac)
