# kubenuc — BetterStack Bridge (Nextcloud Maintenance)

A small Python webhook deployed in `flux-system` pauses the BetterStack uptime monitor for Nextcloud while a Flux-driven upgrade is in progress, avoiding false downtime alerts.

- **Files:**
  - `apps/fluxcd/betterstack-bridge.yaml` — Deployment + Service
  - `apps/fluxcd/betterstack-bridge-main.py` — Python bridge code (plain file, not inline YAML)
  - `apps/fluxcd/kustomization.yaml` — `configMapGenerator` for the bridge code; hash suffix in the ConfigMap name forces a rolling restart on every code change — **do not remove or add `disableNameSuffixHash: true`**
  - `apps/fluxcd/notifications.yaml` — Flux `Provider` (`betterstack-bridge`) + `Alert` (`nextcloud-maintenance`)
- **Pause triggers:** `DependencyNotReady` on `Kustomization/nextcloud` (primary — fires when kustomize-controller's healthCheck fails because the HelmRelease is upgrading, covers values-only digest bumps; does NOT fire on no-op 15m reconcile cycles); plus `DriftDetected` on `HelmRelease/nextcloud` and `ChartPullSucceeded` on `HelmChart/nextcloud-fastnetserv-nextcloud` (chart-version upgrades / manual drift).
- **Unpause triggers:** any terminal HelmRelease reason (`UpgradeSucceeded`, `UpgradeFailed`, `InstallSucceeded`, `RollbackSucceeded`, etc.), or `ReconciliationSucceeded`/`ReconciliationFailed` on `Kustomization/nextcloud` (fast unpause for no-op reconcile cycles where no real upgrade runs).
- **Debug:** set `DEBUG_EVENTS=1` on the Deployment to log every raw event payload. All bridge logs are timestamped (ISO8601 UTC).
- **Secret:** 1Password item `betterstack-token` with fields `token` and `monitor-id`, synced via `OnePasswordItem`.

## PodDisruptionBudgets — Multi-Replica Only

PDBs are only added to apps with more than one replica. A `minAvailable: 1` PDB on a single-replica app permanently blocks `kubectl drain` (the only pod can never be evicted without violating the budget), which wedges `system-upgrade-controller` during node upgrades. The vast majority of apps in this cluster run a single replica and have **no PDB** — accepted downtime during node drains/upgrades for those apps is a deliberate tradeoff, not an oversight.

Current PDBs: `coredns` (`kube-system`, `minAvailable: 1`, backed by an HPA with `minReplicas: 2`), `haproxy-ingress` (`controller.PodDisruptionBudget` in the chart's own values, `minAvailable: 1`, already `replicaCount: 3`). The Zalando postgres-operator manages its own PDB per `Postgresql` cluster automatically (`enable_pod_disruption_budget` defaults to `true`, not overridden here) — do not add a duplicate PDB for postgres clusters.
