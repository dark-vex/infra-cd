# Terraform — Conventions & Recipes

## Conventions

- **State backend:** Terraform Cloud (`Fastnetserv` org) for all stacks **except** `terraform/netbox/`, which uses S3 (Cloudflare R2 — `terraform-state` bucket, `auto` region). Migrated in PR #1404.
- **Required providers:** Hetzner Cloud, OCI, Proxmox (`~> 0.100`), 1Password (`~> 3`)
- **Format:** Always run `terraform fmt` before committing — CI rejects unformatted files
- Each `terraform/{environment}/` (or `terraform/proxmox/{host}/`) is independent with its own backend config
- Reusable modules published as standalone repos: `dark-vex/terraform-proxmox-vm`, `dark-vex/terraform-proxmox-lxc`, `dark-vex/terraform-hetzner-server`, `dark-vex/terraform-cloudflare-dns`, `dark-vex/terraform-cloudflare-tunnel` — referenced via `github.com/dark-vex/<name>?ref=<commit-sha>  # vX.Y.Z` (SHA-pinned for supply-chain safety; the trailing comment records the tag the SHA corresponds to)
- **Secrets provider by stack** (never hardcode sensitive values — source from the stack's provider(s) below):
  - **1Password only:** `terraform/hetzner/`, `terraform/grafana/`, `terraform/semaphore/`, `terraform/oci/k8s-armchair/`, `terraform/oci/teleport/` (proxy hostname is a root-level custom field on the existing `teleport-server` item — not exposed via the standard `onepassword_item` data source, so it's read via a `data "external"` + Connect API script instead of `section_map`)
  - **SOPS only** (`carlpett/sops`, age-encrypted `secrets.sops.yaml`): `terraform/DNS/`, `terraform/cloudflare-tunnel/`
  - **Both:** `terraform/netbox/` (1Password for API credentials; SOPS for on-prem IP/prefix inventory), `terraform/proxmox/rabbit/`, `terraform/proxmox/gozzi-hpelvisor/`, `terraform/proxmox/ec200/`, `terraform/oci/test_vpn/` (1Password for Proxmox/API credentials + SSH keys; SOPS for VM/LXC/instance hostnames)
  - Each SOPS-using stack has its own dedicated age keypair and `SOPS_AGE_KEY_*` GitHub Actions secret — never shared across stacks
- Do not hand-pin provider versions managed by Renovate
- **`local-exec`/`terraform_data` escape hatch** (first used in `terraform/semaphore/main.tf`): only reach for this when a provider genuinely doesn't wrap a real, documented API endpoint (confirmed by checking the provider's schema/source, not assumed) — a custom provider is over-engineering for a couple of endpoints, and a manual out-of-band step violates this repo's no-config-drift convention. Make it idempotent (GET-then-match-then-PUT/POST, never a blind POST) and drive re-runs via `triggers_replace` hashing both the desired config and the helper script itself — `terraform_data` provisioners only fire on `create` otherwise. Document the known limitation plainly: this doesn't detect out-of-band drift on an otherwise-unchanged apply.

**CI workflow stages** (fmt → init → validate → plan-as-PR-comment → apply-on-main): see the `ci-workflows` skill's "Terraform CI workflow pattern" for the full step-by-step and copy-paste template — don't duplicate it here.

---

## CI Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `terraform.yml` | PR/push to `terraform/hetzner/` | Hetzner infrastructure |
| `terraform-bio.yml` | PR/push to `terraform/proxmox/gozzi-hpelvisor/` | Gozzi-01 BIO + hpelvisor Proxmox hosts |
| `terraform-mxp.yml` | PR/push to `terraform/proxmox/ec200/` | EC200 (MXP) Proxmox host |
| `terraform-psp.yml` | PR/push to `terraform/proxmox/rabbit/` | Rabbit-01 PSP Proxmox host |
| `terraform-dns.yml` | PR/push to `terraform/DNS/` | DNS records (Cloudflare) |
| `terraform-cloudflare-tunnel.yml` | PR/push to `terraform/cloudflare-tunnel/` | Cloudflare Tunnel remote ingress config (kubenuc, prod-k3s) |
| `terraform-grafana.yml` | PR/push to `terraform/grafana/` | Grafana dashboards |
| `terraform-netbox.yml` | PR/push to `terraform/netbox/` | NetBox infrastructure |
| `terraform-oci.yml` | PR/push to `terraform/oci/` | OCI compute instances (k8s-armchair, teleport, test-vpn) |
| `terraform-semaphore.yml` | PR/push to `terraform/semaphore/` | SemaphoreUI project for Proxmox self-registration (webhook → job template) |

---

## Grafana Dashboards (`terraform/grafana/`)

`generate_dashboards.py` generates every Terraform-managed dashboard JSON under `dashboards/{cluster}/*.json` from Python — never hand-edit a `dashboards/*.json` file, the CI drift-guard (`terraform-grafana.yml`) regenerates and diffs it on every PR (`python3 generate_dashboards.py && git diff --exit-code dashboards/` — run this locally before every commit that touches the generator).

**Registry pattern:** the `APPS` dict (`{cluster: [(file_name, namespace, display_name, dashboard_type), ...]}`) lists every dashboard; the `builders` dict maps each `dashboard_type` string to a `lambda c, fn, ns, d, u: build_x(...)` that returns the dashboard JSON. `stable_uid(cluster, file_name)` derives a deterministic UID so re-running the generator never changes existing dashboards' UIDs. To add a new app: add an `APPS` entry, write a `build_x(...)` function, register it in `builders`.

**Two ways to build a dashboard:**
- **Hand-rolled** (`build_postgresql`, `build_teleport_agent`, `build_haproxy_ingress`, etc.): panels built directly from the shared helpers (`p_row`/`p_stat`/`p_ts`/`p_stat_multi`/`p_gauge`/`p_logs`, plus the composite `status_row`/`resource_row`/`reliability_row`). Use this when no suitable official/community dashboard exists, or the app's metric surface is small enough to hand-write.
- **Template import** (`build_harbor_from_template`, `build_awx_from_template`, `build_seaweedfs_from_template`, etc.): adapts a real, checked-in-verbatim dashboard JSON from `templates/` (fetched from the project's own GitHub repo or grafana.com — never hand-edited, only the generator adapts it). Before adapting a new grafana.com dashboard, **check its top-level keys for the new Grafana schema v2 shape** (`apiVersion: dashboard.grafana.app/v2`, `kind: Dashboard`, `spec.elements`/`spec.layout` instead of classic `schemaVersion`/`panels[]`/`targets[]`) — every helper in this file assumes the classic model; a v2 dashboard needs an entirely separate code path, not supported today. Reject v2 candidates and prefer a classic-schema alternative (an older grafana.com revision, or the project's own bundled dashboard, which is usually classic-schema).

**Template-import sub-patterns** (a template's panel array shape decides which applies):
- **Flat panel list with `type: "row"` marker panels interspersed** (CoreDNS, Harbor, Velero) — use `_remove_row_and_contents(panels, row_title)` to drop a row and its child panels. Before trusting it on a new template, confirm the row's children are actually contiguous in the array immediately after the row marker (print titles in order) — an early draft of the SeaweedFS import used this helper and was bitten by non-contiguous children (two rows' panels interleaved); its current code handles that template's row removal a different way instead. Flux's template needed no row removal at all — it only nulls out two unwanted histogram targets inside an existing panel via `_replace_exprs_exact`, a different helper entirely.
- **Nested/collapsed rows where each row object itself carries its own `panels: [...]` list** (AWX) — `_remove_row_and_contents` doesn't apply; filter both the outer row list and each row's inner `panels` list directly via list comprehension.

**Datasource-ref handling:** `_fix_datasource_refs(d)` rewrites the standard grafana.com `${DS_PROMETHEUS}` placeholder (bare string or `{"uid": "${DS_...}"}` dict shape) to this repo's real datasource (`PROM = {"uid": "grafanacloud-prom", "type": "prometheus"}`). Some templates use additional non-standard shapes (AWX: literal `"awx_prometheus"` uid, legacy numeric uid, bare `{}`; Harbor: `${datasource}` template-variable uid, literal `"prometheus"` placeholder) — these need a dedicated per-template walker function, but **always call the shared `_fix_datasource_refs` too** if the template also uses the standard `${DS_PROMETHEUS}` shape anywhere (Harbor's template mixes all three shapes — a dedicated walker alone would silently leave any `${DS_PROMETHEUS}` panels unresolved). Grep the generated JSON for leftover `${DS_`/`${datasource}`/literal `"prometheus"` strings after every template-import build to catch this class of miss. Never rewrite Grafana's own built-in annotations datasource (`{"type": "datasource", "uid": "grafana"}` or `{"type": "grafana", "uid": "-- Grafana --"}`) — that's a legitimate, distinct reference, not a stale placeholder.

