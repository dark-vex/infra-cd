#!/usr/bin/env python3
"""
Generate Grafana dashboard JSON files for all cluster applications.

Run from the terraform/grafana/ directory:
    python3 generate_dashboards.py

Re-run after editing app definitions or panel templates to regenerate all JSONs.
The generated files are committed to git and consumed by Terraform.
"""

import json
import os

PROM = {"uid": "grafanacloud-prom", "type": "prometheus"}
LOKI = {"uid": "grafanacloud-logs", "type": "loki"}


# ---------------------------------------------------------------------------
# Panel builders
# ---------------------------------------------------------------------------

def p_stat(pid, title, expr, x, y, w=6, h=4, unit="short", legend="", thresholds=None, instant=False):
    if thresholds is None:
        thresholds = [{"value": None, "color": "green"}]
    target = {"expr": expr, "legendFormat": legend, "refId": "A"}
    if instant:
        target["instant"] = True
    return {
        "id": pid, "title": title, "type": "stat", "datasource": PROM,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "targets": [target],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
            "orientation": "auto", "textMode": "auto",
            "colorMode": "background", "graphMode": "none",
        },
        "fieldConfig": {
            "defaults": {
                "unit": unit,
                "thresholds": {"mode": "absolute", "steps": thresholds},
                "color": {"mode": "thresholds"},
                "mappings": [],
            },
            "overrides": [],
        },
    }


def p_gauge(pid, title, expr, x, y, w=8, h=8, unit="percent", min_val=0, max_val=100, thresholds=None):
    if thresholds is None:
        thresholds = [
            {"value": None, "color": "green"},
            {"value": 70, "color": "yellow"},
            {"value": 90, "color": "orange"},
            {"value": 95, "color": "red"},
        ]
    return {
        "id": pid, "title": title, "type": "gauge", "datasource": PROM,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "targets": [{"expr": expr, "legendFormat": "", "refId": "A", "instant": True}],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
            "orientation": "auto",
            "showThresholdLabels": False,
            "showThresholdMarkers": True,
        },
        "fieldConfig": {
            "defaults": {
                "unit": unit,
                "min": min_val,
                "max": max_val,
                "thresholds": {"mode": "absolute", "steps": thresholds},
                "color": {"mode": "thresholds"},
                "mappings": [],
            },
            "overrides": [],
        },
    }


def p_stat_multi(pid, title, targets, x, y, w=6, h=4):
    return {
        "id": pid, "title": title, "type": "stat", "datasource": PROM,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "targets": [
            {"expr": t["expr"], "legendFormat": t.get("legend", ""), "refId": chr(65 + i)}
            for i, t in enumerate(targets)
        ],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
            "orientation": "horizontal", "textMode": "value_and_name",
            "colorMode": "value", "graphMode": "none",
        },
        "fieldConfig": {
            "defaults": {"unit": "short", "color": {"mode": "palette-classic"}, "mappings": []},
            "overrides": [],
        },
    }


def p_ts(pid, title, targets, x, y, w=12, h=8, unit="short", ds=None):
    return {
        "id": pid, "title": title, "type": "timeseries", "datasource": ds or PROM,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "targets": [
            {"expr": t["expr"], "legendFormat": t.get("legend", "{{pod}}"), "refId": chr(65 + i)}
            for i, t in enumerate(targets)
        ],
        "options": {
            "tooltip": {"mode": "multi", "sort": "desc"},
            "legend": {"displayMode": "table", "placement": "bottom", "calcs": ["lastNotNull", "max"]},
        },
        "fieldConfig": {
            "defaults": {
                "unit": unit,
                "custom": {"lineWidth": 1, "fillOpacity": 10, "gradientMode": "none", "spanNulls": False},
            },
            "overrides": [],
        },
    }


def p_logs(pid, cluster, namespace, y, extra_filter=""):
    return {
        "id": pid, "title": "Pod Logs", "type": "logs", "datasource": LOKI,
        "gridPos": {"x": 0, "y": y, "w": 24, "h": 8},
        "targets": [{
            "expr": f'{{cluster="{cluster}",namespace="{namespace}"}}{extra_filter}',
            "refId": "A",
            "queryType": "range",
        }],
        "options": {
            "dedupStrategy": "none", "enableLogDetails": True,
            "prettifyLogMessage": False, "showLabels": False,
            "showTime": True, "sortOrder": "Descending", "wrapLogMessage": False,
        },
    }


def p_row(pid, title, y):
    return {
        "id": pid, "title": title, "type": "row", "collapsed": False,
        "gridPos": {"x": 0, "y": y, "w": 24, "h": 1}, "panels": [],
    }


def make_dashboard(title, uid_str, tags, panels, time_range=None, refresh="1m"):
    return {
        "title": title,
        "uid": uid_str,
        "tags": tags,
        "timezone": "browser",
        "refresh": refresh,
        "schemaVersion": 38,
        "time": time_range or {"from": "now-6h", "to": "now"},
        "timepicker": {},
        "templating": {"list": []},
        "annotations": {"list": []},
        "panels": panels,
        "version": 1,
        "editable": True,
    }


def stable_uid(cluster, name):
    prefix = {"kubenuc": "kn", "k8s-vms-daniele": "kv", "proxmox": "pve"}[cluster]
    safe = name.replace(".", "-").replace("/", "-")[:30]
    return f"{prefix}-{safe}"


# ---------------------------------------------------------------------------
# Standard status + resource row helper
# ---------------------------------------------------------------------------

