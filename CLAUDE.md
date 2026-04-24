# CLAUDE.md — AI Assistant Guide for infra-cd

This file provides context for AI assistants (Claude Code and similar) working in this repository. It covers the codebase structure, development workflows, conventions, and key rules to follow.

---

## Repository Overview

`infra-cd` is a **production-grade GitOps infrastructure-as-code repository** managing:

- Multiple Kubernetes clusters across on-premises and cloud providers
- Terraform-managed cloud infrastructure (Hetzner, OCI, Proxmox, OVH)
- Continuous deployment via FluxCD v2
- Ansible automation for OS-level configuration
- Automated dependency management via Renovate

The repository follows strict GitOps principles: **changes to this repository drive infrastructure state**. Handle all modifications carefully.

---

## Directory Structure

```
infra-cd/
├── .github/workflows/      # GitHub Actions CI/CD pipelines
├── .claude/                # Claude Code configuration and permissions
├── ansible/                # Ansible playbooks for OS automation
│   ├── falco/              # Falco host-level security (Debian 12/13)
│   ├── iredmail/           # Mail server configuration
│   └── ansible-os-updates/ # OS patching (git submodule)
├── apps/                   # Shared application definitions
├── charts/                 # Helm chart repository references
├── clusters/               # Kubernetes cluster configs (FluxCD/Kustomize)
│   ├── kubenuc/            # Primary production cluster (3 CP + 3 workers)
│   ├── kubenuc-test/       # Test cluster
│   ├── k3s-prod-test/      # K3s production-test cluster
│   ├── k3s-rabbit/         # K3s Rabbit cluster
│   ├── k8s-vms-daniele/    # VM-based Kubernetes
│   ├── oc-ampere/          # OpenShift Ampere cluster
│   └── common/             # Shared configurations across clusters
├── portainer/              # Docker Compose configs for Portainer
├── scripts/                # Utility shell scripts
│   └── test-kind-flux-local.sh  # Local Kind+FluxCD test script
├── terraform/              # Infrastructure-as-Code
│   ├── DNS/                # DNS records management
│   ├── ec200/              # Legacy standalone ec200 (pre-module)
│   ├── hetzner/            # Hetzner Cloud servers
│   ├── netbird/            # Netbird VPN (networks, groups, policies)
│   ├── oci/                # Oracle Cloud Infrastructure (two accounts)
│   ├── tailscale/          # Tailscale VPN (ACLs, DNS, auth keys)
│   ├── modules/            # Reusable Terraform modules (proxmox-vm, proxmox-lxc, hetzner-server, oci-instance)
│   └── proxmox/            # Proxmox-managed infra, one workspace per host
│       ├── ec200/          # OVH EC200 (Proxmox host, MXP workspace)
│       ├── gozzi-hpelvisor/# Gozzi-01 BIO + hpelvisor Proxmox hosts
│       └── rabbit/         # Rabbit-01 PSP Proxmox host
├── tests/
│   └── robot/              # Robot Framework E2E tests
├── .pre-commit-config.yaml # Pre-commit hooks
├── .gitignore
├── .gitmodules             # Submodule: ansible-os-updates
├── renovate.json           # Automated dependency update config
└── README.md               # Hardware inventory and cluster overview
```

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

## Kubernetes Clusters

| Cluster | Type | Purpose |
|---|---|---|
| `kubenuc` | Bare metal (HP ProLiant) | Primary production — 3 control plane + 3 workers |
| `kubenuc-test` | Bare metal | Pre-production testing |
| `k3s-prod-test` | k3s | Production-like test environment |
| `k3s-rabbit` | k3s | Rabbit server cluster |
| `k8s-vms-daniele` | VMs | Development cluster |
| `oc-ampere` | OpenShift | Ampere ARM-based cluster |

---

## Cluster Configuration Conventions

Each cluster under `clusters/{cluster-name}/` follows this structure:

```
clusters/{cluster-name}/
├── flux-system/            # FluxCD bootstrap and Kustomization
├── apps.yaml               # Top-level app Kustomization
├── charts.yaml             # HelmRepository Kustomization
└── apps/
    └── {app-name}/
        ├── deploy.yaml     # HelmRelease or Kustomization manifest
        ├── secrets/        # 1Password-backed SecretStore/ExternalSecret
        └── manifests/      # Additional raw Kubernetes manifests
```

**Key conventions:**
- Each application lives in its own directory under `apps/`
- Dependencies are declared explicitly in Kustomization `.spec.dependsOn`
- Common pattern: storage (OpenEBS) → database (PostgreSQL) → application
- Sync intervals vary by component: `5m` for apps, `15m` for charts
- All secrets use 1Password ExternalSecrets — **never commit raw secrets**

---

## Terraform Conventions

