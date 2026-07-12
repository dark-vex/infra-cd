---
name: app-troubleshooting
description: Diagnose a broken/slow/crashlooping app in kubenuc or k8s-vms-daniele — gather evidence via Graylog/Grafana/kubectl before asking the user anything. Triggers on "X is down", "X is crashlooping", "X is erroring", "X is slow", "why did X restart".
---

# App Troubleshooting Skill

Use this skill whenever an application in `kubenuc` or `k8s-vms-daniele` is reported down, crashlooping, erroring, or slow. Gather evidence yourself before asking the user for details they may not have (namespace, pod name, recent changes) — those are all discoverable from the repo and the observability stack.

## Decision tree

### 1. Locate

- Map the app name to a cluster: search `clusters/kubenuc/apps/<app>/` first, then `clusters/k8s-vms-daniele/apps/<app>/`. App directory names don't always match the Kubernetes namespace (e.g. `jfrog-acr` app → `jfrog` namespace, `postgresql` app → `databases` namespace) — read the app's `manifests/release.yml` or `manifests/namespace.yml` to get the real namespace.
- Check `deploy.yaml` for the Flux `dependsOn` chain — an app stuck behind a failing dependency (storage, database) will show as unhealthy even though the real fault is upstream.

### 2. Logs

- **kubenuc**: query **Graylog MCP first** (local, free, Grafana Alloy ships OTLP logs there at info level and above). Fall back to `mcp__grafana__query_loki_logs` only for logs that Graylog's info-level filter drops, or when you need a specific LogQL pattern.
- **k8s-vms-daniele**: **Loki only** — this cluster has no Graylog feed, so `mcp__grafana__query_loki_logs` is the sole source.
- **Pod never started / nothing in any log pipeline**: reach for direct cluster access. Prefer the user-level `kubernetes-mcp-server` (read-only, one context per cluster — select the right one via its `configuration_contexts_list`/`configuration_view` tools) for quick lookups: `pods_get`, `resources_get`, `events_list`, `pods_log`. Reserve the `kubernetes-agent` subagent for anything needing `kubectl describe`/`get events --sort-by`/`logs --previous` combined with write-adjacent `kubectl`/`helm`/`flux`/`kustomize` operations, or Docker-isolated `exec`.

### 3. Metrics (both clusters)

- Use `mcp__grafana__query_prometheus`, always scoped with `cluster=` and `namespace=` labels — this environment has a hard 10K active-series budget in Grafana Cloud, unscoped queries are wasteful and slow.
- Before writing a new PromQL query, call `mcp__grafana__search_dashboards` — there may already be a dashboard covering this app or its underlying component (postgres, redis, ingress).

### 4. Flux / GitOps state

- Check current `Kustomization`/`HelmRelease` status and recent reconciliation history — see the `flux-operations` skill for the exact commands.
- Correlate with `git log -- clusters/<cluster>/apps/<app>` for recent manifest changes, and check for open Renovate PRs bumping this app's chart (`gh pr list` / GitHub search for the app name) — a chart bump landing right before the incident is the most common root cause in this repo.

### 5. Output contract

Once you have evidence, report back as:

1. **Timeline** — when the symptom started, correlated with any deploy/reconcile/chart-bump event
2. **Evidence** — the actual log lines / metric values / kubectl output that support the diagnosis (not just "logs show an error")
3. **Hypothesis** — the most likely root cause given the evidence
4. **Proposed fix** — as a concrete PR (which file, what change), following this repo's normal PR workflow (feature branch, semantic commit, never push to `main`)

Don't propose a fix without evidence from at least one of steps 2–4 — a guess dressed up as a diagnosis wastes a review cycle.

## Related skills

- `flux-operations` — Kustomization/HelmRelease status commands, dependency chain conventions
- `cluster-operations` — which apps live on which cluster, kubenuc-test overlay pattern
- `secrets-management` — if the suspected cause is a missing/rotated 1Password secret