def status_row(pid, y, c, n, pf="", df=""):
    """Returns (panels_list, next_pid, next_y)."""
    panels = []
    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1

    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}"{pf},phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1

    panels.append(p_stat(pid, "Ready Containers",
        f'sum(kube_pod_container_status_ready{{cluster="{c}",namespace="{n}"{pf}}})',
        6, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1

    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"{pf}}}[24h]))',
        12, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1

    panels.append(p_stat_multi(pid, "Replicas (Available / Desired)", [
        {"expr": f'sum(kube_deployment_status_replicas_available{{cluster="{c}",namespace="{n}"{df}}})', "legend": "Available"},
        {"expr": f'sum(kube_deployment_spec_replicas{{cluster="{c}",namespace="{n}"{df}}})', "legend": "Desired"},
    ], 18, y)); pid += 1

    return panels, pid, y + 4


def resource_row(pid, y, c, n, pf=""):
    panels = []
    panels.append(p_row(pid, "Resources", y)); pid += 1; y += 1

    panels.append(p_ts(pid, "CPU Usage by Pod",
        [{"expr": f'sum by (pod) (rate(container_cpu_usage_seconds_total{{cluster="{c}",namespace="{n}"{pf},container!="",container!="POD"}}[5m]))', "legend": "{{pod}}"}],
        0, y, unit="short"
    )); pid += 1

    panels.append(p_ts(pid, "Memory Usage by Pod",
        [{"expr": f'sum by (pod) (container_memory_working_set_bytes{{cluster="{c}",namespace="{n}"{pf},container!="",container!="POD"}})', "legend": "{{pod}}"}],
        12, y, unit="bytes"
    )); pid += 1

    return panels, pid, y + 8


def reliability_row(pid, y, c, n, pf=""):
    panels = []
    panels.append(p_row(pid, "Reliability", y)); pid += 1; y += 1

    panels.append(p_ts(pid, "Container Restarts",
        [{"expr": f'sum by (pod, container) (rate(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"{pf}}}[5m]))', "legend": "{{pod}}/{{container}}"}],
        0, y, unit="short"
    )); pid += 1

    panels.append(p_ts(pid, "Network I/O",
        [
            {"expr": f'sum(rate(container_network_receive_bytes_total{{cluster="{c}",namespace="{n}"}}[5m]))', "legend": "Receive"},
            {"expr": f'sum(rate(container_network_transmit_bytes_total{{cluster="{c}",namespace="{n}"}}[5m]))', "legend": "Transmit"},
        ],
        12, y, unit="Bps"
    )); pid += 1

    return panels, pid, y + 8


# ---------------------------------------------------------------------------
# Dashboard builders
# ---------------------------------------------------------------------------

def build_standard(cluster, name, namespace, display, uid_str, has_container=True, pf="", df=""):
    c, n = cluster, namespace
    panels, pid, y = status_row(1, 0, c, n, pf, df)

    if has_container:
        rp, pid, y = resource_row(pid, y, c, n, pf)
        panels += rp
        rp, pid, y = reliability_row(pid, y, c, n, pf)
        panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"{display} — {cluster}", uid_str, [cluster, name, "kubernetes"], panels)


def build_cert_manager(cluster, namespace, uid_str):
    c, n = cluster, namespace
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Ready Containers",
        f'sum(kube_pod_container_status_ready{{cluster="{c}",namespace="{n}"}})',
        6, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"}}[24h]))',
        12, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "ACME Requests (1h)",
        f'sum(increase(certmanager_http_acme_client_request_count{{cluster="{c}"}}[1h]))',
        18, y
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Certificates", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Days Until Expiry",
        [{"expr": f'(certmanager_certificate_expiration_timestamp_seconds{{cluster="{c}"}} - time()) / 86400', "legend": "{{namespace}}/{{name}}"}],
        0, y, w=24, unit="d"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Resources", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "CPU Usage",
        [{"expr": f'sum by (pod) (rate(container_cpu_usage_seconds_total{{cluster="{c}",namespace="{n}",container!="",container!="POD"}}[5m]))', "legend": "{{pod}}"}],
        0, y, unit="short"
    )); pid += 1
    panels.append(p_ts(pid, "Memory Usage",
        [{"expr": f'sum by (pod) (container_memory_working_set_bytes{{cluster="{c}",namespace="{n}",container!="",container!="POD"}})', "legend": "{{pod}}"}],
        12, y, unit="bytes"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Controller Metrics", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Controller Sync Rate",
        [
            {"expr": f'sum by (controller) (rate(certmanager_controller_sync_call_count{{cluster="{c}"}}[5m]))', "legend": "{{controller}} calls/s"},
            {"expr": f'sum by (controller) (rate(certmanager_controller_sync_error_count{{cluster="{c}"}}[5m]))', "legend": "{{controller}} errors/s"},
        ],
        0, y, unit="ops"
    )); pid += 1
    panels.append(p_ts(pid, "ACME Client Requests",
        [{"expr": f'sum by (method, status) (rate(certmanager_http_acme_client_request_count{{cluster="{c}"}}[5m]))', "legend": "{{method}} {{status}}"}],
        12, y, unit="reqps"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"cert-manager — {cluster}", uid_str, [cluster, "cert-manager", "kubernetes"], panels)


def build_falco(cluster, namespace, uid_str):
    c, n = cluster, namespace
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Security Events", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Events (1h)",
        f'sum(increase(falcosecurity_falcosidekick_falco_events_total{{cluster="{c}"}}[1h]))',
        0, y, thresholds=[{"value": None, "color": "green"}, {"value": 10, "color": "yellow"}, {"value": 100, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "Critical / Emergency (1h)",
        f'sum(increase(falcosecurity_falcosidekick_falco_events_total{{cluster="{c}",priority_raw=~"critical|emergency"}}[1h]))',
        6, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",phase="Running"}})',
        12, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"}}[24h]))',
        18, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Event Trends", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Events by Priority",
        [{"expr": f'sum by (priority_raw) (rate(falcosecurity_falcosidekick_falco_events_total{{cluster="{c}"}}[5m]))', "legend": "{{priority_raw}}"}],
        0, y, w=12, unit="cps"
    )); pid += 1
    panels.append(p_ts(pid, "Top 10 Rules",
        [{"expr": f'topk(10, sum by (rule) (rate(falcosecurity_falcosidekick_falco_events_total{{cluster="{c}"}}[5m])))', "legend": "{{rule}}"}],
        12, y, w=12, unit="cps"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Resources", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "CPU Usage",
        [{"expr": f'sum by (pod) (rate(container_cpu_usage_seconds_total{{cluster="{c}",namespace="{n}",container!="",container!="POD"}}[5m]))', "legend": "{{pod}}"}],
        0, y, unit="short"
    )); pid += 1
    panels.append(p_ts(pid, "Memory Usage",
        [{"expr": f'sum by (pod) (container_memory_working_set_bytes{{cluster="{c}",namespace="{n}",container!="",container!="POD"}})', "legend": "{{pod}}"}],
        12, y, unit="bytes"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"Falco — {cluster}", uid_str, [cluster, "falco", "security", "kubernetes"], panels)


def build_postgresql(cluster, namespace, uid_str):
    c, n = cluster, namespace
    panels, pid, y = status_row(1, 0, c, n)

    # replace last stat (replicas) with PVC bound stat
    panels[-1] = p_stat(pid - 1, "PVCs Bound",
        f'sum(kube_persistentvolumeclaim_status_phase{{cluster="{c}",namespace="{n}",phase="Bound"}})',
        18, 1, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )

    rp, pid, y = resource_row(pid, y, c, n)
    panels += rp

    panels.append(p_row(pid, "Storage", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "PVC Capacity Requested",
        [{"expr": f'kube_persistentvolumeclaim_resource_requests_storage_bytes{{cluster="{c}",namespace="{n}"}}', "legend": "{{persistentvolumeclaim}}"}],
        0, y, w=24, unit="bytes"
    )); pid += 1; y += 8

    rp, pid, y = reliability_row(pid, y, c, n)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y)); pid += 1; y += 8

    # pg_* metrics here are exporter-native (no namespace label), unlike the
    # kube_*/container_* metrics above.
    panels.append(p_row(pid, "Database", y)); pid += 1; y += 1

    panels.append(p_stat(pid, "Database Up",
        f'pg_up{{cluster="{c}"}}',
        0, y, w=4, legend="{{pod}}",
        thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1

    panels.append({
        "id": pid, "title": "Uptime", "type": "stat", "datasource": PROM,
        "gridPos": {"x": 4, "y": y, "w": 4, "h": 4},
        "targets": [{"expr": f'time() - pg_postmaster_start_time_seconds{{cluster="{c}"}}', "legendFormat": "{{pod}}", "refId": "A"}],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
            "orientation": "auto", "textMode": "auto",
            "colorMode": "value", "graphMode": "none",
        },
        "fieldConfig": {
            "defaults": {
                "unit": "s",
                "color": {"mode": "thresholds"},
                "thresholds": {"mode": "absolute", "steps": [{"value": None, "color": "green"}]},
                "mappings": [],
            },
            "overrides": [],
        },
    }); pid += 1

    panels.append(p_ts(pid, "Connections vs Limit", [
        {"expr": f'pg_stat_database_numbackends{{cluster="{c}"}}', "legend": "{{datname}} ({{pod}})"},
        {"expr": f'pg_database_connection_limit{{cluster="{c}"}}', "legend": "limit {{datname}} ({{pod}})"},
    ], 8, y, w=8, h=8)); pid += 1

    panels.append({
        "id": pid, "title": "Cache Hit Ratio", "type": "timeseries", "datasource": PROM,
        "gridPos": {"x": 16, "y": y, "w": 8, "h": 8},
        "targets": [{
            "expr": f'pg_stat_database_blks_hit{{cluster="{c}"}} / (pg_stat_database_blks_hit{{cluster="{c}"}} + pg_stat_database_blks_read{{cluster="{c}"}})',
            "legendFormat": "{{datname}} ({{pod}})", "refId": "A",
        }],
        "options": {
            "tooltip": {"mode": "multi", "sort": "desc"},
            "legend": {"displayMode": "table", "placement": "bottom", "calcs": ["lastNotNull", "min"]},
        },
        "fieldConfig": {
            "defaults": {
                "unit": "percentunit", "min": 0, "max": 1,
                "custom": {"lineWidth": 1, "fillOpacity": 10, "gradientMode": "none", "spanNulls": False},
            },
            "overrides": [],
        },
    }); pid += 1; y += 8

    panels.append(p_ts(pid, "Transactions/s", [
        {"expr": f'rate(pg_stat_database_xact_commit{{cluster="{c}"}}[5m])', "legend": "commit {{datname}} ({{pod}})"},
        {"expr": f'rate(pg_stat_database_xact_rollback{{cluster="{c}"}}[5m])', "legend": "rollback {{datname}} ({{pod}})"},
    ], 0, y, w=8, h=8, unit="ops")); pid += 1

    panels.append(p_ts(pid, "Deadlocks", [
        {"expr": f'rate(pg_stat_database_deadlocks{{cluster="{c}"}}[5m])', "legend": "{{datname}} ({{pod}})"},
    ], 8, y, w=8, h=8, unit="ops")); pid += 1

    panels.append(p_ts(pid, "Database Size", [
        {"expr": f'pg_database_size_bytes{{cluster="{c}"}}', "legend": "{{datname}} ({{pod}})"},
    ], 16, y, w=8, h=8, unit="bytes")); pid += 1; y += 8

    panels.append(p_ts(pid, "Replication Lag", [
        {"expr": f'pg_replication_lag_seconds{{cluster="{c}"}} and on(instance) (pg_replication_is_replica{{cluster="{c}"}} == 1)', "legend": "{{pod}}"},
    ], 0, y, w=12, h=8, unit="s"))

    return make_dashboard(f"PostgreSQL — {cluster}", uid_str, [cluster, "postgresql", "database", "kubernetes"], panels)


def build_harbor(cluster, namespace, uid_str):
    c, n = cluster, namespace
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Ready Containers",
        f'sum(kube_pod_container_status_ready{{cluster="{c}",namespace="{n}"}})',
        6, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"}}[24h]))',
        12, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "TLS Cert Expiry (min days)",
        f'min((certmanager_certificate_expiration_timestamp_seconds{{cluster="{c}",namespace="{n}"}} - time()) / 86400)',
        18, y, unit="d", thresholds=[{"value": None, "color": "red"}, {"value": 14, "color": "yellow"}, {"value": 30, "color": "green"}]
    )); pid += 1; y += 4

    rp, pid, y = resource_row(pid, y, c, n)
    panels += rp

    panels.append(p_row(pid, "Garbage Collection (CronJobs)", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Active CronJobs",
        [{"expr": f'sum(kube_cronjob_status_active{{cluster="{c}",namespace="{n}"}})', "legend": "Active"}],
        0, y, w=12, unit="short"
    )); pid += 1
    panels.append(p_ts(pid, "CronJob Last Schedule",
        [{"expr": f'kube_cronjob_status_last_schedule_time{{cluster="{c}",namespace="{n}"}}', "legend": "{{cronjob}}"}],
        12, y, w=12, unit="dateTimeAsIso"
    )); pid += 1; y += 8

    rp, pid, y = reliability_row(pid, y, c, n)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"Harbor — {cluster}", uid_str, [cluster, "harbor", "registry", "kubernetes"], panels)


