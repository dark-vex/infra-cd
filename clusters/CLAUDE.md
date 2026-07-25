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
        ├── namespace.y*ml  # Raw Namespace manifest, only if the app creates its own —
        │                   # lives here, NOT nested under manifests/ (see note below)
        ├── secrets/        # 1Password-backed OnePasswordItem CRDs
        └── manifests/      # HelmRelease (interval: 15m) + any raw Kubernetes manifests
```

**Key conventions:**
- Each application lives in its own directory under `apps/`
- Dependencies are declared explicitly in the per-app Kustomization's `.spec.dependsOn`, not in the HelmRelease
- Common pattern: storage (OpenEBS) → database (PostgreSQL) → application
- Sync intervals in practice: `charts.yaml` `5m`, `apps.yaml` `10m`, per-app Kustomization/HelmRelease `15m` — never go below `5m` anywhere without a documented reason
- All secrets use 1Password `OnePasswordItem`/`ExternalSecret` — **never commit raw secrets**
- An app's own `Namespace` manifest (when it has one) goes at the app's top level and is listed directly in the cluster's root `apps/kustomization.yaml` — never nested under `manifests/`. See "Explicit `apps/kustomization.yaml`" below for why.

---

## Common Tasks

### Add a new application to a cluster

1. Create `clusters/{cluster}/apps/{app-name}/deploy.yaml` with a per-app `Kustomization` (path -> `./manifests`, `healthChecks` referencing the `HelmRelease`)
2. Add the `HelmRelease` under `clusters/{cluster}/apps/{app-name}/manifests/release.yml`
3. Add secrets under `clusters/{cluster}/apps/{app-name}/secrets/` using `OnePasswordItem` CRDs
4. Add `dependsOn` in the Kustomization if the app requires storage or a database
5. If the app needs its own `Namespace` (rather than relying on Helm's `install.createNamespace`), put it at `clusters/{cluster}/apps/{app-name}/namespace.y*ml` — **not** nested inside `manifests/` — with `kustomize.toolkit.fluxcd.io/prune: disabled` set on it. This is required on any cluster with an explicit `apps/kustomization.yaml` (step 6): the root `apps` Kustomization applies with no `dependsOn` on anything app-specific, so listing the namespace directly in `apps/kustomization.yaml` guarantees it's created before either the app's `manifests` Kustomization or its `secrets` Kustomization can reconcile — closing off a from-scratch-bootstrap deadlock that a `manifests/`-nested namespace can hit if the app's `manifests` Kustomization `dependsOn`s its own `secrets` Kustomization. `oc-ampere` and `k3s-rabbit` sidestep this entirely by bundling the namespace inside `secrets/` instead — either placement works there since neither cluster's split-secrets apps have this dependsOn shape.
6. `oc-ampere`, `k3s-rabbit`, `k8s-vms-daniele`, and `kubenuc` each have an explicit `apps/kustomization.yaml` — add the new app's nested Kustomization file (or its directory, if it has its own wrapper `kustomization.yaml`), **and** its `namespace.y*ml` if it has one, to that `resources:` list, or it silently never gets applied. `kubenuc-test` and `k3s-prod-test` (legacy classic-bootstrap clusters) have no `apps/kustomization.yaml`; Flux/kustomize auto-discovers all YAML files in a path there.

### Add a new Helm repository

1. Add a `HelmRepository` manifest under `clusters/{cluster}/charts/`
2. It's auto-discovered by `clusters/{cluster}/charts.yaml`'s Kustomization (same auto-discovery as above)
3. Use the repository source in `HelmRelease` specs via `sourceRef`

### Update FluxCD components

- **Flux Operator clusters** (`kubenuc`, `k3s-rabbit`, `k8s-vms-daniele`, `oc-ampere`): Renovate auto-PRs `flux-instance.yaml` version bumps (`spec.distribution.version`) — do not manually edit unless fixing a bootstrap issue.
- **Legacy classic-bootstrap clusters** (`kubenuc-test`, `k3s-prod-test`): Renovate auto-PRs `flux-system/gotk-components.yaml` bumps — same rule, don't hand-edit outside a bootstrap fix.
- **Flux Operator's own installation** (the `controlplaneio-fluxcd/flux-operator` binary itself, distinct from the `FluxInstance` CR it reconciles): on `kubenuc`, `k8s-vms-daniele`, and `oc-ampere` this is now HelmRelease-managed via `clusters/{cluster}/apps/flux-operator/` (`charts/flux-operator.yml` HelmRepository + per-app Kustomization/HelmRelease), Renovate-tracked like any other chart. `k3s-rabbit` is still on the original untracked manual `helm install` — same gap, not yet closed on that cluster.
- **`system-upgrade-controller`** (Rancher's k3s auto-upgrade controller, driven by `Plan` CRs under `apps/system-upgrade-controller/`): on `oc-ampere` this is now GitOps-managed (backported to `kubenuc`, `k8s-vms-daniele`, and `k3s-rabbit` in a companion PR) via `clusters/{cluster}/system-upgrade-controller/` (vendored verbatim `crd.yaml` + `controller.yaml` from the matching `rancher/system-upgrade-controller` GitHub release) plus a top-level `clusters/{cluster}/system-upgrade-controller.yaml` Kustomization that `apps` `dependsOn` (health-checked on the controller `Deployment`). This is a **new cluster-scoped CRD/RBAC install**, kept out of `apps/` deliberately — same ownership-separation reasoning as `flux-operator`/`charts`/`cluster-vars` each owning a sibling top-level directory. Renovate's `customManagers` entry only bumps the `image:` tag in `controller.yaml` — a version bump PR does **not** update the CRD schema, RBAC, or ConfigMap; those must be manually re-vendored from the matching release (same convention as `flux-system/gotk-components.yaml`). **Version is intentionally not uniform across clusters**: `kubenuc`/`k8s-vms-daniele`/`k3s-rabbit` are pinned to `v0.19.2` to match the pre-existing out-of-band install confirmed live on the first two (`kubectl apply`-managed, no Helm/Rancher ownership markers) — `k3s-rabbit` itself couldn't be checked (no MCP context) and was assumed to match; `oc-ampere` runs the latest `v0.20.1` since it had no prior install to match. Don't "fix" this divergence by bulk-bumping all four to the same tag without re-confirming live state first. See Confluence for the full incident history and live-check details.
- **Explicit `apps/kustomization.yaml`** (listing every app's nested Kustomization file, or its directory for apps with their own wrapper `kustomization.yaml`, instead of relying on kustomize-controller's recursive auto-discovery) is now in place on all four Flux Operator clusters (`oc-ampere`, `k3s-rabbit`, `k8s-vms-daniele`, `kubenuc`) — this closes a dual-ownership bug where an app's live objects were reconciled by both the flattened `apps` Kustomization and its own nested child Kustomization (hit in practice on `oc-ampere`'s and `k8s-vms-daniele`'s `system-upgrade-controller` `Plan` CRs, and on `k8s-vms-daniele`'s `awx/backup/backup.yml` CronJob, which had no nested Kustomization CR of its own and is now listed explicitly to avoid it silently dropping out of the build). See "Add a new application to a cluster" above: any new app on one of these clusters must be added to its `apps/kustomization.yaml`'s `resources:` list.
- **App-owned `Namespace` objects moved out of `manifests/` to the app's top level** on `k8s-vms-daniele` and `kubenuc` (PRs #1707–#1710), listed directly in the cluster's root `apps/kustomization.yaml` so the root `apps` Kustomization owns/creates them. The old pattern — `namespace.y*ml` nested inside `manifests/`, applied only by the app's `manifests` Kustomization, which itself `dependsOn`s the app's `secrets` Kustomization — deadlocks a from-scratch bootstrap: `secrets` can't go `Ready` without the namespace, and the `manifests` Kustomization that would create it never runs while blocked on `secrets`. Invisible on an already-live cluster (the namespace already exists), real on a genuine rebuild. `apps` applies with no `dependsOn` on anything app-specific, so this ownership makes the namespace structurally guaranteed to exist before any per-app Kustomization — `manifests` or `secrets` — can even start reconciling. Safe to move without triggering pruning of the (already-live) namespace because every such manifest carries `kustomize.toolkit.fluxcd.io/prune: disabled`, which exempts the object from garbage collection regardless of which Kustomization currently or formerly owns it. `oc-ampere` and `k3s-rabbit` don't need this — every split-secrets app there already bundles its own `namespace.yml` inside `secrets/` instead, so no `dependsOn` cycle exists on those two clusters. See "Add a new application to a cluster" above for the convention going forward.

### Flux notification alerting (Slack)

Live on `kubenuc`, `k8s-vms-daniele`, and `k3s-rabbit` via `clusters/{cluster}/apps/fluxcd/` (`notifications.yaml`: a `notification.toolkit.fluxcd.io` `Provider`+`Alert` pair, plus `secrets.yaml`/`secrets/slack-secret.yml` syncing a shared `OnePasswordItem` at `vaults/k8s_secrets/items/slack-url` — the same 1Password item across all three, not a per-cluster secret). `eventMetadata.cluster` in the `Alert` must be set to the real cluster name; the tuned `exclusionList` (transient DNS/socket noise) should be copied verbatim. `kubenuc`/`k8s-vms-daniele` additionally have a `github` `Receiver` for push-triggered reconcile and (`kubenuc` only) a `betterstack-bridge` `Provider`/`Alert` scoped to Nextcloud maintenance — neither is part of this pattern; don't copy them when extending alerting to a new cluster.

**Not extended to the other 3 clusters, deliberately:**
- **`oc-ampere`** has no 1Password Operator by design (`FluxInstance.spec.components` only lists the four core Flux controllers, and there's no `apps/1password/`) — adding Slack alerting here would need introducing 1Password onto a cluster that's intentionally scoped to Teleport-agent-only. Needs a product decision (add 1Password there, or use a different secret mechanism), not a copy-paste.
- **`kubenuc-test` and `k3s-prod-test`** are the two legacy classic-bootstrap clusters (auto-discovery, no `apps/kustomization.yaml`). Every app there is either flat auto-discovered files or a nested `Kustomization` CR that cross-references another cluster's real content (see "Add a new application to a cluster" and `kubenuc-test`'s `overlays kubenuc manifests` convention) — there's no clean shape for notifications specifically: a flat copy would apply the `OnePasswordItem` with no `dependsOn` on the (untracked, out-of-band) 1Password operator; a nested `secrets` Kustomization pointed at its own `apps/fluxcd/secrets/` would be double-reconciled by auto-discovery (the exact class of bug fixed in PRs #1697–#1710); and cross-referencing the paired live cluster's whole `apps/fluxcd/` directory drags in resources that don't belong on a test cluster (`kubenuc`'s Nextcloud-specific `betterstack-bridge`, or a `webhook-ingress.yaml` that needs its own `postBuild.substituteFrom` to avoid applying a literal, invalid `${FLUX_WEBHOOK_HOST:=...}` hostname). Needs its own design, not a template copy.
- **`k3s-prod-test`'s existing `apps/fluxcd/deploy.yaml`** already cross-references `clusters/k8s-vms-daniele/apps/fluxcd` today, despite this cluster being documented as having "independent manifests" (unlike `kubenuc-test`'s explicit "overlays" convention) — likely a copy-paste of `kubenuc-test`'s pattern rather than an intentional choice. Any Flux alert this fires on `k3s-prod-test` would carry `eventMetadata.cluster: "k8s-vms-daniele"`, which is wrong. Flagged here, not fixed — resolving it (independent content vs. an intentional, metadata-patched cross-reference) is a separate decision.

---

## CI Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `validate-kubenuc.yml` | PR | Full `kubenuc` cluster E2E validation (2h timeout) |
| `validate-k8s-vms.yml` | PR | `k8s-vms-daniele` cluster validation |
| `security-static-analysis.yml` | PR/push to `clusters/**` | KubeLinter static analysis + checkov across all cluster apps |
| `gitleaks.yml` | PR/push to `main` | Secret scanning |

PR validation runs k3s + Flux CD with a 2-hour timeout. Robot Framework E2E tests via `tests/robot/robot-test-job.yaml`.

**Known gap — neither workflow validates the real root `apps/kustomization.yaml`:** both `validate-kubenuc.yml` and `validate-k8s-vms.yml` derive their app list from `git diff` path-parsing and create one synthetic `flux create kustomization app-<name>` CR per changed app, never building/applying a Kustomization pointed at the whole `clusters/{cluster}/apps` directory. Both also deploy exclusively from the `-test` cluster directories (`kubenuc-test`, `k3s-prod-test`), which don't have a root `apps/kustomization.yaml` at all — only the prod directories (`kubenuc`, `k8s-vms-daniele`) do. A bug in the real file (typo'd path, missing app entry) has no CI code path that would ever catch it — only manual `kustomize build clusters/{cluster}/apps` review. TODO if either workflow is touched again: add a build-the-real-file check. See memory `project_kubenuc_e2e_bootstrap_gap.md` / `project_k8s_vms_e2e_ci_gap.md`.

---

## Renovate

### Benign `Excess registryUrls` warning

During Renovate runs you will see:

```
WARN: Excess registryUrls found for datasource lookup - using first configured only
```

This is **expected and harmless**. Several `HelmRepository` names (e.g. `1password-chart`, `grafana-charts`) are intentionally defined in multiple cluster directories — per-cluster isolation is by design. Renovate's Flux/helm manager aggregates all matching repo definitions repo-wide and attaches the URL once per occurrence; the helm datasource uses only the first URL. Because every duplicate name maps to the **same URL** across all clusters, the correct URL is always used. No action needed; do not rename `HelmRepository` resources to silence this warning.