**Fail loud, don't guess:** when scoping a template's panel exprs to this repo's `cluster=`/`namespace=` labels, raise `ValueError`/`KeyError` if a panel's metric isn't recognized/scoped rather than silently shipping an unadapted query — this pattern has caught real bugs (a Harbor row-removal bug that left an unscoped `harbor_core_*` expr in the output) exactly when it's supposed to.

### Template-import candidate audit (2026-08-31)

The same-metrics-only audit landed across PRs #1925-#1928. Re-evaluate rejected candidates only if their scrape targets, remote-write policy, recording rules, or upstream dashboard artifacts change.

**Adopted:**
- **cert-manager (both clusters):** grafana.com #20340. `k8s-vms-daniele` drops the ACME Client row because `certmanager_http_acme_client_request_count` is absent there but live on `kubenuc`.
- **Blackbox (`k8s-vms-daniele`):** grafana.com #7587. Its seven legacy `singlestat` panels require explicit conversion to `stat`: `_normalize_imported_dashboard_metadata()` force-stamps `schemaVersion = 38`, so Grafana assumes frontend schema migration already ran and skips `singlestat` → `stat` conversion.
- **Authentik/SSO (`kubenuc`):** Authentik's project-official dashboard. Drops all outpost-timing/LDAP/proxy/radius panels plus task-error/duration-bucket panels; every referenced family was confirmed absent live, a larger cut than the initial candidate review assumed.
- **Falco (both clusters):** grafana.com #17319, the generator's first Loki/LogQL template import. Uses dedicated `_fix_loki_datasource_refs()` and `_replace_logql_exprs_exact()` helpers; the Prometheus equivalents would silently attach Loki panels to the wrong datasource. Selectors use this repo's live `service_name="falco"` label instead of the template's `from="falcosidekick"` placeholder.

