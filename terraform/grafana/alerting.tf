# ---------------------------------------------------------------------------
# Pre-emptive alert: Grafana Cloud active-series approaching the 10,000
# included-series limit. Fires *before* the monthly billing reset throttles
# ingestion, instead of us finding out after the fact.
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
              params = [9000]
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
      summary     = "Grafana Cloud active series is approaching the 10,000 included-series limit"
      description = "max(grafanacloud_instance_active_series) on grafanacloud-usage has been above 9000 for 6h. Ingestion throttles at 10,000. Check `count by(cluster)({__name__=~\".+\"})` on grafanacloud-prom to find the growth source before the monthly billing reset."
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