def build_nextcloud(cluster, namespace, uid_str):
    c, n = cluster, namespace
    # Filter to nextcloud pods only — seaweedfs lives in the same namespace
    pf = ',pod=~"nextcloud.*"'
    df = ',deployment=~"nextcloud.*"'
    panels, pid, y = status_row(1, 0, c, n, pf, df)

    rp, pid, y = resource_row(pid, y, c, n, pf)
    panels += rp

    panels.append(p_row(pid, "Background Jobs", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Active CronJobs",
        [{"expr": f'sum(kube_cronjob_status_active{{cluster="{c}",namespace="{n}"}})', "legend": "Active"}],
        0, y, w=8, unit="short"
    )); pid += 1
    panels.append(p_ts(pid, "Completed Jobs",
        [{"expr": f'sum(kube_job_complete{{cluster="{c}",namespace="{n}"}})', "legend": "Complete"}],
        8, y, w=8, unit="short"
    )); pid += 1
    panels.append(p_ts(pid, "Failed Jobs",
        [{"expr": f'sum(kube_job_failed{{cluster="{c}",namespace="{n}"}})', "legend": "Failed"}],
        16, y, w=8, unit="short"
    )); pid += 1; y += 8

    rp, pid, y = reliability_row(pid, y, c, n, pf)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y, extra_filter=' | pod=~"nextcloud.*"'))

    return make_dashboard(f"Nextcloud — {cluster}", uid_str, [cluster, "nextcloud", "kubernetes"], panels)


