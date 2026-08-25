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
import re

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
    template-variable references with this repo's concrete datasource.
    Two shapes seen across templates: a bare string ("${DS_PROMETHEUS}",
    e.g. the CoreDNS import) and an object ({"uid": "${DS_PROMETHEUS}"},
    e.g. the Flux import) - handle both, not just the first one found."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == "datasource" and isinstance(v, str) and v.startswith("${DS_"):
                obj[k] = PROM
            elif k == "datasource" and isinstance(v, dict) and isinstance(v.get("uid"), str) and v["uid"].startswith("${DS_"):
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


def _normalize_imported_dashboard_metadata(d, title, uid_str, tags, time_range=None):
    """grafana.com dashboards carry their own author's refresh/schemaVersion/
    timezone/time-range preferences, which have nothing to do with this
    repo's convention and don't get reset just by swapping panels/queries.
    Confirmed both templates used here shipped a far more aggressive
    refresh than every hand-rolled dashboard in this file (CoreDNS: 5s,
    12x more query load than the repo's 1m default; Flux: 10s) - matches
    make_dashboard()'s own defaults so an imported dashboard behaves like
    every other one in this repo instead of quietly hammering Grafana
    Cloud on its author's original schedule.
    """
    d["title"] = title
    d["uid"] = uid_str
    d["tags"] = tags
    d["id"] = None
    d["version"] = 1
    d["editable"] = True
    d["refresh"] = "1m"
    d["schemaVersion"] = 38
    d["timezone"] = "browser"
    d["time"] = time_range or {"from": "now-6h", "to": "now"}
    d["timepicker"] = {}
    # grafana.com's export format ships __inputs/__requires scaffolding for
    # its own "Import Dashboard" UI (datasource picker, plugin version
    # checks) - inert here (not read by Terraform's grafana_dashboard
    # resource or any panel), but leaving it in means a stale "DS_PROMETHEUS"
    # string sits in the committed JSON despite every real datasource
    # reference already being fixed up above.
    d.pop("__inputs", None)
    d.pop("__requires", None)
    return d


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
    return _normalize_imported_dashboard_metadata(
        d, f"CoreDNS — {c}", uid_str, [c, "coredns", "kubernetes"]
    )


def _replace_exprs_exact(panels, mapping):
    """Rewrite every target's expr via an exact-string lookup, dropping any
    target mapped to None. Raises if a target's expr isn't in the mapping -
    fail loud rather than silently ship an unadapted (and possibly
    cross-cluster-unscoped) query."""
    for p in panels:
        if p.get("type") == "row":
            continue
        kept = []
        for t in p.get("targets", []):
            expr = t.get("expr", "")
            if expr not in mapping:
                raise KeyError(f'No adaptation mapped for expr in panel "{p.get("title")}": {expr!r}')
            new_expr = mapping[expr]
            if new_expr is None:
                continue
            t["expr"] = new_expr
            kept.append(t)
        p["targets"] = kept


def build_flux_from_template(cluster, uid_str):
    """Adapted from grafana.com dashboard 21150 / the official FluxCD
    "Flux Control Plane" dashboard (fluxcd/flux2-monitoring-example,
    monitoring/configs/dashboards/control-plane.json, fetched 2026-08-24,
    checked in verbatim at templates/flux-control-plane.json).

    The companion "Flux Cluster Stats" dashboard was evaluated and
    rejected: 100% of its panels depend on gotk_resource_info, which is
    dropped from remote-write entirely by an existing (pre-existing,
    unrelated to this change) write_relabel_config rule matching gotk_.* -
    there's no substitute metric with per-resource-kind readiness/
    suspension data, so nothing in that dashboard could ever render.

    Control Plane needed heavier rewriting than CoreDNS - every target
    expr is replaced via an exact-string lookup (not substring surgery),
    since several metrics needed full substitution, not just added label
    scope. Every mapping below was checked against a live query before
    writing it (not guessed):
      - go_info / go_memstats_alloc_bytes / process_cpu_seconds_total are
        all dropped by an existing generic go_/process_ self-diagnostics
        rule - replaced with kube_pod_status_phase (controller pod count),
        container_memory_working_set_bytes, and
        container_cpu_usage_seconds_total respectively (all confirmed
        live for the flux-system namespace, same metrics this file's
        other builders already use throughout).
      - controller_runtime_reconcile_time_seconds_bucket is dropped by an
        existing rule (predates this file, drops that specific _bucket
        while keeping _sum/_count) - the 3 P50/P90/P99
        histogram_quantile() targets in "Helm Release Duration" collapse
        to a single avg-duration line via _sum/_count, same tradeoff used
        throughout this file's hand-rolled builders.
      - controller_runtime_reconcile_total, rest_client_requests_total,
        and workqueue_longest_running_processor_seconds are all confirmed
        live with the exact controller=/code=/name= label values this
        template expects (kustomization, gitrepository, ocirepository,
        helmrepository, bucket, helmrelease, helmchart controllers; HTTP
        status codes; workqueue name "kustomization").
      - The $namespace template variable (upstream default "flux-system",
        sourced from a regex-extracted label_values query) is dropped in
        favor of hardcoding namespace="flux-system" directly, which is
        already this cluster's real Flux namespace and avoids depending
        on yet another live-verified variable query for a value that
        never actually varies here.
      - Every target gets an explicit cluster="{cluster}" scope added -
        the upstream dashboard has none (written for a single-cluster
        Prometheus), and while Flux pod names (unlike CoreDNS's
        Service-based instance label) aren't guaranteed to collide across
        clusters, every other dashboard in this file scopes by cluster
        for the same underlying reason, and Flux genuinely runs on both
        clusters here.
    """
    c = cluster
    ns = "flux-system"
    scope = f'cluster="{c}",namespace="{ns}",'
    d = load_grafana_template("flux-control-plane")

    _fix_datasource_refs(d)
    d["templating"]["list"] = [v for v in d["templating"]["list"] if v.get("type") != "datasource"]
    d["templating"]["list"] = [v for v in d["templating"]["list"] if v.get("name") != "namespace"]

    mapping = {
        'sum(go_info{namespace="$namespace",pod=~".*-controller-.*"})':
            f'sum(kube_pod_status_phase{{{scope}phase="Running"}})',
        'max(workqueue_longest_running_processor_seconds{namespace="$namespace",pod=~".*-controller-.*"})':
            f'max(workqueue_longest_running_processor_seconds{{{scope.rstrip(",")}}})',
        'sum(go_memstats_alloc_bytes{namespace="$namespace",pod=~".*-controller-.*"})':
            f'sum(container_memory_working_set_bytes{{{scope}container!="",container!="POD"}})',
        'sum(rate(rest_client_requests_total{namespace="$namespace",pod=~".*-controller-.*"}[1m]))':
            f'sum(rate(rest_client_requests_total{{{scope.rstrip(",")}}}[1m]))',
        'sum(rate(rest_client_requests_total{namespace="$namespace"}[1m]))':
            f'sum(rate(rest_client_requests_total{{{scope.rstrip(",")}}}[1m]))',
        'sum(rate(rest_client_requests_total{namespace="$namespace",code!~"2.."}[1m]))':
            f'sum(rate(rest_client_requests_total{{{scope}code!~"2.."}}[1m]))',
        'rate(process_cpu_seconds_total{namespace="$namespace",pod=~".*-controller-.*"}[1m])':
            f'sum by (pod) (rate(container_cpu_usage_seconds_total{{{scope}container!="",container!="POD"}}[1m]))',
        'sum(container_memory_working_set_bytes{namespace="$namespace",container!="POD",container!="",pod=~".*-controller-.*"}) by (pod)':
            f'sum by (pod) (container_memory_working_set_bytes{{{scope}container!="",container!="POD"}})',
        'workqueue_longest_running_processor_seconds{name="kustomization"}':
            f'workqueue_longest_running_processor_seconds{{{scope}name="kustomization"}}',
        'sum(increase(controller_runtime_reconcile_total{controller="kustomization",result!="error"}[1m])) by (controller)':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="kustomization",result!="error"}}[1m])) by (controller)',
        'sum(increase(controller_runtime_reconcile_total{controller="kustomization",result="error"}[1m])) by (controller)':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="kustomization",result="error"}}[1m])) by (controller)',
        'sum(increase(controller_runtime_reconcile_total{controller="gitrepository",result!="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="gitrepository",result!="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="gitrepository",result="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="gitrepository",result="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="ocirepository",result!="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="ocirepository",result!="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="ocirepository",result="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="ocirepository",result="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="helmrepository",result!="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="helmrepository",result!="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="helmrepository",result="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="helmrepository",result="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="bucket",result!="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="bucket",result!="error"}}[1m]))',
        'sum(increase(controller_runtime_reconcile_total{controller="bucket",result="error"}[1m]))':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="bucket",result="error"}}[1m]))',
        'histogram_quantile(0.50, sum(rate(controller_runtime_reconcile_time_seconds_bucket{controller="helmrelease"}[5m])) by (le))':
            f'sum(rate(controller_runtime_reconcile_time_seconds_sum{{{scope}controller="helmrelease"}}[5m])) / '
            f'sum(rate(controller_runtime_reconcile_time_seconds_count{{{scope}controller="helmrelease"}}[5m]))',
        'histogram_quantile(0.90, sum(rate(controller_runtime_reconcile_time_seconds_bucket{controller="helmrelease"}[5m])) by (le))':
            None,
        'histogram_quantile(0.99, sum(rate(controller_runtime_reconcile_time_seconds_bucket{controller="helmrelease"}[5m])) by (le))':
            None,
        'sum(increase(controller_runtime_reconcile_total{controller="helmrelease",result!="error"}[1m])) by (controller)':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="helmrelease",result!="error"}}[1m])) by (controller)',
        'sum(increase(controller_runtime_reconcile_total{controller="helmrelease",result="error"}[1m])) by (controller)':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="helmrelease",result="error"}}[1m])) by (controller)',
        'sum(increase(controller_runtime_reconcile_total{controller="helmchart",result!="error"}[1m])) by (controller)':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="helmchart",result!="error"}}[1m])) by (controller)',
        'sum(increase(controller_runtime_reconcile_total{controller="helmchart",result="error"}[1m])) by (controller)':
            f'sum(increase(controller_runtime_reconcile_total{{{scope}controller="helmchart",result="error"}}[1m])) by (controller)',
    }

    panels = d["panels"]
    _replace_exprs_exact(panels, mapping)

    # "Helm Release Duration" now carries only one target (the P50 slot,
    # repurposed as the avg line) - fix its legend from "P50" to "avg".
    for p in panels:
        if p.get("title") == "Helm Release Duration":
            for t in p.get("targets", []):
                t["legendFormat"] = "avg"

    return _normalize_imported_dashboard_metadata(
        d, f"Flux — {c}", uid_str, [c, "flux", "gitops", "kubernetes"]
    )


