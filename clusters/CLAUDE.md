# Clusters — Conventions & Recipes

## Kubernetes Clusters

| Cluster | Type | Purpose | Flux bootstrap |
|---|---|---|---|
| `kubenuc` | Bare metal (HP ProLiant) | Primary production — 3 control plane + 3 workers | Flux Operator (`FluxInstance`) |
| `kubenuc-test` | Bare metal | Pre-production testing, overlays `kubenuc` manifests | Legacy classic bootstrap (`flux-system/`) |
| `k3s-prod-test` | k3s | Production-like test environment, independent manifests | Legacy classic bootstrap (`flux-system/`) |
| `k3s-rabbit` | k3s | Rabbit server cluster | Flux Operator (`FluxInstance`) |
| `k8s-vms-daniele` | VMs | Development cluster | Flux Operator (`FluxInstance`) |
| `oc-ampere` | k3s (OCI, ARM/Ampere) | Teleport agent only | Flux Operator (`FluxInstance`) |

---

## Cluster Configuration Conventions

Four of the six clusters (`kubenuc`, `k3s-rabbit`, `k8s-vms-daniele`, `oc-ampere`) are managed by the **Flux Operator** via a `FluxInstance` custom resource — there is no `flux-system/` bootstrap directory for these, and no classic `flux bootstrap`-generated manifests in the repo. `kubenuc-test` and `k3s-prod-test` are the two remaining holdouts still on the legacy classic-bootstrap pattern (`flux-system/gotk-components.yaml` + `gotk-sync.yaml`, committed in-repo); don't assume every cluster has a `flux-system/` directory.

```
clusters/{cluster-name}/
├── flux-instance.yaml      # FluxInstance CRD (Flux Operator clusters only)
├── flux-system/            # Legacy classic-bootstrap clusters only (kubenuc-test, k3s-prod-test)
├── cluster-vars.yaml       # Reference to the SOPS-encrypted cluster-vars Secret
├── vars/
│   └── cluster-vars.sops.yaml
├── apps.yaml               # Top-level Kustomization -> ./apps/ (interval: 10m)
├── charts.yaml             # Top-level Kustomization -> ./charts/ (interval: 5m; 1m on
│                           # k3s-rabbit/k8s-vms-daniele/oc-ampere is known pending debt,
│                           # not a documentation error — see Plan C interval-policy work)
├── charts/
│   └── {repo-name}.yml     # HelmRepository manifests
└── apps/
    └── {app-name}/
        ├── deploy.yaml     # Per-app Kustomization (interval: 15m), healthChecks the HelmRelease
        ├── secrets/        # 1Password-backed OnePasswordItem CRDs
        └── manifests/      # HelmRelease (interval: 15m) + any raw Kubernetes manifests
```

**Key conventions:**
- Each application lives in its own directory under `apps/`
- Dependencies are declared explicitly in the per-app Kustomization's `.spec.dependsOn`, not in the HelmRelease
- Common pattern: storage (OpenEBS) → database (PostgreSQL) → application
- Sync intervals in practice: `charts.yaml` `5m`, `apps.yaml` `10m`, per-app Kustomization/HelmRelease `15m` — never go below `5m` anywhere without a documented reason
- All secrets use 1Password `OnePasswordItem`/`ExternalSecret` — **never commit raw secrets**

---

## Common Tasks

### Add a new application to a cluster

1. Create `clusters/{cluster}/apps/{app-name}/deploy.yaml` with a per-app `Kustomization` (path -> `./manifests`, `healthChecks` referencing the `HelmRelease`)
2. Add the `HelmRelease` under `clusters/{cluster}/apps/{app-name}/manifests/release.yml`
3. Add secrets under `clusters/{cluster}/apps/{app-name}/secrets/` using `OnePasswordItem` CRDs
4. Add `dependsOn` in the Kustomization if the app requires storage or a database
5. No `kustomization.yaml` edit needed in most cases — Flux/kustomize auto-discovers all YAML files in a path when no `kustomization.yaml` exists there

### Add a new Helm repository

1. Add a `HelmRepository` manifest under `clusters/{cluster}/charts/`
2. It's auto-discovered by `clusters/{cluster}/charts.yaml`'s Kustomization (same auto-discovery as above)
3. Use the repository source in `HelmRelease` specs via `sourceRef`

### Update FluxCD components

- **Flux Operator clusters** (`kubenuc`, `k3s-rabbit`, `k8s-vms-daniele`, `oc-ampere`): Renovate auto-PRs `flux-instance.yaml` version bumps (`spec.distribution.version`) — do not manually edit unless fixing a bootstrap issue.
- **Legacy classic-bootstrap clusters** (`kubenuc-test`, `k3s-prod-test`): Renovate auto-PRs `flux-system/gotk-components.yaml` bumps — same rule, don't hand-edit outside a bootstrap fix.
- **Flux Operator's own installation** (the `controlplaneio-fluxcd/flux-operator` binary itself, distinct from the `FluxInstance` CR it reconciles): on `kubenuc` and `k8s-vms-daniele` this is now HelmRelease-managed via `clusters/{cluster}/apps/flux-operator/` (`charts/flux-operator.yml` HelmRepository + per-app Kustomization/HelmRelease), Renovate-tracked like any other chart. `k3s-rabbit` and `oc-ampere` are still on the original untracked manual `helm install` — same gap, not yet closed on those clusters.

---

## CI Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `validate-kubenuc.yml` | PR | Full `kubenuc` cluster E2E validation (2h timeout) |
| `validate-k8s-vms.yml` | PR | `k8s-vms-daniele` cluster validation |
| `security-static-analysis.yml` | PR/push to `clusters/**` | KubeLinter static analysis + checkov across all cluster apps |
| `gitleaks.yml` | PR/push to `main` | Secret scanning |

PR validation runs k3s + Flux CD with a 2-hour timeout. Robot Framework E2E tests via `tests/robot/robot-test-job.yaml`.

---

## Renovate

### Benign `Excess registryUrls` warning

During Renovate runs you will see:

```
WARN: Excess registryUrls found for datasource lookup - using first configured only
```

This is **expected and harmless**. Several `HelmRepository` names (e.g. `1password-chart`, `grafana-charts`) are intentionally defined in multiple cluster directories — per-cluster isolation is by design. Renovate's Flux/helm manager aggregates all matching repo definitions repo-wide and attaches the URL once per occurrence; the helm datasource uses only the first URL. Because every duplicate name maps to the **same URL** across all clusters, the correct URL is always used. No action needed; do not rename `HelmRepository` resources to silence this warning.
