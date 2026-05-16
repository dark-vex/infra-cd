# Clusters — Conventions & Recipes

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

### Update FluxCD components

Renovate auto-PRs FluxCD component bumps — do not manually edit `clusters/{cluster}/flux-system/` files unless fixing a bootstrap issue.

---

## CI Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `validate-kubenuc.yml` | PR | Full cluster E2E validation (2h timeout) |
| `validate-k8s-vms.yml` | PR | K8s VMs cluster validation |
| `security-static-analysis.yml` | PR/push to `clusters/**` | KubeLinter static analysis across all cluster apps |

PR validation runs k3s + Flux CD with a 2-hour timeout. Robot Framework E2E tests via `tests/robot/robot-test-job.yaml`.