def build_cloudflared_from_template(uid_str):
    """kubenuc only. Adapted from grafana.com dashboard 17457 ("Cloudflare
    Tunnels (cloudflared)", org tylerobrien, 206K downloads, fetched
    2026-08-25, checked in verbatim at
    templates/cloudflare-tunnel-17457.json).

    100% metric compatibility confirmed live before adapting - all 6
    panels use metric names that exist verbatim in this cluster's
    cloudflared_* series (job="cloudflared", namespace=cloudflare). No
    panels dropped, no template variables to strip (this template ships
    none), no incompatible metrics. Every target still needs an explicit
    cluster="kubenuc" scope added - the upstream dashboard has none
    (written for a single-cluster Prometheus), same reasoning as every
    other imported dashboard in this file.
    """
    c, n = "kubenuc", "cloudflare"
    scope = f'cluster="{c}",job="cloudflared",'
    d = load_grafana_template("cloudflare-tunnel-17457")

    _fix_datasource_refs(d)

    mapping = {
        "cloudflared_tunnel_ha_connections":
            f"cloudflared_tunnel_ha_connections{{{scope.rstrip(',')}}}",
        "cloudflared_tunnel_concurrent_requests_per_tunnel":
            f"cloudflared_tunnel_concurrent_requests_per_tunnel{{{scope.rstrip(',')}}}",
        "sum by(status_code) (increase(cloudflared_tunnel_response_by_code[$__rate_interval]))":
            f"sum by(status_code) (increase(cloudflared_tunnel_response_by_code{{{scope.rstrip(',')}}}[$__rate_interval]))",
        "sum by(instance) (increase(cloudflared_tunnel_total_requests[$__rate_interval]))":
            f"sum by(instance) (increase(cloudflared_tunnel_total_requests{{{scope.rstrip(',')}}}[$__rate_interval]))",
        "changes(cloudflared_orchestration_config_version[$__interval])":
            f"changes(cloudflared_orchestration_config_version{{{scope.rstrip(',')}}}[$__interval])",
        "increase(cloudflared_tunnel_request_errors[$__rate_interval])":
            f"increase(cloudflared_tunnel_request_errors{{{scope.rstrip(',')}}}[$__rate_interval])",
    }

    _replace_exprs_exact(d["panels"], mapping)

    return _normalize_imported_dashboard_metadata(
        d, f"Cloudflare Tunnel — {c}", uid_str, [c, "cloudflared", "networking", "kubernetes"]
    )