- **State backend:** Terraform Cloud (organization: `Fastnetserv`)
- **Required providers:** Hetzner Cloud, OCI, Proxmox (`~> 0.100`), 1Password (`~> 3`)
- **Format:** Always run `terraform fmt` before committing
- CI will reject PRs with unformatted Terraform files
- Each `terraform/{environment}/` (or `terraform/proxmox/{host}/`) is independent with its own backend config
- Reusable modules under `terraform/modules/`: `proxmox-vm`, `proxmox-lxc`, `hetzner-server`, `cloudflare-dns`
- Sensitive values are sourced from 1Password provider — never hardcoded
- Do not hand-pin provider versions managed by Renovate

**CI workflow per Terraform directory:**
1. `terraform fmt -check` (PR)
2. `terraform init` (PR)
3. `terraform validate` (PR)
4. `terraform plan` (PR — result posted as PR comment)
5. `terraform apply` (main branch only)

---

## GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `terraform.yml` | PR/push to `terraform/hetzner/` | Hetzner infrastructure |
| `terraform-bio.yml` | PR/push to `terraform/proxmox/gozzi-hpelvisor/` | Gozzi-01 BIO + hpelvisor Proxmox hosts |
| `terraform-mxp.yml` | PR/push to `terraform/proxmox/ec200/` | OVH EC200 (MXP) Proxmox host |
| `terraform-psp.yml` | PR/push to `terraform/proxmox/rabbit/` | Rabbit-01 PSP Proxmox host |
| `validate-kubenuc.yml` | PR | Full cluster E2E validation (2h timeout) |
| `validate-k8s-vms.yml` | PR | K8s VMs cluster validation |
| `flux-cron.yml` | Mondays 3 AM (+ manual) | Weekly FluxCD component updates |

**Required GitHub Actions secrets:**
- `ANTHROPIC_API_KEY` — Claude API key
- `GITHUB_TOKEN` — GitHub Actions token
- `TF_API_TOKEN` — Terraform Cloud token
- `OP_TOKEN` — 1Password Connect token
- `OP_ENDPOINT` — 1Password Connect endpoint
- `PUB_KEY` — SSH public key for provisioned servers

---

## Testing

### Local Testing (Kind + FluxCD)

```bash
./scripts/test-kind-flux-local.sh
```

Prerequisites: `kind`, `kubectl`, `flux` CLI installed.

The script:
1. Creates a Kind cluster
2. Installs FluxCD
3. Validates cluster health
4. Auto-cleans up on completion

### CI Testing

PR validation uses k3s (v1.33.3+k3s1) and Flux CD v2.7.5 with a 2-hour timeout. Robot Framework runs E2E tests via `tests/robot/robot-test-job.yaml`.

### Pre-commit Hooks

Enabled via `.pre-commit-config.yaml`:
- Trailing whitespace removal
- End-of-file newline fixer
- YAML syntax validation (multi-document aware)
- Large file detection

Run manually: `pre-commit run --all-files`

---

## Secrets Management

This repository uses **1Password** for all secrets:

- **Kubernetes secrets:** 1Password Operator syncs secrets as Kubernetes `Secret` resources via `OnePasswordItem` CRDs
- **Terraform secrets:** 1Password Terraform provider reads secrets at plan/apply time
- **CI secrets:** Stored as GitHub Actions repository secrets

**Never:**
- Commit `.env` files, plaintext credentials, or Kubernetes `Secret` manifests with base64-encoded values
- Add TLS certificates, SSH private keys, or tokens to git

**Always:**
- Reference secrets via `OnePasswordItem` CRDs or `ExternalSecret` resources
- Store new secrets in 1Password first, then reference by path

---

## Observability & Alerting

### BetterStack bridge (Nextcloud maintenance)

A small Python webhook deployed in `flux-system` pauses the BetterStack uptime monitor for Nextcloud while a Flux-driven upgrade is in progress, avoiding false downtime alerts.

- **Files:**
  - `clusters/kubenuc/apps/fluxcd/betterstack-bridge.yaml` — ConfigMap (code) + Deployment + Service
  - `clusters/kubenuc/apps/fluxcd/notifications.yaml` — Flux `Provider` (`betterstack-bridge`) + `Alert` (`nextcloud-maintenance`)
