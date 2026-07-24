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
- **Flux Operator's own installation** (the `controlplaneio-fluxcd/flux-operator` binary itself, distinct from the `FluxInstance` CR it reconciles): on `kubenuc`, `k8s-vms-daniele`, and `oc-ampere` this is now HelmRelease-managed via `clusters/{cluster}/apps/flux-operator/` (`charts/flux-operator.yml` HelmRepository + per-app Kustomization/HelmRelease), Renovate-tracked like any other chart. `k3s-rabbit` is still on the original untracked manual `helm install` — same gap, not yet closed on that cluster.
- **`system-upgrade-controller`** (Rancher's k3s auto-upgrade controller, driven by `Plan` CRs under `apps/system-upgrade-controller/`): on `oc-ampere` this is now GitOps-managed (backported to `kubenuc`, `k8s-vms-daniele`, and `k3s-rabbit` in a companion PR) via `clusters/{cluster}/system-upgrade-controller/` (vendored verbatim `crd.yaml` + `controller.yaml` from the matching `rancher/system-upgrade-controller` GitHub release) plus a top-level `clusters/{cluster}/system-upgrade-controller.yaml` Kustomization that `apps` `dependsOn` (health-checked on the controller `Deployment`). This is a **new cluster-scoped CRD/RBAC install**, kept out of `apps/` deliberately — same ownership-separation reasoning as `flux-operator`/`charts`/`cluster-vars` each owning a sibling top-level directory. Renovate's `customManagers` entry only bumps the `image:` tag in `controller.yaml` — a version bump PR does **not** update the CRD schema, RBAC, or ConfigMap; those must be manually re-vendored from the matching release (same convention as `flux-system/gotk-components.yaml`). **Version is intentionally not uniform across clusters**: `kubenuc`/`k8s-vms-daniele`/`k3s-rabbit` are pinned to `v0.19.2` to match the pre-existing out-of-band install confirmed live on the first two (`kubectl apply`-managed, no Helm/Rancher ownership markers) — `k3s-rabbit` itself couldn't be checked (no MCP context) and was assumed to match; `oc-ampere` runs the latest `v0.20.1` since it had no prior install to match. Don't "fix" this divergence by bulk-bumping all four to the same tag without re-confirming live state first. See Confluence for the full incident history and live-check details.
- **`oc-ampere`'s `apps/kustomization.yaml`** lists its four app subdirectories explicitly instead of relying on kustomize-controller's recursive auto-discovery — this was needed to stop the `Plan` CRs under `apps/system-upgrade-controller/manifests/` from being dual-owned by both the flattened `apps` Kustomization and the nested `system-upgrade` child Kustomization. `kubenuc` (27 app dirs), `k8s-vms-daniele` (17), and `k3s-rabbit` (2) have the same latent dual-ownership issue but are **not yet fixed** — larger per-cluster enumeration, tracked as a follow-up.

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
