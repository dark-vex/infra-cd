# ---------------------------------------------------------------------------
# Pre-emptive alert: Grafana Cloud active-series approaching the account's
# real ingestion-rejection limit of 15,000 (confirmed live via a real
# remote-write incident, 2026-08-26, err-mimir-max-active-series 429s) -
# distinct from and higher than the 10,000 included-series (billing) figure,
# a separate, softer threshold governing overage cost, not a hard block.
#
# Reframed 2026-09-30 (was >9000, framed around the 10,000 billing figure):
# a 2026-09-29/30 cardinality audit (see terraform/CLAUDE.md's "Metrics usage
# audit" section) found this repo's real baseline now runs ~11,500-13,300
# active series - durably and knowingly above both the old 9,000 alert
# threshold and the ≤9,500 working target, an accepted tradeoff, not a
# regression. At the old threshold this alert was permanently `firing` with
# zero signal value (never resolves, so it stops being an actionable
# warning). Raised to >13,500 for 6h - genuine early warning before the real
# 15,000 hard cap, not the softer billing figure. Sustained baseline over the
# preceding 7 days peaked at ~13,071 - only ~430 below this new threshold, so
# expect this to still fire occasionally under normal drift, not just in a
# genuine emergency.
#
# Caveat (not fixed here): this `for: 6h` window guards against slow drift
# toward the cap, not a sudden step change - Mimir enforces the 15,000
# ingestion limit live, independent of this alert, and `for` only delays the
# Slack notification, it doesn't delay or prevent rejection. A haproxy-
# ingress-sized surprise (~6,471 series against an estimated low-hundreds,
# this repo's own precedent) landing from the current ~12,000-13,000
# baseline would blow past 15,000 almost immediately, likely before this
# rule's 6h window elapses. The actual guard against that class of surprise
# is this repo's "two-step land" process (annotate-only PR, confirm live
# cardinality before building anything on top - see the cardinality-budget
# discipline section) - not this alert.
#
# Routing: this rule uses a per-rule `notification_settings` override to send
# straight to the infra Slack contact point, instead of a `grafana_notification_policy`
# resource. `grafana_notification_policy` manages the *entire* org-wide policy
# tree as a singleton — since this org's existing policy tree isn't managed by
# this repo (and isn't readable with the current service account's
# permissions), defining it here risks silently overwriting routing for
# unrelated, pre-existing alerts. The per-rule override is additive and safe.
# ---------------------------------------------------------------------------

# Reuses the Slack webhook already used for Flux CD notifications
# (clusters/kubenuc/apps/fluxcd/notifications.yaml, channel #infrastructure).
data "onepassword_item" "slack_webhook" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "hvl3ggxc2qphqc3h434svskhka"
}

resource "grafana_contact_point" "infra_slack" {
  name = "infra-slack"

  slack {
    # The item is a 1Password "API Credential"; its `hostname`-purpose field
    # is labeled "address" in the vault and holds the Slack webhook URL.
    url = data.onepassword_item.slack_webhook.hostname
  }
}

resource "grafana_rule_group" "active_series_guard" {
  name             = "active-series-guard"
  folder_uid       = grafana_folder.alerting.uid
  interval_seconds = 300

  rule {
    name           = "GrafanaCloudActiveSeriesNearLimit"
    condition      = "B"
    for            = "6h"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "grafanacloud-usage"
      model = jsonencode({
        refId         = "A"
        expr          = "max(grafanacloud_instance_active_series)"
        instant       = true
        range         = false
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "-100"
      model = jsonencode({
        refId = "B"
        type  = "classic_conditions"
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        conditions = [
          {
            evaluator = {
              type   = "gt"
              params = [13500]
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              type   = "last"
              params = []
            }
            type = "query"
          }
        ]
      })
    }

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Grafana Cloud active series is approaching the 15,000 ingestion-rejection limit"
      description = "max(grafanacloud_instance_active_series) on grafanacloud-usage has been above 13500 for 6h - within 1,500 series of the tenant's real ingestion-rejection limit of 15,000 (confirmed live via err-mimir-max-active-series 429s, 2026-08-26). This repo's accepted working baseline runs ~11,500-13,300 (see terraform/CLAUDE.md's cardinality-budget discipline and Metrics usage audit sections) - this firing means growth beyond that baseline, not the baseline itself. Check `count by(cluster)({__name__=~\".+\"})` on grafanacloud-prom to find the growth source."
    }

    notification_settings {
      contact_point = grafana_contact_point.infra_slack.name
      group_by      = ["alertname"]
    }
  }
}