**Rejected:**
- **Grafana Alloy (both clusters):** every candidate `alloy_component_*` metric is dropped by the existing remote-write relabel policy; the dashboard would be empty.
- **Node Exporter (`k8s-vms-daniele`):** the entire `job="prometheus-node-exporter"` stream is dropped by remote-write.
- **PostgreSQL:** about 30 of 35 candidate panels require settings/activity/locks/bgwriter/static/process metric families dropped by remote-write; the surviving subset is not a viable replacement.
- **Nextcloud:** no Prometheus exporter is deployed (`metrics.enabled = false`); fails the same-metrics-only constraint.
- **OpenEBS:** the official candidate targets LVM LocalPV; this cluster uses hostpath LocalPV and has no matching exporter.
- **Jenkins:** candidate requires the Jenkins Prometheus plugin, which is not installed or scraped here.
- **Jellyfin:** no importable official/community dashboard artifact and no scrape target.
- **Node Resources:** the official kube-prometheus dashboard requires recording rules this repo does not run; keep the bespoke builder.
- **System Upgrade Controller:** upstream exposes no metrics endpoint.
- **NUT (`kubenuc`):** exporter configuration, scrape annotations, and NetworkPolicy are correct but it intentionally emits zero live metrics (repo-owner confirmation, 2026-08-31); do not resurface as a scrape bug.