- **Pause triggers:** `DependencyNotReady` on `Kustomization/nextcloud` (primary — fires when kustomize-controller's healthCheck fails because the HelmRelease is upgrading, covers values-only digest bumps; does NOT fire on no-op 15m reconcile cycles); plus `DriftDetected` on `HelmRelease/nextcloud` and `ChartPullSucceeded` on `HelmChart/nextcloud-fastnetserv-nextcloud` (chart-version upgrades / manual drift).
- **Unpause triggers:** any terminal HelmRelease reason (`UpgradeSucceeded`, `UpgradeFailed`, `InstallSucceeded`, `RollbackSucceeded`, etc.), or `ReconciliationSucceeded`/`ReconciliationFailed` on `Kustomization/nextcloud` (fast unpause for no-op reconcile cycles where no real upgrade runs).
- **Debug:** set `DEBUG_EVENTS=1` on the Deployment to log every raw event payload. All bridge logs are timestamped (ISO8601 UTC).
- **Secret:** 1Password item `betterstack-token` with fields `token` and `monitor-id`, synced via `OnePasswordItem`.

---

## Dependency Management (Renovate)

`renovate.json` configures automated dependency updates with semantic versioning:

- `chore(deps):` — General dependency updates
- `feat(flux):` — FluxCD major version updates
- `fix(security):` — Security patch updates

Renovate auto-creates PRs for:
- Helm chart version bumps in HelmRelease manifests
- FluxCD component updates
- Terraform provider version bumps
- GitHub Actions runner versions

Do not manually pin versions that Renovate manages — let it handle updates.

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

## Git workflow
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

---

## Common Tasks

### Add a new application to a cluster

1. Create `clusters/{cluster}/apps/{app-name}/deploy.yaml` with a `HelmRelease` or `Kustomization`
2. Add secrets under `clusters/{cluster}/apps/{app-name}/secrets/` using `OnePasswordItem` CRDs
3. Add `dependsOn` if the app requires storage or a database
4. Reference the new directory in `clusters/{cluster}/apps.yaml` Kustomization

### Add a new Helm repository

1. Add a `HelmRepository` manifest under `clusters/{cluster}/charts/`
2. Reference it in `clusters/{cluster}/charts.yaml`
3. Use the repository source in `HelmRelease` specs via `sourceRef`

### Add a new Terraform environment

1. Create `terraform/{environment}/` with `provider.tf`, `main.tf`, `variables.tf`
2. Configure a Terraform Cloud workspace for the new environment
3. Add a corresponding GitHub Actions workflow in `.github/workflows/`

### Update FluxCD components

Handled automatically by the `flux-cron.yml` workflow (Mondays 3 AM) or triggered manually via GitHub Actions. Do not manually edit `clusters/{cluster}/flux-system/` files unless fixing a bootstrap issue.

---

## Infrastructure Overview

Hardware managed by this repository (from README.md):

- **kubenuc**: HP ProLiant MicroServer Gen10 Plus — production Kubernetes cluster
- **Hetzner VPS**: Multiple instances across CX/CPX tiers
- **OCI Ampere**: Oracle Cloud ARM-based instances
- **OVH EC200**: EC200 dedicated server
- Additional on-premises nodes across Prague, Bergamo, Zurich, Mexico locations

---

## Skills & Agents Architecture

Claude Code uses a layered approach for domain-specific operations in this repository:

### Skills (`.claude/skills/`)

Skills provide repository-specific patterns and conventions as quick-reference guides. Invoke them when working in their domain:

| Skill | Domain |
|---|---|
| `flux-operations` | Add/update FluxCD apps, HelmRepositories, SOPS vars, dependsOn chains |
| `terraform-operations` | New TF environments, modules, CI workflows, renovate config |
| `secrets-management` | 1Password Operator, ExternalSecret, SOPS age encryption |
| `cluster-operations` | New clusters, kubenuc-test overlay pattern, kustomize patches |
| `ci-workflows` | GitHub Actions templates, runner selection, required secrets |

### Agents (`.claude/agents/`)

Agents are Docker containers for executing operations. They support local Ollama models to minimize API usage:

| Agent | Purpose | Ollama use |
|---|---|---|
| `kubernetes-agent` | kubectl, helm, kustomize, flux CLI | YAML/manifest generation |
| `terraform-agent` | terraform, tflint, checkov, 1Password CLI | HCL generation |
| `ansible-agent` | ansible, ansible-lint, community collections | Playbook generation |

**Hybrid model strategy:** Use Ollama (local) for routine boilerplate generation (YAML manifests, HCL resources). Use Claude Code API for complex reasoning (dependency analysis, security review, multi-file refactors).

### Starting agents

```bash
cd docker/agents
docker compose up -d          # Start all agents
docker compose up -d terraform-agent kubernetes-agent  # Start specific agents
```

Set `OLLAMA_HOST` in `docker/agents/.env` to point to your Ollama instance.

---

## Getting Started

```bash
# Clone with submodules
git clone --recurse-submodules <repo-url>
cd infra-cd

# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Validate YAML
pre-commit run --all-files

# Run local cluster tests
./scripts/test-kind-flux-local.sh

# Terraform (example: hetzner)
cd terraform/hetzner
terraform init
terraform plan
```
