# BetterStack bridge — change history

Kept here to avoid re-discovering the same dead ends. Each PR's assumption and
whether it held up in production.

| PR | Commit | What changed | Assumption | Held? |
|----|--------|-------------|------------|-------|
| #1207 | 83a11b3 | Initial bridge — HelmRelease terminal events only | Pause would be added later; only unpause path existed | No — no pause at all |
| #1213 | 0802154 | Logging + API endpoint fix | Operational fix only | N/A |
| #1254 | 1f93d11 | `DriftDetected` (HR) + `ChartPullSucceeded` (HelmChart) as pause triggers | These fire before every upgrade | Partial — they fire for chart-version bumps and manual drift, but **not** for values-only spec changes (e.g. image digest bumps via Renovate) |
| #1271 | 41f37ae | `Kustomization/ReconciliationSucceeded` as pause trigger + auto-unpause timer | `ReconciliationSucceeded` fires before helm-controller picks up the new spec | **No** — `deploy.yaml` has a `healthChecks` on the HelmRelease, so kustomize-controller waits for the HR to become Ready before emitting `ReconciliationSucceeded`. It fires **after** `UpgradeSucceeded`, not before. |
| #1324 | this | `Kustomization/Progressing` as pause trigger; `KUSTOMIZATION_CLOSE_REASONS` for fast unpause on no-op reconciles; `should_close()` helper | `Progressing` fires when kustomize-controller starts applying — before helm-controller sees the new spec. Terminal kustomization reasons close the pause quickly for no-op cycles. | TBD |

## Key constraints to remember

- **`healthChecks` in `apps/nextcloud/deploy.yaml:38-42`** blocks kustomize-controller
  from emitting `ReconciliationSucceeded` until the `HelmRelease` is Ready. This is
  what makes `ReconciliationSucceeded` unusable as a pre-upgrade trigger.
- **`DriftDetected`** only fires when installed manifests diverge from desired state
  (manual kubectl changes, etc.) — not on a Flux-pushed spec change.
- **`ChartPullSucceeded`** only fires when a new chart *version* is pulled — not on a
  values/image-digest change that keeps the same chart version.
- **`Progressing`** on the Kustomization fires reliably for both chart-version upgrades
  and values-only changes, making it the most reliable pre-upgrade hook.
- The post-upgrade `Kustomization/Progressing` (visible in incident log at 19:47:21)
  is harmless — any re-pause from it is closed quickly by the following
  `ReconciliationSucceeded`.