def build_s3(cluster, namespace, uid_str):
    """SeaweedFS (S3) in the shared nextcloud-fastnetserv namespace."""
    c, n = cluster, namespace
    pf = ',pod=~"seaweedfs.*"'
    df = ',deployment=~"seaweedfs.*"'
    panels, pid, y = status_row(1, 0, c, n, pf, df)

    rp, pid, y = resource_row(pid, y, c, n, pf)
    panels += rp
    rp, pid, y = reliability_row(pid, y, c, n, pf)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y, extra_filter=' | pod=~"seaweedfs.*"'))

    return make_dashboard(f"S3 / SeaweedFS — {cluster}", uid_str, [cluster, "s3", "seaweedfs", "kubernetes"], panels)


def build_rabbit_netbw(uid_str):
    """Monthly network bandwidth dashboard for rabbit-01-psp Proxmox host.

    Default time range is 'This month' (now/M → now) so that $__range and
    $__range_s expand to the elapsed calendar-month duration, giving exact
    month-to-date totals for quota tracking against the 25 TB housing limit.
    Traffic = inbound + outbound combined, physical interfaces only (site="bgy").
    """
    LIMIT = 25e12  # 25 TB in bytes
    site = "bgy"

    iface = "eth0"
    rx = f'node_network_receive_bytes_total{{site="{site}",device="{iface}",instance="rabbit-01-psp"}}'
    tx = f'node_network_transmit_bytes_total{{site="{site}",device="{iface}",instance="rabbit-01-psp"}}'
    total_mtd = f"sum(increase({rx}[$__range])) + sum(increase({tx}[$__range]))"

    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Monthly Budget — rabbit-01-psp", y)); pid += 1; y += 1

    # Gauge: % of 25 TB used
    panels.append(p_gauge(
        pid, "% of 25 TB Limit",
        f"({total_mtd}) / {LIMIT} * 100",
        x=0, y=y, w=8, h=8,
        unit="percent", min_val=0, max_val=100,
        thresholds=[
            {"value": None, "color": "green"},
            {"value": 70, "color": "yellow"},
            {"value": 90, "color": "orange"},
            {"value": 95, "color": "red"},
        ],
    )); pid += 1

    # Stat: total bytes used this month
    panels.append(p_stat(
        pid, "Used This Month",
        total_mtd,
        x=8, y=y, w=8, h=4,
        unit="decbytes",
        thresholds=[
            {"value": None, "color": "green"},
            {"value": LIMIT * 0.70, "color": "yellow"},
            {"value": LIMIT * 0.90, "color": "orange"},
            {"value": LIMIT * 0.95, "color": "red"},
        ],
        instant=True,
    )); pid += 1

    # Stat: remaining budget
    panels.append(p_stat(
        pid, "Remaining Budget",
        f"{LIMIT} - ({total_mtd})",
        x=16, y=y, w=8, h=4,
        unit="decbytes",
        thresholds=[
            {"value": None, "color": "red"},
            {"value": LIMIT * 0.05, "color": "orange"},
            {"value": LIMIT * 0.10, "color": "yellow"},
            {"value": LIMIT * 0.30, "color": "green"},
        ],
        instant=True,
    )); pid += 1

    y += 4  # move below the first stat row; gauge still extends to y=9

    # Stat: daily average (bytes per day since the 1st)
    panels.append(p_stat(
        pid, "Daily Average",
        f"({total_mtd}) / ($__range_s / 86400)",
        x=8, y=y, w=16, h=4,
        unit="decbytes",
        thresholds=[{"value": None, "color": "blue"}],
        instant=True,
    )); pid += 1

    y += 4  # y=9 — gauge ends here too

    panels.append(p_row(pid, "Traffic Rate", y)); pid += 1; y += 1

    panels.append(p_ts(
        pid, f"Inbound / Outbound Rate ({iface})",
        [
            {"expr": f"rate({rx}[1h])", "legend": "↓ rx"},
            {"expr": f"rate({tx}[1h])", "legend": "↑ tx"},
        ],
        x=0, y=y, w=24, h=8,
        unit="binBps",
    )); pid += 1

    return make_dashboard(
        "rabbit-01-psp — Network Bandwidth",
        uid_str,
        ["proxmox", "rabbit", "network", "bandwidth"],
        panels,
        time_range={"from": "now/M", "to": "now"},
        refresh="5m",
    )


def build_node_resources(cluster, uid_str):
    """Node-scoped resource dashboard using the k8s-monitoring chart's built-in
    low-cardinality resource collector (job=integrations/kubernetes/resources),
    distinct from the standalone prometheus-node-exporter chart on
    k8s-vms-daniele (job=prometheus-node-exporter, deliberately dropped
    upstream — do not use that job here). No namespace filter: node-scoped.
    """
    c = cluster
    jf = ',job="integrations/kubernetes/resources"'
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "CPU", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "CPU Usage by Node",
        [{"expr": f'sum by (instance) (rate(node_cpu_usage_seconds_total{{cluster="{c}"{jf}}}[5m]))', "legend": "{{instance}}"}],
        0, y, w=24, unit="short"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Memory", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Memory Working Set by Node",
        [{"expr": f'node_memory_working_set_bytes{{cluster="{c}"{jf}}}', "legend": "{{instance}}"}],
        0, y, w=24, unit="bytes"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Network", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Network Receive by Node",
        [{"expr": f'rate(node_network_receive_bytes_total{{cluster="{c}"{jf}}}[5m])', "legend": "{{instance}}"}],
        0, y, w=12, unit="Bps"
    )); pid += 1
    panels.append(p_ts(pid, "Network Transmit by Node",
        [{"expr": f'rate(node_network_transmit_bytes_total{{cluster="{c}"{jf}}}[5m])', "legend": "{{instance}}"}],
        12, y, w=12, unit="Bps"
    )); pid += 1

    return make_dashboard(f"Node Resources — {cluster}", uid_str, [cluster, "node-resources", "kubernetes"], panels)