def build_traefik_from_template(uid_str):
    """k8s-vms-daniele only. Adapted from grafana.com dashboard 17347
    ("Traefik Official Kubernetes Dashboard", official Traefik Labs, 6.8M
    downloads, fetched 2026-08-25, checked in verbatim at
    templates/traefik-17347.json). k3s's built-in Traefik, namespace=
    kube-system, job=traefik (confirmed live).

    Adaptations required to match this environment (confirmed live before
    editing, not guessed):
      - "Apdex score" used traefik_entrypoint_request_duration_seconds_
        bucket at le="0.3"/le="1.2" - that _bucket metric is dropped from
        remote-write by an existing (pre-existing, unrelated to this
        change) write_relabel_config rule (Wave 0 cardinality trim, 510
        series). Real Apdex can't be approximated from _sum/_count alone
        (it's a threshold-satisfaction ratio, not an average), so this
        panel is repurposed as "Avg Entrypoint Request Duration" using
        traefik_entrypoint_request_duration_seconds_sum/_count instead -
        same collapse-to-avg tradeoff already used for Flux's Helm
        Release Duration panel.
      - Every other panel's traefik_service_*/traefik_entrypoint_*/
        traefik_config_reloads_total/traefik_open_connections metrics are
        all confirmed live and unaffected by any drop rule.
      - The $entrypoint and $service template variables stay (both
        label_values queries resolve against live label values here) -
        the "SLO" row (empty in the upstream template - a bare section
        divider with no panels under it) is left as-is, matching upstream
        layout.
      - Every target gets an explicit cluster="k8s-vms-daniele" scope
        added - the upstream dashboard has none (written for a
        single-cluster Prometheus).
    """
    c, n = "k8s-vms-daniele", "kube-system"
    scope = f'cluster="{c}",job="traefik",'
    d = load_grafana_template("traefik-17347")

    _fix_datasource_refs(d)
    d["templating"]["list"] = [v for v in d["templating"]["list"] if v.get("type") != "datasource"]

    mapping = {
        "count(traefik_config_reloads_total)":
            f"count(traefik_config_reloads_total{{{scope.rstrip(',')}}})",
        "sum(rate(traefik_entrypoint_requests_total{entrypoint=~\"$entrypoint\"}[$interval])) by (entrypoint)":
            f"sum(rate(traefik_entrypoint_requests_total{{{scope}entrypoint=~\"$entrypoint\"}}[$interval])) by (entrypoint)",
        '(sum(rate(traefik_entrypoint_request_duration_seconds_bucket{le="0.3",code="200",entrypoint=~"$entrypoint"}[$interval])) by (method) + \n sum(rate(traefik_entrypoint_request_duration_seconds_bucket{le="1.2",code="200",entrypoint=~"$entrypoint"}[$interval])) by (method)) / 2 / \n sum(rate(traefik_entrypoint_request_duration_seconds_count{code="200",entrypoint=~"$entrypoint"}[$interval])) by (method)\n':
            f'sum(rate(traefik_entrypoint_request_duration_seconds_sum{{{scope}code="200",entrypoint=~"$entrypoint"}}[$interval])) by (method) / \nsum(rate(traefik_entrypoint_request_duration_seconds_count{{{scope}code="200",entrypoint=~"$entrypoint"}}[$interval])) by (method)\n',
        'sum(rate(traefik_service_requests_total{service=~"$service.*",protocol="http"}[$interval])) by (method, code)':
            f'sum(rate(traefik_service_requests_total{{{scope}service=~"$service.*",protocol="http"}}[$interval])) by (method, code)',
        'topk(15,\n    label_replace(\n        traefik_service_request_duration_seconds_sum{service=~"$service.*",protocol="http"} / \n          traefik_service_request_duration_seconds_count{service=~"$service.*",protocol="http"},\n        "service", "$1", "service", "([^@]+)@.*")\n)\n\n':
            f'topk(15,\n    label_replace(\n        traefik_service_request_duration_seconds_sum{{{scope}service=~"$service.*",protocol="http"}} / \n          traefik_service_request_duration_seconds_count{{{scope}service=~"$service.*",protocol="http"}},\n        "service", "$1", "service", "([^@]+)@.*")\n)\n\n',
        'topk(15,\n    label_replace(\n        sum by (service,code) \n          (rate(traefik_service_requests_total{service=~"$service.*",protocol="http"}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)':
            f'topk(15,\n    label_replace(\n        sum by (service,code) \n          (rate(traefik_service_requests_total{{{scope}service=~"$service.*",protocol="http"}}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)',
        'topk(15,\n    label_replace(\n        sum by (service,method,code) \n          (rate(traefik_service_requests_total{service=~"$service.*",code=~"2..",protocol="http"}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)':
            f'topk(15,\n    label_replace(\n        sum by (service,method,code) \n          (rate(traefik_service_requests_total{{{scope}service=~"$service.*",code=~"2..",protocol="http"}}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)',
        'topk(15,\n    label_replace(\n        sum by (service,method,code) \n          (rate(traefik_service_requests_total{service=~"$service.*",code=~"5..",protocol="http"}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)':
            f'topk(15,\n    label_replace(\n        sum by (service,method,code) \n          (rate(traefik_service_requests_total{{{scope}service=~"$service.*",code=~"5..",protocol="http"}}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)',
        'topk(15,\n    label_replace(\n        sum by (service,method,code) \n          (rate(traefik_service_requests_total{service=~"$service.*",code!~"2..|5..",protocol="http"}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)':
            f'topk(15,\n    label_replace(\n        sum by (service,method,code) \n          (rate(traefik_service_requests_total{{{scope}service=~"$service.*",code!~"2..|5..",protocol="http"}}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)',
        'topk(15,\n    label_replace(\n        sum by (service,method) \n          (rate(traefik_service_requests_bytes_total{service=~"$service.*",protocol="http"}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)':
            f'topk(15,\n    label_replace(\n        sum by (service,method) \n          (rate(traefik_service_requests_bytes_total{{{scope}service=~"$service.*",protocol="http"}}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)',
        'topk(15,\n    label_replace(\n        sum by (service,method) \n          (rate(traefik_service_responses_bytes_total{service=~"$service.*",protocol="http"}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)':
            f'topk(15,\n    label_replace(\n        sum by (service,method) \n          (rate(traefik_service_responses_bytes_total{{{scope}service=~"$service.*",protocol="http"}}[$interval])) > 0,\n        "service", "$1", "service", "([^@]+)@.*")\n)',
        'sum(traefik_open_connections{entrypoint=~"$entrypoint"}) by (entrypoint)\n':
            f'sum(traefik_open_connections{{{scope}entrypoint=~"$entrypoint"}}) by (entrypoint)\n',
    }

    _replace_exprs_exact(d["panels"], mapping)

    for p in d["panels"]:
        if p.get("title") == "Apdex score":
            p["title"] = "Avg Entrypoint Request Duration"
            # Upstream shipped no explicit unit (plain number formatting,
            # fine for a 0-1 Apdex score); now this is a duration in
            # seconds, so set it explicitly rather than leave raw numbers.
            p["fieldConfig"]["defaults"]["unit"] = "s"

    return _normalize_imported_dashboard_metadata(
        d, f"Traefik — {c}", uid_str, [c, "traefik", "ingress", "kubernetes"]
    )


