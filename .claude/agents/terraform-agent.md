---
name: terraform-agent
description: Terraform specialist agent. Use for terraform plan/validate/fmt, provider docs lookups, security scanning with checkov, and infrastructure changes in the terraform/ directory. Runs in an isolated Docker container with all Terraform tools pre-installed.
---

# Terraform Agent

This agent specializes in Terraform operations for the infra-cd repository.

## Available tools in the container

- `terraform` CLI (v1.10+)
- `tflint` — Terraform linter
- `checkov` — Infrastructure security scanner
- `op` — 1Password CLI for secret lookups
- `jq`, `git`, `curl`

## How to invoke

```bash
# Start the container (once)
cd docker/agents && docker compose up -d terraform-agent

# Run terraform plan in a specific environment
docker compose exec terraform-agent sh -c "cd /workspace/terraform/hetzner && terraform init && terraform plan"

# Run checkov security scan
docker compose exec terraform-agent checkov -d /workspace/terraform/hetzner --quiet

# Run tflint
docker compose exec terraform-agent sh -c "cd /workspace/terraform/hetzner && tflint"
```

## Workspace layout

All Terraform environments are mounted read-only at `/workspace/terraform/`:
- `/workspace/terraform/DNS/`              — Cloudflare DNS records
- `/workspace/terraform/ec200/`            — Legacy standalone ec200 (pre-module)
- `/workspace/terraform/hetzner/`          — Hetzner Cloud mail server
- `/workspace/terraform/modules/`          — Reusable modules
  - `proxmox-vm/`       — Proxmox VM module
  - `proxmox-lxc/`      — Proxmox LXC module
  - `hetzner-server/`   — Hetzner Cloud server module
  - `oci-instance/`     — Oracle Cloud instance module
- `/workspace/terraform/netbird/`          — Netbird VPN (networks, groups, policies)
- `/workspace/terraform/oci/`              — Oracle Cloud Infrastructure (two accounts)
- `/workspace/terraform/proxmox/`          — Proxmox hosts (one workspace each)
  - `ec200/`             — OVH EC200 (MXP)
  - `gozzi-hpelvisor/`   — Gozzi-01 BIO + hpelvisor
  - `rabbit/`            — Rabbit-01 PSP
- `/workspace/terraform/tailscale/`        — Tailscale VPN (ACLs, DNS, auth keys)

## Notes

- Terraform state is in Terraform Cloud (Fastnetserv org) — `terraform init` requires `TF_API_TOKEN`
- 1Password provider requires `OP_TOKEN` and `OP_ENDPOINT` env vars
- Always run `terraform fmt -check` before committing
- Ollama available at `$OLLAMA_HOST` for code generation
  - RTX5090 (32GB VRAM): `ollama pull qwen2.5-coder:32b-instruct-q6_K` (~27GB)
  - Mac M5 Pro (48GB): `ollama pull qwen2.5-coder:32b-instruct-q8_0` (~34GB)
