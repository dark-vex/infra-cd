# k3s-rabbit — Cluster-Specific Notes

## Cluster Bootstrap

- `flux-instance` — `spec.cluster.multitenant: false` is single-tenant-by-design, not an oversight. See [Confluence: FluxCD — Multitenancy (k3s-rabbit)](https://fastnetserv.atlassian.net/wiki/spaces/IT/pages/748322817).

## App-Specific Gotchas

Terse pointers to decisions that used to be inline comments — full rationale now lives in Confluence.

- `fluxcd` (notifications) — the `fluxcd-notifications` Alert deliberately omits `eventMetadata.region`, unlike kubenuc/k8s-vms-daniele. See [Confluence: FluxCD — Notification Region Omission (k3s-rabbit)](https://fastnetserv.atlassian.net/wiki/spaces/IT/pages/748322817).

## CI e2e coverage (`validate-k3s-rabbit.yml`)

This cluster has exactly 3 real apps — `fluxcd`, `system-upgrade-controller`, `teleport-agent` — and **all 3 are excluded** from the e2e workflow's real-path app loop: each has a live external side-effect (Slack/GitHub notifications, a real k3s upgrade-channel call with node-cordon capability, a real Teleport tunnel join against production infra). The per-app loop therefore deploys **zero apps by design** on every run today. This is not a no-op run: it still proves Flux bootstrap, GitRepository resolution against the PR branch, the `teleport-charts` HelmRepository source reconciling, and the top-level `system-upgrade-controller` Kustomization (a separate, safe object from the excluded app-level `Plan` CRs of the same base name) reaching Ready — plus fail-closed coverage that fires automatically the moment a 4th app is ever added without an `EXCLUDED_APPS` entry or a real resolution path. See the workflow's own header comments for the exact conditions that gate its exit code (the `Check for failed reconciliations` step does not — its `jq` pipelines all end in `|| true`).
