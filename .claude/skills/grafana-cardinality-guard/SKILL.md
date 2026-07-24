---
name: grafana-cardinality-guard
description: Before adding any new Prometheus scrape target or exporter, check the active-series budget in Grafana Cloud and propose write_relabel drops if needed. Triggers on "add a scrape config", "add an exporter", "enable metrics for X", "add a ServiceMonitor". Gates any change that could grow active series count.
---

# Grafana Cardinality Guard Skill

This repo has a **hard 10K active-series budget** in Grafana Cloud (kubenuc's `grafana-alloy` HelmRelease already carries an extensive `write_relabel_config` drop-list purely to stay under it — see `clusters/kubenuc/apps/grafana-alloy/manifests/release.yml`). Use this skill **before** any PR adds a new Prometheus scrape target, exporter, `ServiceMonitor`, or enables `metrics.enabled` on a chart that was previously unscraped.

## Steps

1. **Query current active series.** Use `mcp__grafana__query_prometheus` against `count({__name__=~".+"})` (or the equivalent cardinality query for this Grafana Cloud stack) to get today's baseline before making any change.
2. **Estimate the delta.** For a new exporter/scrape target, estimate how many distinct series it will add — check the exporter's own `/metrics` endpoint cardinality if reachable, or a documented series count from the exporter's project docs. Multiply by label cardinality if the target has per-pod/per-namespace label dimensions that will fan out.
3. **Compare against the cap.** If baseline + estimated delta would approach or exceed 10K, this is a blocker, not a nice-to-have fix later.
4. **Propose `write_relabel_config` drops.** Follow the existing pattern in `clusters/kubenuc/apps/grafana-alloy/manifests/release.yml`'s `destinations.grafanaCloudMetrics.metricProcessingRules` — each rule is a `write_relabel_config` block with `source_labels`, a `regex`, and `action = "drop"`. Propose the minimal drop-list needed to keep the new target's contribution small (e.g. drop per-container histogram buckets, drop high-cardinality debug/internal metrics) rather than dropping the whole target's metrics wholesale if only some of them matter.
5. **Mirror to k8s-vms-daniele if relevant** — that cluster has its own, smaller `grafana-alloy` HelmRelease with its own `metricProcessingRules` block; a shared exporter added to both clusters needs the drop-list considered for each independently, since the budgets are not pooled.

## When this skill gates other work

Per this repo's Cluster Optimization plan, several changes are explicitly blocked on this check before being enabled:
- Reloader (stakater) — disabling its own `ServiceMonitor` when installed, or confirming it doesn't add scrape targets
- node-problem-detector — must be deployed **unscraped** (no `ServiceMonitor`), verified via this skill before install
- Any VPA-recommender/right-sizing exercise — metrics-server is bundled in k3s already; adding a *new* scrape path for right-sizing needs this check first

## Output contract

Report: current baseline series count, estimated delta from the proposed change, whether it fits the budget, and (if not) the specific `write_relabel_config` blocks to add — as a diff against the target `release.yml`, not just a description.