# ---------------------------------------------------------------------------
# Weekly Postgres DB backup CronJobs (nextcloud-db-backup, harbor-db-backup)
# failed silently for an extended period before being caught manually (see
# clusters/kubenuc/apps/{nextcloud,harbor}/manifests/backup.yml). This alert
# closes that gap using kube_job_status_failed, which kube-state-metrics
# already emits for every Job object - zero new scrape targets/series added.
# no_data_state is OK: the series only exists while the (already-failed) Job
# object exists in the cluster, so its absence means no failure to report.
# ---------------------------------------------------------------------------
resource "grafana_rule_group" "backup_cronjob_guard" {
  name             = "backup-cronjob-guard"
  folder_uid       = grafana_folder.alerting.uid
  interval_seconds = 300

  rule {
    name           = "WeeklyDbBackupFailed"
    condition      = "B"
    for            = "5m"
    no_data_state  = "OK"
    exec_err_state = "Alerting"

    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "grafanacloud-prom"
      model = jsonencode({
        refId         = "A"
        expr          = "max(kube_job_status_failed{job_name=~\"nextcloud-db-backup-.*|harbor-db-backup-.*\"})"
        instant       = true
        range         = false
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "-100"
      model = jsonencode({
        refId = "B"
        type  = "classic_conditions"
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        conditions = [
          {
            evaluator = {
              type   = "gt"
              params = [0]
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              type   = "last"
              params = []
            }
            type = "query"
          }
        ]
      })
    }

    labels = {
      severity = "critical"
    }

    annotations = {
      summary     = "Weekly Postgres DB backup CronJob failed"
      description = "kube_job_status_failed is 1 for a Job matching nextcloud-db-backup-* or harbor-db-backup-* - the weekly pg_dump->S3 backup did not complete. Check `kubectl get jobs -n nextcloud-fastnetserv` / `-n harbor` and the pod logs."
    }

    notification_settings {
      contact_point = grafana_contact_point.infra_slack.name
      group_by      = ["alertname"]
    }
  }
}

# ---------------------------------------------------------------------------
# rabbit-01-psp is capped at 25 TB/month of physical-NIC bandwidth by its
# housing provider (see ansible/pve-host-netmon/). Tracks a trailing 30-day
# increase() (not calendar month-to-date — grafana_rule_group has no "now/M"
# calendar-alignment primitive) against 90% of the cap, the same "orange"
# tier used by the dashboard's gauge/stat panels. Evaluated hourly since a
# 30d range query on a slow-moving counter doesn't need 5m granularity;
# `for` is set to a few eval cycles so a single noisy evaluation can't fire
# it. Rolling 30d, not calendar month — see plan doc / PR description for
# why, and note it under-reads (fires late, not early) across any collector
# gap since increase() can't count samples that were never scraped.
# ---------------------------------------------------------------------------
resource "grafana_rule_group" "rabbit_netbw_quota_guard" {
  name             = "rabbit-netbw-quota-guard"
  folder_uid       = grafana_folder.alerting.uid
  interval_seconds = 3600

  rule {
    name           = "RabbitNetbwApproachingMonthlyQuota"
    condition      = "B"
    for            = "3h"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    data {
      ref_id = "A"

      relative_time_range {
        from = 2592000 # 30d
        to   = 0
      }

      datasource_uid = "grafanacloud-prom"
      model = jsonencode({
        refId         = "A"
        expr          = "(sum(increase(node_network_receive_bytes_total{site=\"bgy\",device=\"eno1\",instance=\"rabbit-01-psp\"}[30d])) + sum(increase(node_network_transmit_bytes_total{site=\"bgy\",device=\"eno1\",instance=\"rabbit-01-psp\"}[30d]))) / 25000000000000.0 * 100"
        instant       = true
        range         = false
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "-100"
      model = jsonencode({
        refId = "B"
        type  = "classic_conditions"
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        conditions = [
          {
            evaluator = {
              type   = "gt"
              params = [90]
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              type   = "last"
              params = []
            }
            type = "query"
          }
        ]
      })
    }

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "rabbit-01-psp is approaching its 25 TB/month bandwidth quota"
      description = "Trailing 30-day rx+tx on eno1 (site=bgy, instance=rabbit-01-psp) is above 90% of the 25 TB housing cap. This is a rolling 30-day window, not calendar month-to-date, and under-reads across any collector gap - check the 'rabbit-01-psp — Network Bandwidth' dashboard (proxmox folder, uid pve-rabbit-netbw) for the exact month-to-date figure before deciding whether to throttle or contact the provider."
    }

    notification_settings {
      contact_point = grafana_contact_point.infra_slack.name
      group_by      = ["alertname"]
    }
  }
}