FLUX_JOBS = "flux-operator|kustomize-controller|helm-controller|source-controller|notification-controller"


def build_flux(cluster, uid_str):
    """namespace=flux-system, jobs=FLUX_JOBS on both clusters (confirmed live).
    No per-resource-kind reconcile success/failure panel: the classic
    gotk_reconcile_* metrics are dropped before remote-write by the
    "gotk" alternative in the first write_relabel_config rule in this
    cluster's grafana-alloy release.yml (self-diagnostics cleanup) — that
    data never reaches Grafana Cloud today. Built instead from what's
    actually live: controller-runtime reconcile latency (_sum/_count,
    not _bucket — already dropped by an existing rule), workqueue depth,
    and leader-election status, all confirmed live per controller.
    """
    c, n = cluster, "flux-system"
    jf = f',job=~"{FLUX_JOBS}"'
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Reconciles/s (all controllers)",
        f'sum(rate(controller_runtime_reconcile_time_seconds_count{{cluster="{c}"{jf}}}[5m]))',
        6, y, unit="ops"
    )); pid += 1
    panels.append(p_stat(pid, "Total Workqueue Depth",
        f'sum(workqueue_depth{{cluster="{c}"{jf}}})',
        12, y, thresholds=[{"value": None, "color": "green"}, {"value": 20, "color": "yellow"}, {"value": 100, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"}}[24h]))',
        18, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Reconciliation", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Reconciles/s by Controller",
        [{"expr": f'sum by (job) (rate(controller_runtime_reconcile_time_seconds_count{{cluster="{c}"{jf}}}[5m]))', "legend": "{{job}}"}],
        0, y, w=12, unit="ops"
    )); pid += 1
    panels.append(p_ts(pid, "Avg Reconcile Duration by Controller",
        [{"expr": f'sum by (job) (rate(controller_runtime_reconcile_time_seconds_sum{{cluster="{c}"{jf}}}[5m])) / '
                  f'sum by (job) (rate(controller_runtime_reconcile_time_seconds_count{{cluster="{c}"{jf}}}[5m]))', "legend": "{{job}}"}],
        12, y, w=12, unit="s"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Controller Health", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Workqueue Depth by Controller",
        [{"expr": f'workqueue_depth{{cluster="{c}"{jf}}}', "legend": "{{job}}"}],
        0, y, w=12, unit="short"
    )); pid += 1
    panels.append(p_ts(pid, "Leader Election Status by Controller",
        [{"expr": f'leader_election_master_status{{cluster="{c}"{jf}}}', "legend": "{{job}}"}],
        12, y, w=12, unit="short"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"Flux — {cluster}", uid_str, [cluster, "flux", "gitops", "kubernetes"], panels)


def build_velero(uid_str):
    """kubenuc only. namespace=velero, job=velero (confirmed live)."""
    c, n = "kubenuc", "velero"
    panels, pid, y = status_row(1, 0, c, n)

    panels.append(p_row(pid, "Backups", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Successful (24h)",
        f'sum(increase(velero_backup_success_total{{cluster="{c}"}}[24h]))',
        0, y, w=6, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Failed (24h)",
        f'sum(increase(velero_backup_failure_total{{cluster="{c}"}}[24h]))',
        6, y, w=6, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "Partial Failures (24h)",
        f'sum(increase(velero_backup_partial_failure_total{{cluster="{c}"}}[24h]))',
        12, y, w=6, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}]
    )); pid += 1
    panels.append(p_stat(pid, "Time Since Last Success",
        f'time() - max(velero_backup_last_successful_timestamp{{cluster="{c}"}})',
        18, y, w=6, unit="s", instant=True,
        thresholds=[{"value": None, "color": "green"}, {"value": 172800, "color": "yellow"}, {"value": 259200, "color": "red"}]
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Backup Detail", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Backup Attempts/s by Result",
        [
            {"expr": f'sum(rate(velero_backup_success_total{{cluster="{c}"}}[1h]))', "legend": "success"},
            {"expr": f'sum(rate(velero_backup_failure_total{{cluster="{c}"}}[1h]))', "legend": "failure"},
            {"expr": f'sum(rate(velero_backup_partial_failure_total{{cluster="{c}"}}[1h]))', "legend": "partial failure"},
        ],
        0, y, w=12, unit="ops"
    )); pid += 1
    panels.append(p_ts(pid, "Avg Backup Duration",
        [{"expr": f'sum(rate(velero_backup_duration_seconds_sum{{cluster="{c}"}}[1h])) / '
                  f'sum(rate(velero_backup_duration_seconds_count{{cluster="{c}"}}[1h]))', "legend": "avg duration"}],
        12, y, w=12, unit="s"
    )); pid += 1; y += 8

    panels.append(p_ts(pid, "Items Backed Up / Errors",
        [
            {"expr": f'sum(rate(velero_backup_items_total{{cluster="{c}"}}[1h]))', "legend": "items"},
            {"expr": f'sum(rate(velero_backup_items_errors{{cluster="{c}"}}[1h]))', "legend": "errors"},
        ],
        0, y, w=24, unit="ops"
    )); pid += 1; y += 8

    rp, pid, y = resource_row(pid, y, c, n)
    panels += rp
    rp, pid, y = reliability_row(pid, y, c, n)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"Velero — {c}", uid_str, [c, "velero", "backup", "kubernetes"], panels)


