# CLAUDE.md — AI Assistant Guide for infra-cd

`infra-cd` is a **production-grade GitOps infrastructure-as-code repository** managing multiple Kubernetes clusters, Terraform-managed cloud infrastructure (Hetzner, OCI, Proxmox, OVH), FluxCD v2 continuous deployment, Ansible automation, and automated dependency management via Renovate. **Changes to this repository drive infrastructure state** — handle all modifications carefully.

---

## Technology Stack

| Layer | Technology |
|---|---|
| GitOps/CD | FluxCD v2 |
| K8s packaging | Helm + Kustomize |
| IaC | Terraform (Cloud state in Fastnetserv org) |
| Config management | Ansible |
| Secrets | 1Password Secrets Automation + 1Password Operator |
| CI/CD | GitHub Actions (self-hosted runners) |
| Image builds | Packer |
| Dependency updates | Renovate |
| Testing | Robot Framework + KinD + k3s |
| Storage | OpenEBS, Longhorn |
| Database | PostgreSQL (Zalando operator) |

---

## Secrets Management

This repository uses **1Password** for all secrets:

- **Kubernetes secrets:** 1Password Operator syncs secrets as Kubernetes `Secret` resources via `OnePasswordItem` CRDs
- **Terraform secrets:** 1Password Terraform provider reads secrets at plan/apply time
- **CI secrets:** Stored as GitHub Actions repository secrets

**Never:**
- Commit `.env` files, plaintext credentials, or Kubernetes `Secret` manifests with base64-encoded values
- Add TLS certificates, SSH private keys, or tokens to git
- Hardcode hostnames, FQDNs, or internal service URLs — these are treated as sensitive infrastructure details regardless of whether they appear to be "just configuration"

**Always:**
- Reference secrets via `OnePasswordItem` CRDs or `ExternalSecret` resources
- Store new secrets in 1Password first, then reference by path
- Store server URLs and FQDNs in 1Password alongside credentials (e.g. use `.url` or `.hostname` from a `onepassword_item` data source in Terraform, or a `OnePasswordItem` field in Kubernetes)

---

## Claude Code MCP Servers

The project-scoped `.mcp.json` at the repo root configures Graylog, Grafana, and NetBox MCP servers for observability/troubleshooting and infra-inventory lookups. It references credentials via env vars only (`${GRAYLOG_MCP_TOKEN}`, `${GRAFANA_URL}`, `${GRAFANA_API_KEY}`, `${NETBOX_URL}`, `${NETBOX_TOKEN}`) — no tokens are committed. See the README's "Claude Code MCP Setup" section for how to export them from 1Password before starting a session. NetBox access through this MCP is **read-only** by convention — inventory writes always go through `terraform/netbox/*.tf` PRs, never a direct MCP write (see the `documentation` skill).

---

## Commit Message Conventions

Follow semantic commit format (consistent with Renovate and existing history):

```
<type>(<scope>): <description>

# Examples:
chore(deps): update helm release harbor to v24.1.0
feat(kubenuc): add nextcloud application
fix(terraform): correct hetzner server region
docs: update CLAUDE.md with cluster conventions
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

---

## Git Workflow

**Never push directly to `main`.** The branch has a PR rule — always create a feature branch and open a pull request. Never bypass the rule.

---

## Key Rules for AI Assistants

1. **GitOps is the source of truth** — all cluster state changes must go through git, never `kubectl apply` directly in production
2. **Never commit secrets** — use 1Password references only
3. **Run `terraform fmt`** before any Terraform commit
4. **Respect `dependsOn` chains** — storage → database → application ordering is intentional
5. **YAML validation** — all YAML must pass `yamllint`; pre-commit enforces this
6. **Renovate owns versions** — do not manually edit chart versions managed by Renovate unless fixing a break
7. **Per-cluster isolation** — changes to one cluster's directory should not affect others
8. **Sync intervals** — do not reduce sync intervals below `5m` without a documented reason
9. **Self-hosted runners** — Terraform workflows run on self-hosted runners; ensure runner availability before expecting CI to pass
10. **Submodule awareness** — `ansible/ansible-os-updates` is a git submodule; use `git submodule update --init` after cloning
11. **Document before opening the PR** — before opening a PR for a structural infra change, a new app/cluster, an incident fix, a security-hardening trade-off, or a version-pin rationale, decide whether README.md, a CLAUDE.md, or Confluence needs updating — route the decision through the `documentation` skill

---

## Path-Specific Conventions

Detailed conventions are in nested `CLAUDE.md` files, auto-loaded when working in those directories:

- `clusters/CLAUDE.md` — Kubernetes clusters, FluxCD conventions, cluster CI workflows
- `clusters/kubenuc/CLAUDE.md` — BetterStack bridge (Nextcloud maintenance alerting)
- `terraform/CLAUDE.md` — Terraform conventions, provider patterns, CI workflows
- `ansible/CLAUDE.md` — Ansible conventions, Molecule testing requirements
