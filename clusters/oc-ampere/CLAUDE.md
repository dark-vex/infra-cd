# oc-ampere — Cluster-Specific Notes

## Architecture: ARM64 production, x86_64 CI

Production `oc-ampere` runs on genuinely ARM64 compute — `terraform/oci/k8s-armchair/main.tf`, `shape = "VM.Standard.A1.Flex"` (OCI Ampere A1). The self-hosted GitHub Actions runner pool this repo's CI uses is not documented as any specific architecture anywhere in this repo — not confirmed x86_64 by any repo file, but there's also no evidence of ARM64 self-hosted capacity.

**Practical effect**: `validate-oc-ampere.yml`'s e2e run validates manifest correctness and Flux reconciliation health — it does not validate that every image this cluster pulls actually has an arm64 variant. Images not covered by that validation: `nginxinc/nginx-unprivileged:1.31-alpine` (`ngx-webhook`), `ghcr.io/controlplaneio-fluxcd/flux-operator:v0.57.0` (`flux-operator`). If a future image pin only ships an amd64 tag, this workflow will pass while production fails to schedule the pod — check multi-arch support by hand for any new image added here.

## App Inventory

4 real apps under `apps/kustomization.yaml`: `flux-operator`, `ngx-webhook`, `system-upgrade-controller`, `teleport-agent`. This supersedes any older "Teleport agent only" characterization of this cluster — see `clusters/CLAUDE.md`'s cluster table.

No `apps/1password/` and no 1Password Operator on this cluster (`FluxInstance.spec.components` only lists the four core Flux controllers) — this is a real gap, not a design choice scoped to a smaller app set. Any future app needing a `OnePasswordItem` secret needs that gap closed first (see `clusters/CLAUDE.md`'s Slack-alerting section for the same constraint).

`flux-operator`'s own installation is HelmRelease-managed here (`apps/flux-operator/`, chart pinned to `0.57.0` via `charts/flux-operator.yml`), Renovate-tracked like any other chart — same pattern now in place on all four Flux Operator clusters, including `k3s-rabbit` (added via PRs #1799/#1804/#1805).

## CI e2e coverage (`validate-oc-ampere.yml`)

2 of the 4 real apps deploy for real in e2e: `flux-operator` and `ngx-webhook`. `system-upgrade-controller` and `teleport-agent` are excluded (same live-external-side-effect reasons as k3s-rabbit's: real `upgrade.cattle.io` `Plan` CRDs with `cordon: true`, and a real Teleport tunnel join against production infra respectively).

`ngx-webhook` has no per-app `deploy.yaml` — it's a bare `manifests/deploy.yml` entry directly in the root `apps/kustomization.yaml`. The e2e workflow resolves this via a dedicated fourth resolution tier (`dirname()` of the matched `apps/kustomization.yaml` entry), not the standard per-app `deploy.y*ml` fallback used everywhere else.

`flux-instance.yaml` stays permanently skip-listed in this workflow's top-level-resource loop: the job bootstraps Flux via a plain `flux install`, and applying `flux-instance.yaml` for real would hand reconciliation to the workflow's own real-path `flux-operator` app, fighting the CLI-installed components mid-run. Verified (via `helm template` against the pinned `0.57.0` chart with empty values) that `flux-operator`'s own Deployment stays idle — no Helm hooks, no automatic action at pod startup — until a `FluxInstance` CR actually exists, so deploying it for real without one is safe.