**Bespoke — confirmed no public candidate:** `1password`, `net-mon`, `film-tv-exporter`, `rabbit-netbw`, and `teleport-agent` (small metric surface; no HTTP request-rate metrics). These were quick-checked, not deep-researched.

**Excluded by policy, not research:** `haproxy-ingress`. Public HAProxy dashboards assume `haproxy_server_*`, the exact family deliberately dropped after the documented cardinality incident (~6,471 series and an OOM crash-loop).

**Verification checklist, every dashboard change:** `python3 generate_dashboards.py` clean → `git diff --exit-code -- dashboards/` (drift-guard) → `terraform fmt -check -diff` → grep the generated JSON for leftover `${DS_`/`${datasource}`/literal `"prometheus"`-uid strings → live `query_prometheus` check that each new panel's expr actually returns real, non-stale data (a green generator run proves the JSON is well-formed, not that the dashboard shows anything meaningful) → independent dual review (codex-rescue + fable, run separately, not primed with each other's findings) before merge.

### Cardinality-budget discipline

The Grafana Cloud account's real hard enforcement limit is **15,000 active series** (`err-mimir-max-active-series` — confirmed via live `429` remote-write errors during an incident, not documentation) — distinct from and higher than the ~10,000-series billing/included-series figure, which is a separate, softer threshold. This project worked to a **≤9,500 active series** target ceiling (buffer below the hard cap, plus margin for the billing tier), checked via `grafanacloud_instance_active_series` on the `grafanacloud-usage` datasource.

- **Checkpoint before and after every change that adds scrape targets** — but only trust the reading if the Alloy metrics collector (`alloy-metrics`, the StatefulSet running `annotationAutodiscovery`) has been stable for a real stretch (no recent pod restarts). A crash-looping collector biases the gauge low (it can't complete scrape+remote-write cycles), and recovery after a fix isn't instant even once the collector is healthy again — Mimir's active-series count only clears already-ingested series as they age out as stale, a lag of tens of minutes, not seconds.
- **Two-step land, every new scrape target:** (1) an annotation-only PR enabling scraping, merged and given time for Flux to reconcile plus a real scrape interval; (2) confirm actual live metric names AND their cardinality (`query_prometheus`/`count by (__name__) (...)`) before writing any dashboard builder — never guess metric names or estimate cardinality from documentation alone. A metric family with a "per pre-reserved slot" cardinality shape (e.g. HAProxy Ingress's `haproxy_server_*`, sized by reserved server slots for dynamic scaling, not actual running pods) can be an order of magnitude higher than a naive backend-count estimate — this actually happened enabling haproxy-ingress metrics (~6,471 series added, not the low-hundreds originally estimated, requiring an emergency follow-up `write_relabel_config` drop rule).
- **`write_relabel_config` drop rules** live in each cluster's `grafana-alloy/manifests/release.yml`, under `destinations.grafanaCloudMetrics.metricProcessingRules` — this project's accumulated precedent for dropping a confirmed-zero-consumer metric family. Always confirm zero consumers first (grep every `dashboards/*.json` panel expr and any `grafana_rule_group` alert rule for the metric name) before adding a drop rule.

## Add a New Terraform Environment

1. Create `terraform/{environment}/` with `provider.tf`, `main.tf`, `variables.tf`
2. Configure a Terraform Cloud workspace for the new environment
3. Add a corresponding GitHub Actions workflow — see the `ci-workflows` skill's "Adding a new Terraform workflow" section for the exact steps
