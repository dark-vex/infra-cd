# k3s-rabbit — Cluster-Specific Notes

## Cluster Bootstrap

- `flux-instance` — `spec.cluster.multitenant: false` is single-tenant-by-design, not an oversight. See [Confluence: FluxCD — Multitenancy (k3s-rabbit)](https://fastnetserv.atlassian.net/wiki/spaces/IT/pages/748322817).

## App-Specific Gotchas

Terse pointers to decisions that used to be inline comments — full rationale now lives in Confluence.

- `fluxcd` (notifications) — the `fluxcd-notifications` Alert deliberately omits `eventMetadata.region`, unlike kubenuc/k8s-vms-daniele. See [Confluence: FluxCD — Notification Region Omission (k3s-rabbit)](https://fastnetserv.atlassian.net/wiki/spaces/IT/pages/748322817).