def build_velero_from_template(uid_str):
    """kubenuc only. Adapted from grafana.com dashboard 16829 ("Kubernetes/
    Tanzu/Velero", official Velero team, 125K downloads, fetched
    2026-08-25, checked in verbatim at templates/velero-16829.json).
    namespace=velero, job=velero (confirmed live).

    Adaptations required to match this environment (confirmed live before
    editing, not guessed):
      - Dropped the entire "Restic" row (3 panels: Restic Success Rate/
        per hour/time) - this cluster's node-agent uses kopia, not
        restic, as its backup-repo engine; none of
        restic_pod_volume_backup_dequeue_count/_enqueue_count/
        restic_restic_operation_latency_seconds_gauge exist live. Kept
        the "File System Backup"/"Data Mover" rows - the podVolume_*
        metrics they use (pod_volume_backup_dequeue_count/
        _enqueue_count, pod_volume_operation_latency_seconds_gauge,
        data_upload_*/data_download_*) are all confirmed live with the
        exact backupName/node/operation/pod_volume_backup labels this
        template filters on.
      - The upstream $schedule variable (label_values(
        velero_backup_attempt_total, schedule)) returns empty here - our
        backups are ad-hoc (no Schedule CR), so velero_backup_attempt_
        total carries no schedule label at all. Stripped every
        schedule=~"$schedule" filter clause rather than leave a dead
        template variable in the UI (same reasoning as dropping Flux's
        $namespace variable). Same for $csi_backup_name -
        velero_csi_snapshot_attempt_total doesn't carry a backupName
        label on this cluster either (confirmed live; both CSI counters
        are 0 anyway, no CSI snapshots ever attempted).
      - velero_backup_duration_seconds_bucket (used by the "Backup time
        heatmap" panel) is NOT dropped by any existing rule - only the
        Velero/kopia pod-volume-backup buckets are (Wave 0) - kept as-is
        with scope added.
      - Every target gets an explicit cluster="kubenuc" scope added - the
        upstream dashboard has none (written for a single-cluster
        Prometheus).
    """
    c = "kubenuc"
    scope = f'cluster="{c}"'
    d = load_grafana_template("velero-16829")

    _fix_datasource_refs(d)
    d["templating"]["list"] = [
        v for v in d["templating"]["list"]
        if v.get("type") != "datasource"
        and v.get("name") not in ("schedule", "csi_backup_name", "restic_node", "restic_backup_name", "restic_operation", "restic_pvb_name")
    ]

    panels = _remove_row_and_contents(d["panels"], "Restic")

    velero_metrics = [
        "velero_backup_total", "velero_backup_last_status", "velero_restore_total",
        "velero_backup_success_total", "velero_backup_attempt_total",
        "velero_volume_snapshot_success_total", "velero_volume_snapshot_attempt_total",
        "velero_volume_snapshot_failure_total",
        "velero_backup_deletion_success_total", "velero_backup_deletion_attempt_total",
        "velero_backup_deletion_failure_total",
        "velero_backup_last_successful_timestamp",
        "velero_backup_failure_total", "velero_backup_partial_failure_total",
        "velero_backup_items_total", "velero_backup_items_errors",
        "velero_backup_validation_failure_total", "velero_backup_warning_total",
        "velero_backup_duration_seconds_bucket", "velero_backup_tarball_size_bytes",
        "velero_restore_success_total", "velero_restore_attempt_total",
        "velero_restore_failed_total", "velero_restore_validation_failed_total",
        "velero_restore_partial_failure_total",
        "velero_csi_snapshot_attempt_total", "velero_csi_snapshot_success_total",
        "velero_csi_snapshot_failure_total",
        "podVolume_pod_volume_backup_enqueue_count", "podVolume_pod_volume_backup_dequeue_count",
        "podVolume_pod_volume_operation_latency_seconds_gauge",
        "podVolume_data_upload_success_total", "podVolume_data_upload_failure_total",
        "podVolume_data_upload_cancel_total", "podVolume_data_download_success_total",
        "podVolume_data_download_failure_total", "podVolume_data_download_cancel_total",
    ]
    # Filter clauses that don't survive adaptation (no live schedule/backupName
    # label on this cluster's metrics, per the docstring above) - stripped
    # from a metric's existing {...} selector before re-scoping, rather than
    # left as dead filters referencing a removed template variable.
    dead_filters = re.compile(r'schedule=~"\$schedule"|schedule!=""|backupName=~"\$csi_backup_name"')

    def scope_metric(expr, metric):
        def repl_braced(m):
            inner = dead_filters.sub("", m.group(1))
            parts = [p.strip().rstrip(",") for p in inner.split(",") if p.strip(", ")]
            return metric + "{" + ", ".join([scope] + parts) + "}"
        expr, n = re.subn(re.escape(metric) + r"\{([^}]*)\}", repl_braced, expr)
        if n == 0:
            expr = re.sub(r"(?<![\w{])" + re.escape(metric) + r"(?![\w{])", metric + "{" + scope + "}", expr)
        return expr

    for p in panels:
        if p.get("type") == "row":
            continue
        for t in p.get("targets", []):
            expr = t.get("expr", "")
            for metric in velero_metrics:
                expr = scope_metric(expr, metric)
            t["expr"] = expr

    for p in panels:
        if p.get("title") == "CSI Snapshot Data Mover per hour":
            for t in p.get("targets", []):
                if t.get("legendFormat") == "Data download cancel":
                    t["expr"] = t["expr"].replace(
                        "podVolume_data_upload_cancel_total",
                        "podVolume_data_download_cancel_total",
                    )

    d["panels"] = panels
    return _normalize_imported_dashboard_metadata(
        d, f"Velero — {c}", uid_str, [c, "velero", "backup", "kubernetes"]
    )


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
                "flux":         lambda c, fn, ns, d, u: build_flux_from_template(c, u),
                "velero":       lambda c, fn, ns, d, u: build_velero_from_template(u),
                "traefik":      lambda c, fn, ns, d, u: build_traefik_from_template(u),
                "cloudflared":  lambda c, fn, ns, d, u: build_cloudflared_from_template(u),
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
