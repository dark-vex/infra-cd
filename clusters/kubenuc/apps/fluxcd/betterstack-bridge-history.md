# BetterStack bridge — change history

Kept here to avoid re-discovering the same dead ends. Each PR's assumption and
whether it held up in production.

| PR | Commit | What changed | Assumption | Held? |
|----|--------|-------------|------------|-------|
| #1207 | 83a11b3 | Initial bridge — HelmRelease terminal events only | Pause would be added later; only unpause path existed | No — no pause at all |
| #1213 | 0802154 | Logging + API endpoint fix | Operational fix only | N/A |
| #1254 | 1f93d11 | `DriftDetected` (HR) + `ChartPullSucceeded` (HelmChart) as pause triggers | These fire before every upgrade | Partial — they fire for chart-version bumps and manual drift, but **not** for values-only spec changes (e.g. image digest bumps via Renovate) |
| #1271 | 41f37ae | `Kustomization/ReconciliationSucceeded` as pause trigger + auto-unpause timer | `ReconciliationSucceeded` fires before helm-controller picks up the new spec | **No** — `deploy.yaml` has a `healthChecks` on the HelmRelease, so kustomize-controller waits for the HR to become Ready before emitting `ReconciliationSucceeded`. It fires **after** `UpgradeSucceeded`, not before. |
| #1324 | d788eed | `Kustomization/Progressing` as pause trigger; `KUSTOMIZATION_CLOSE_REASONS` for fast unpause on no-op reconciles; `should_close()` helper | `Progressing` fires when kustomize-controller starts applying — before helm-controller sees the new spec. Terminal kustomization reasons close the pause quickly for no-op cycles. | **No** — `Progressing` fires on EVERY 15m reconcile cycle; `ReconciliationSucceeded` is suppressed by the notification controller for routine cycles, so the fast-unpause path never fires. Monitor paused for 5 min every 15 min. |
| #1325 | this | `Kustomization/DependencyNotReady` as pause trigger | `DependencyNotReady` fires only when kustomize-controller's healthCheck fails (i.e., HelmRelease is actively upgrading). It does NOT fire on no-op reconciles where the HelmRelease is already Ready. | TBD |

## Key constraints to remember

- **`healthChecks` in `apps/nextcloud/deploy.yaml:38-42`** blocks kustomize-controller
  from emitting `ReconciliationSucceeded` until the `HelmRelease` is Ready. This is
  what makes `ReconciliationSucceeded` unusable as a pre-upgrade trigger.
- **`DriftDetected`** only fires when installed manifests diverge from desired state
  (manual kubectl changes, etc.) — not on a Flux-pushed spec change.
- **`ChartPullSucceeded`** only fires when a new chart *version* is pulled — not on a
  values/image-digest change that keeps the same chart version.
- **`Progressing`** fires on EVERY Kustomization reconcile cycle (~15 min), not just
  during real upgrades. Using it as a pause trigger causes spurious 5-minute pauses.
- **`ReconciliationSucceeded`** is suppressed by the Flux notification controller for
  routine reconcile cycles — it never arrives at the bridge, making it useless as a
  fast-unpause close trigger.
- **`DependencyNotReady`** fires only when the Kustomization's healthCheck fails because
  the HelmRelease isn't Ready. This happens during real upgrades but not during no-ops.