def build_traefik(uid_str):
    """k8s-vms-daniele only. k3s's built-in Traefik, namespace=kube-system,
    job=traefik (confirmed live). Uses the *_requests_total counters, not the
    *_request_duration_seconds_bucket histograms (dropped in Wave 0).
    """
    c, n = "k8s-vms-daniele", "kube-system"
    jf = ',job="traefik"'
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",pod=~"traefik.*",phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Requests/s (all entrypoints)",
        f'sum(rate(traefik_entrypoint_requests_total{{cluster="{c}"{jf}}}[5m]))',
        6, y, unit="reqps"
    )); pid += 1
    panels.append(p_stat(pid, "5xx/s",
        f'sum(rate(traefik_entrypoint_requests_total{{cluster="{c}"{jf},code=~"5.."}}[5m]))',
        12, y, unit="reqps",
        thresholds=[{"value": None, "color": "green"}, {"value": 0.1, "color": "yellow"}, {"value": 1, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}",pod=~"traefik.*"}}[24h]))',
        18, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Requests", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Requests/s by Entrypoint",
        [{"expr": f'sum by (entrypoint) (rate(traefik_entrypoint_requests_total{{cluster="{c}"{jf}}}[5m]))', "legend": "{{entrypoint}}"}],
        0, y, w=12, unit="reqps"
    )); pid += 1
    panels.append(p_ts(pid, "Requests/s by Service",
        [{"expr": f'sum by (service) (rate(traefik_service_requests_total{{cluster="{c}"{jf}}}[5m]))', "legend": "{{service}}"}],
        12, y, w=12, unit="reqps"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Errors", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Requests/s by Status Code",
        [{"expr": f'sum by (code) (rate(traefik_entrypoint_requests_total{{cluster="{c}"{jf}}}[5m]))', "legend": "{{code}}"}],
        0, y, w=24, unit="reqps"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y, extra_filter=' | pod=~"traefik.*"'))

    return make_dashboard(f"Traefik — {c}", uid_str, [c, "traefik", "ingress", "kubernetes"], panels)


# ---------------------------------------------------------------------------
# grafana.com community-dashboard imports
#
# Raw dashboard JSON fetched from grafana.com is checked into templates/ and
# adapted here (never hand-pasted into dashboards/ directly - the CI drift
# guard runs this generator and fails if its output doesn't match committed
# JSON byte-for-byte, so the adaptation has to be code, not a one-time edit).
# ---------------------------------------------------------------------------

def load_grafana_template(name):
    base = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(base, "templates", f"{name}.json")) as f:
        return json.load(f)


