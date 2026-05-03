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

def p_stat(pid, title, expr, x, y, w=6, h=4, unit="short", legend="", thresholds=None):
    if thresholds is None:
        thresholds = [{"value": None, "color": "green"}]
    return {
        "id": pid, "title": title, "type": "stat", "datasource": PROM,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "targets": [{"expr": expr, "legendFormat": legend, "refId": "A"}],
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


def make_dashboard(title, uid_str, tags, panels):
    return {
        "title": title,
        "uid": uid_str,
        "tags": tags,
        "timezone": "browser",
        "refresh": "1m",
        "schemaVersion": 38,
        "time": {"from": "now-6h", "to": "now"},
        "timepicker": {},
        "templating": {"list": []},
        "annotations": {"list": []},
        "panels": panels,
        "version": 1,
        "editable": True,
    }


def stable_uid(cluster, name):
    prefix = {"kubenuc": "kn", "k8s-vms-daniele": "kv"}[cluster]
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
        f'sum(increase(falcosecurity_falcosidekick_falco_events_total{{cluster="{c}",priority=~"Critical|Emergency"}}[1h]))',
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
        [{"expr": f'sum by (priority) (rate(falcosecurity_falcosidekick_falco_events_total{{cluster="{c}"}}[5m]))', "legend": "{{priority}}"}],
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
    panels.append(p_logs(pid, c, n, y))

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


# ---------------------------------------------------------------------------
# App registry
# ---------------------------------------------------------------------------

# (file_name, namespace, display_name, dashboard_type)
APPS = {
    "kubenuc": [
        ("1password",                "1password",             "1Password",                    "standard"),
        ("bareos",                   "bareos",                "Bareos",                        "standard"),
        ("cert-manager",             "cert-manager",          "cert-manager",                  "cert-manager"),
        ("cloudflare",               "cloudflare",            "Cloudflare Tunnel",             "standard"),
        ("falco",                    "falco",                 "Falco",                         "falco"),
        ("film-tv-exporter",         "film-tv",               "Film/TV Exporter",              "no-container"),
        ("grafana-alloy",            "grafana-alloy",         "Grafana Alloy",                 "standard"),
        ("haproxy-ingress",          "haproxy-ingress",       "HAProxy Ingress",               "standard"),
        ("harbor",                   "harbor",                "Harbor Registry",               "harbor"),
        ("jellyfin",                 "jellyfin",              "Jellyfin",                      "standard"),
        ("jenkins",                  "jenkins",               "Jenkins",                       "standard"),
        ("jfrog-acr",                "jfrog",                 "JFrog Artifactory",             "standard"),
        ("net-mon",                  "net-mon",               "Net-Mon",                       "standard"),
        ("nextcloud",                "nextcloud-fastnetserv", "Nextcloud",                     "nextcloud"),
        ("nut",                      "nut",                   "NUT Exporter",                  "standard"),
        ("openebs",                  "openebs",               "OpenEBS",                       "standard"),
        ("portainer",                "portainer",             "Portainer",                     "standard"),
        ("postgresql",               "databases",             "PostgreSQL (Zalando)",          "postgresql"),
        ("s3",                       "nextcloud-fastnetserv", "S3 / SeaweedFS",               "s3"),
        ("sso",                      "sso",                   "SSO (Keycloak)",                "standard"),
        ("system-upgrade-controller","system-upgrade",        "System Upgrade Controller",     "standard"),
        ("unifi",                    "unifi",                 "UniFi",                         "standard"),
        ("zabbix",                   "zabbix",                "Zabbix Proxy",                  "standard"),
    ],
    "k8s-vms-daniele": [
        ("1password",                "1password",             "1Password",                    "standard"),
        ("awx",                      "awx",                   "AWX",                           "standard"),
        ("blackbox",                 "monitoring",            "Blackbox Exporter",             "standard"),
        ("cert-manager",             "cert-manager",          "cert-manager",                  "cert-manager"),
        ("cloudflare",               "cloudflare",            "Cloudflare Tunnel",             "standard"),
        ("falco",                    "falco",                 "Falco",                         "falco"),
        ("grafana-alloy",            "grafana-alloy",         "Grafana Alloy",                 "standard"),
        ("node-exporter",            "node-exporter",         "Node Exporter",                 "standard"),
        ("semaphore",                "semaphore",             "Semaphore",                     "standard"),
        ("system-upgrade-controller","system-upgrade",        "System Upgrade Controller",     "standard"),
        ("teleport-agent",           "teleport-agent",        "Teleport Agent",                "standard"),
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