def _fix_datasource_refs(obj):
    """Recursively replace grafana.com's ${DS_PROMETHEUS}-style datasource
    template-variable references with this repo's concrete datasource."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == "datasource" and isinstance(v, str) and v.startswith("${DS_"):
                obj[k] = PROM
            else:
                _fix_datasource_refs(v)
    elif isinstance(obj, list):
        for item in obj:
            _fix_datasource_refs(item)


def _remove_row_and_contents(panels, row_title):
    """Remove a row panel and every panel between it and the next row
    (exclusive) - grafana.com dashboards from this era use a flat panel
    list with plain "row" markers, not nested collapsed-row panels."""
    result = []
    skipping = False
    for p in panels:
        if p.get("type") == "row":
            skipping = (p.get("title") == row_title)
            if skipping:
                continue
        if not skipping:
            result.append(p)
    return result


def build_coredns_from_template(cluster, uid_str):
    """Adapted from grafana.com dashboard 14981 ("CoreDNS", org beryju,
    fetched 2026-08-24, checked in verbatim at templates/coredns-14981.json).

    Every remaining query is rewritten to add cluster="{cluster}" and
    job="kube-dns" - NOT cosmetic. Confirmed live that both kubenuc and
    k8s-vms-daniele's CoreDNS report the *literal identical* instance label
    value (kube-dns.kube-system.svc:9153, from Service-based scraping), so
    without an explicit cluster filter this dashboard would silently sum
    both clusters' data together under the same series. Every other
    hand-rolled dashboard in this file already includes an explicit
    cluster= match for the same underlying reason; this template didn't,
    since it was written for a single-cluster Prometheus.

    Adaptations required to match this environment (confirmed live before
    editing, not guessed):
      - job="coredns" -> job="kube-dns": this cluster's Service is named
        kube-dns, not coredns.
      - The $instance variable's underlying query used up{job=...}, but
        `up` is dropped from remote-write by an existing (pre-existing,
        unrelated to this change) write_relabel_config rule - switched to
        coredns_build_info{...}, which is live and one series per instance.
      - Dropped the entire "Upstream" row (5 panels: coredns_forward_*
        request/cache/latency/response panels) - this CoreDNS build reports
        forwarding latency under the "proxy" plugin
        (coredns_proxy_request_duration_seconds_*), not "forward"; none of
        coredns_forward_requests_total/_conn_cache_hits_total/
        _request_duration_seconds_bucket/_responses_total are live here.
      - Dropped "CPU Time"/"Memory Usage" panels
        (process_cpu_seconds_total, go_memstats_alloc_bytes) - both are
        dropped from remote-write by the existing generic go_/process_
        self-diagnostics rule.
      - Dropped "Requests (DNSSEC by zone)" and the DNSSEC target lines in
        "Cache (hitrate)"/"Cache (size)" -
        coredns_dnssec_cache_hits_total/_entries and
        coredns_dns_do_requests_total don't exist (DNSSEC plugin isn't
        enabled in this cluster's Corefile).
      - Confirmed zone="." is genuinely this cluster's only zone value
        (catch-all Corefile) before keeping the zone="."-filtered panels
        as-is.
    """
    c = cluster
    d = load_grafana_template("coredns-14981")

    _fix_datasource_refs(d)
    d["templating"]["list"] = [v for v in d["templating"]["list"] if v.get("type") != "datasource"]
    for v in d["templating"]["list"]:
        if v.get("name") == "instance":
            q = f'label_values(coredns_build_info{{cluster="{c}",job="kube-dns"}}, instance)'
            v["definition"] = q
            v["query"]["query"] = q

    panels = _remove_row_and_contents(d["panels"], "Upstream")
    panels = [p for p in panels if p.get("title") not in
              ("CPU Time", "Memory Usage", "Requests (DNSSEC by zone)")]

    scope = f'cluster="{c}",job="kube-dns",'
    for p in panels:
        if p.get("type") == "row":
            continue
        kept_targets = []
        for t in p.get("targets", []):
            expr = t.get("expr", "")
            if "dnssec" in expr.lower() or "coredns_dns_do_requests_total" in expr:
                continue  # DNSSEC-only lines within an otherwise-kept panel
            if '{instance=~"$instance"' in expr:
                expr = expr.replace('{instance=~"$instance"', "{" + scope + 'instance=~"$instance"')
            elif expr.startswith("coredns_") or expr.startswith("sum(rate(coredns_"):
                # The one target with no label matcher at all
                # ("Requests (by instance)": sum(rate(coredns_dns_requests_total[5m])) by (instance))
                expr = expr.replace("[5m])", "{" + scope.rstrip(",") + "}[5m])", 1)
            t["expr"] = expr
            kept_targets.append(t)
        p["targets"] = kept_targets

    d["panels"] = panels
    d["title"] = f"CoreDNS — {c}"
    d["uid"] = uid_str
    d["tags"] = [c, "coredns", "kubernetes"]
    d["id"] = None
    d["version"] = 1
    d["editable"] = True
    return d


def build_cloudflared(uid_str):
    """kubenuc only. namespace=cloudflare, job=cloudflared (confirmed live)."""
    c, n = "kubenuc", "cloudflare"
    jf = ',job="cloudflared"'
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Requests/s",
        f'sum(rate(cloudflared_tunnel_total_requests{{cluster="{c}"{jf}}}[5m]))',
        6, y, unit="reqps"
    )); pid += 1
    panels.append(p_stat(pid, "Errors/s",
        f'sum(rate(cloudflared_tunnel_request_errors{{cluster="{c}"{jf}}}[5m]))',
        12, y, unit="reqps",
        thresholds=[{"value": None, "color": "green"}, {"value": 0.1, "color": "yellow"}, {"value": 1, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "HA Connections (min per pod)",
        f'min(cloudflared_tunnel_ha_connections{{cluster="{c}"{jf}}})',
        18, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Requests", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Requests/s by Pod",
        [{"expr": f'sum by (pod) (rate(cloudflared_tunnel_total_requests{{cluster="{c}"{jf}}}[5m]))', "legend": "{{pod}}"}],
        0, y, w=12, unit="reqps"
    )); pid += 1
    panels.append(p_ts(pid, "Responses/s by Status Code",
        [{"expr": f'sum by (status_code) (rate(cloudflared_tunnel_response_by_code{{cluster="{c}"{jf}}}[5m]))', "legend": "{{status_code}}"}],
        12, y, w=12, unit="reqps"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Sessions", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Active TCP/UDP Sessions",
        [
            {"expr": f'sum(cloudflared_tcp_active_sessions{{cluster="{c}"{jf}}})', "legend": "tcp"},
            {"expr": f'sum(cloudflared_udp_active_sessions{{cluster="{c}"{jf}}})', "legend": "udp"},
        ],
        0, y, w=24, unit="short"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"Cloudflare Tunnel — {c}", uid_str, [c, "cloudflared", "networking", "kubernetes"], panels)


def build_teleport_agent(uid_str):
    """k8s-vms-daniele only. namespace=teleport-agent, job=teleport-agent
    (confirmed live). No /metrics request-rate counters exist for the agent
    itself (it's a connection-holding proxy, not an HTTP server) — built
    from cache/resource health and connection-attempt signals instead.
    """
    c, n = "k8s-vms-daniele", "teleport-agent"
    jf = ',job="teleport-agent"'
    panels = []
    pid, y = 1, 0

    panels.append(p_row(pid, "Status", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Running Pods",
        f'sum(kube_pod_status_phase{{cluster="{c}",namespace="{n}",phase="Running"}})',
        0, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Kubernetes Resource Healthy",
        f'min(teleport_resources_health_status_healthy{{cluster="{c}"{jf},type="kubernetes"}})',
        6, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Cache Healthy (kube)",
        f'min(teleport_cache_health{{cluster="{c}"{jf},cache_component="kube"}})',
        12, y, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Restarts (24h)",
        f'sum(increase(kube_pod_container_status_restarts_total{{cluster="{c}",namespace="{n}"}}[24h]))',
        18, y, thresholds=[{"value": None, "color": "green"}, {"value": 1, "color": "yellow"}, {"value": 5, "color": "red"}]
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Connectivity", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Connect-to-Node Attempts/s",
        [{"expr": f'sum(rate(teleport_connect_to_node_attempts_total{{cluster="{c}"{jf}}}[5m]))', "legend": "attempts/s"}],
        0, y, w=12, unit="ops"
    )); pid += 1
    panels.append(p_ts(pid, "Resource Health Status by Type",
        [
            {"expr": f'sum by (type) (teleport_resources_health_status_healthy{{cluster="{c}"{jf}}})', "legend": "{{type}} healthy"},
            {"expr": f'sum by (type) (teleport_resources_health_status_unknown{{cluster="{c}"{jf}}})', "legend": "{{type}} unknown"},
        ],
        12, y, w=12, unit="short"
    )); pid += 1; y += 8

    rp, pid, y = resource_row(pid, y, c, n)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y))

    return make_dashboard(f"Teleport Agent — {c}", uid_str, [c, "teleport", "kubernetes"], panels)


def build_authentik(uid_str):
    """kubenuc only. namespace=sso, job=authentik (confirmed live). The sso
    namespace also runs Zitadel (unrelated) - pod/deployment filters scope
    to authentik-* only, matching the nextcloud/s3 shared-namespace pattern.
    Histogram _bucket metrics were dropped for cardinality (see
    grafana-alloy release.yml) - uses _sum/_count for average duration
    instead of histogram_quantile().
    """
    c, n = "kubenuc", "sso"
    jf = ',job="authentik"'
    pf = ',pod=~"authentik-.*"'
    df = ',deployment=~"authentik-.*"'
    panels, pid, y = status_row(1, 0, c, n, pf, df)

    panels.append(p_row(pid, "Tasks", y)); pid += 1; y += 1
    panels.append(p_stat(pid, "Workers",
        f'sum(authentik_tasks_workers{{cluster="{c}"{jf}}})',
        0, y, w=6, thresholds=[{"value": None, "color": "red"}, {"value": 1, "color": "green"}]
    )); pid += 1
    panels.append(p_stat(pid, "Tasks In Progress",
        f'sum(authentik_tasks_in_progress{{cluster="{c}"{jf}}})',
        6, y, w=6
    )); pid += 1
    panels.append(p_stat(pid, "Tasks Queued",
        f'sum(authentik_tasks_queued{{cluster="{c}"{jf}}})',
        12, y, w=6,
        thresholds=[{"value": None, "color": "green"}, {"value": 20, "color": "yellow"}, {"value": 100, "color": "red"}]
    )); pid += 1
    panels.append(p_stat(pid, "Outposts Connected",
        f'sum(authentik_outposts_connected{{cluster="{c}"{jf}}})',
        18, y, w=6
    )); pid += 1; y += 4

    panels.append(p_row(pid, "Requests", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Request Rate by Destination",
        [{"expr": f'sum by (dest) (rate(authentik_main_request_duration_seconds_count{{cluster="{c}"{jf}}}[5m]))', "legend": "{{dest}}"}],
        0, y, w=12, unit="reqps"
    )); pid += 1
    panels.append(p_ts(pid, "Avg Request Duration by Destination",
        [{"expr": f'sum by (dest) (rate(authentik_main_request_duration_seconds_sum{{cluster="{c}"{jf}}}[5m])) / '
                  f'sum by (dest) (rate(authentik_main_request_duration_seconds_count{{cluster="{c}"{jf}}}[5m]))', "legend": "{{dest}}"}],
        12, y, w=12, unit="s"
    )); pid += 1; y += 8

    panels.append(p_row(pid, "Task Queue by Actor", y)); pid += 1; y += 1
    panels.append(p_ts(pid, "Top 10 Queued Task Types",
        [{"expr": f'topk(10, sum by (actor_name) (authentik_tasks_queued{{cluster="{c}"{jf}}}))', "legend": "{{actor_name}}"}],
        0, y, w=24, unit="short"
    )); pid += 1; y += 8

    rp, pid, y = resource_row(pid, y, c, n, pf)
    panels += rp
    rp, pid, y = reliability_row(pid, y, c, n, pf)
    panels += rp

    panels.append(p_row(pid, "Logs", y)); pid += 1; y += 1
    panels.append(p_logs(pid, c, n, y, extra_filter=' | pod=~"authentik-.*"'))

    return make_dashboard(f"Authentik (SSO) — {c}", uid_str, [c, "sso", "authentik", "kubernetes"], panels)


# ---------------------------------------------------------------------------
# App registry
# ---------------------------------------------------------------------------

# (file_name, namespace, display_name, dashboard_type)
APPS = {
    "kubenuc": [
        ("1password",                "1password",             "1Password",                    "standard"),
        ("cert-manager",             "cert-manager",          "cert-manager",                  "cert-manager"),
        ("cloudflare",               "cloudflare",            "Cloudflare Tunnel",             "cloudflared"),
        ("coredns",                  "kube-system",           "CoreDNS",                       "coredns"),
        ("falco",                    "falco",                 "Falco",                         "falco"),
        ("film-tv-exporter",         "film-tv",               "Film/TV Exporter",              "no-container"),
        ("flux",                     "flux-system",           "Flux",                          "flux"),
        ("grafana-alloy",            "grafana-alloy",         "Grafana Alloy",                 "standard"),
        ("haproxy-ingress",          "haproxy-ingress",       "HAProxy Ingress",               "standard"),
        ("harbor",                   "harbor",                "Harbor Registry",               "harbor"),
        ("jellyfin",                 "jellyfin",              "Jellyfin",                      "standard"),
        ("jenkins",                  "jenkins",               "Jenkins",                       "standard"),
        ("net-mon",                  "net-mon",               "Net-Mon",                       "standard"),
        ("nextcloud",                "nextcloud-fastnetserv", "Nextcloud",                     "nextcloud"),
        ("node-resources",           None,                    "Node Resources",                "node-resources"),
        ("nut",                      "nut",                   "NUT Exporter",                  "standard"),
        ("openebs",                  "openebs",               "OpenEBS",                       "standard"),
        ("postgresql",               "databases",             "PostgreSQL (Zalando)",          "postgresql"),
        ("s3",                       "nextcloud-fastnetserv", "S3 / SeaweedFS",               "s3"),
        ("sso",                      "sso",                   "Authentik (SSO)",               "authentik"),
        ("system-upgrade-controller","system-upgrade",        "System Upgrade Controller",     "standard"),
        ("velero",                   "velero",                "Velero",                        "velero"),
    ],
    "k8s-vms-daniele": [
        ("1password",                "1password",             "1Password",                    "standard"),
        ("awx",                      "awx",                   "AWX",                           "standard"),
        ("blackbox",                 "monitoring",            "Blackbox Exporter",             "standard"),
        ("cert-manager",             "cert-manager",          "cert-manager",                  "cert-manager"),
        ("cloudflare",               "cloudflare",            "Cloudflare Tunnel",             "standard"),
        ("coredns",                  "kube-system",           "CoreDNS",                       "coredns"),
        ("falco",                    "falco",                 "Falco",                         "falco"),
        ("flux",                     "flux-system",           "Flux",                          "flux"),
        ("grafana-alloy",            "grafana-alloy",         "Grafana Alloy",                 "standard"),
        ("node-exporter",            "node-exporter",         "Node Exporter",                 "standard"),
        ("node-resources",           None,                    "Node Resources",                "node-resources"),
        ("system-upgrade-controller","system-upgrade",        "System Upgrade Controller",     "standard"),
        ("teleport-agent",           "teleport-agent",        "Teleport Agent",                "teleport-agent-diag"),
        ("traefik",                  "kube-system",           "Traefik",                       "traefik"),
    ],
    "proxmox": [
        ("rabbit-netbw", None, "rabbit-01-psp Network Bandwidth", "rabbit-netbw"),
    ],
}


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    total = 0

    for cluster, apps in APPS.items():
        out_dir = os.path.join(base, "dashboards", cluster)
        os.makedirs(out_dir, exist_ok=True)

        for file_name, namespace, display, app_type in apps:
            uid_str = stable_uid(cluster, file_name)

            builders = {
                "standard":     lambda c, fn, ns, d, u: build_standard(c, fn, ns, d, u),
                "no-container": lambda c, fn, ns, d, u: build_standard(c, fn, ns, d, u, has_container=False),
                "cert-manager": lambda c, fn, ns, d, u: build_cert_manager(c, ns, u),
                "falco":        lambda c, fn, ns, d, u: build_falco(c, ns, u),
                "postgresql":   lambda c, fn, ns, d, u: build_postgresql(c, ns, u),
                "harbor":       lambda c, fn, ns, d, u: build_harbor(c, ns, u),
                "nextcloud":    lambda c, fn, ns, d, u: build_nextcloud(c, ns, u),
                "s3":           lambda c, fn, ns, d, u: build_s3(c, ns, u),
                "rabbit-netbw": lambda c, fn, ns, d, u: build_rabbit_netbw(u),
                "node-resources": lambda c, fn, ns, d, u: build_node_resources(c, u),
                "coredns":      lambda c, fn, ns, d, u: build_coredns_from_template(c, u),
                "flux":         lambda c, fn, ns, d, u: build_flux(c, u),
                "velero":       lambda c, fn, ns, d, u: build_velero(u),
                "traefik":      lambda c, fn, ns, d, u: build_traefik(u),
                "cloudflared":  lambda c, fn, ns, d, u: build_cloudflared(u),
                "teleport-agent-diag": lambda c, fn, ns, d, u: build_teleport_agent(u),
                "authentik":    lambda c, fn, ns, d, u: build_authentik(u),
            }

            dash = builders[app_type](cluster, file_name, namespace, display, uid_str)

            out_path = os.path.join(out_dir, f"{file_name}.json")
            with open(out_path, "w") as f:
                json.dump(dash, f, indent=2)
                f.write("\n")

            print(f"  {out_path.replace(base + '/', '')}")
            total += 1

    print(f"\nGenerated {total} dashboards.")


if __name__ == "__main__":
    main()
