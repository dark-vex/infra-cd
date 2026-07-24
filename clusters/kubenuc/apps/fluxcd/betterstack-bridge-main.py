import http.server
import urllib.request
import urllib.error
import json
import os
import threading
from datetime import datetime, timezone

BETTERSTACK_TOKEN = os.environ["BETTERSTACK_TOKEN"]
NEXTCLOUD_MONITOR_ID = os.environ["NEXTCLOUD_MONITOR_ID"]
BETTERSTACK_API = "https://uptime.betterstack.com/api/v2"
DEBUG_EVENTS = os.environ.get("DEBUG_EVENTS", "0") == "1"

paused = False
lock = threading.Lock()

# Terminal reasons emitted by helm-controller that mean "upgrade finished".
CLOSE_REASONS = {
    "UpgradeSucceeded",
    "UpgradeFailed",
    "InstallSucceeded",
    "InstallFailed",
    "RollbackSucceeded",
    "RollbackFailed",
    "TestSucceeded",
    "TestFailed",
    "ReconciliationSucceeded",
    "ReconciliationFailed",
}

# Reasons that indicate an upgrade is about to run. helm-controller does NOT
# emit a "Progressing" event — that's only a condition. The earliest real
# event we can hook is DriftDetected on the HelmRelease, or a chart pull
# from the source-controller.
HR_OPEN_REASONS = {"DriftDetected"}
CHART_OPEN_REASONS = {"ChartPullSucceeded"}
# DependencyNotReady fires when kustomize-controller's healthCheck fails
# because the HelmRelease is actively upgrading (not yet Ready). It does NOT
# fire during no-op 15m reconcile cycles where the HR is already Ready.
# Progressing fires on every reconcile cycle and is therefore too noisy.
# ReconciliationSucceeded is suppressed by the notification controller for
# routine cycles, so it cannot be used as a fast-unpause close trigger.
KUSTOMIZATION_OPEN_REASONS = {"DependencyNotReady"}

# Kept as a safety net in case ReconciliationSucceeded starts arriving.
KUSTOMIZATION_CLOSE_REASONS = {"ReconciliationSucceeded", "ReconciliationFailed"}

# Safety auto-unpause: if a terminal HelmRelease event never arrives
# (e.g. bridge restarts mid-upgrade), unpause after this many seconds.
AUTO_UNPAUSE_SECS = 300  # 5 minutes

NEXTCLOUD_HR_NAME = "nextcloud"
NEXTCLOUD_HR_NAMESPACE = "nextcloud-fastnetserv"
# helm-controller creates the HelmChart in the HelmRepository's namespace
# with name "<hr-namespace>-<hr-name>".
NEXTCLOUD_CHART_NAME = f"{NEXTCLOUD_HR_NAMESPACE}-{NEXTCLOUD_HR_NAME}"
NEXTCLOUD_KUSTOMIZATION_NAME = "nextcloud"

auto_unpause_timer = None


def _auto_unpause():
    global paused, auto_unpause_timer
    with lock:
        auto_unpause_timer = None
        if paused:
            if set_monitor_paused(False):
                paused = False
                log(f"[betterstack] monitor {NEXTCLOUD_MONITOR_ID} auto-unpaused after {AUTO_UNPAUSE_SECS}s timeout")
            else:
                log(f"[betterstack] failed to auto-unpause monitor {NEXTCLOUD_MONITOR_ID}")


def _schedule_auto_unpause():
    """Cancel any running timer and start a fresh one. Call inside lock."""
    global auto_unpause_timer
    if auto_unpause_timer:
        auto_unpause_timer.cancel()
    t = threading.Timer(AUTO_UNPAUSE_SECS, _auto_unpause)
    t.daemon = True
    t.start()
    auto_unpause_timer = t


def _cancel_auto_unpause():
    """Cancel any pending auto-unpause timer. Call inside lock."""
    global auto_unpause_timer
    if auto_unpause_timer:
        auto_unpause_timer.cancel()
        auto_unpause_timer = None


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(f"{ts} {msg}", flush=True)


def betterstack_request(method, path, body=None):
    url = f"{BETTERSTACK_API}{path}"
    data = json.dumps(body).encode() if body else None
    headers = {"Authorization": f"Bearer {BETTERSTACK_TOKEN}"}
    if data:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        log(f"[betterstack] {method} {path} -> HTTP {e.code}: {e.read().decode()}")
        return e.code, None


def set_monitor_paused(pause):
    status, _ = betterstack_request(
        "PATCH",
        f"/monitors/{NEXTCLOUD_MONITOR_ID}",
        {"paused": pause},
    )
    return status == 200


def is_nextcloud_event(obj_kind, obj_name, obj_namespace):
    if obj_kind == "HelmRelease" and obj_name == NEXTCLOUD_HR_NAME:
        return True
    if obj_kind == "HelmChart" and obj_name == NEXTCLOUD_CHART_NAME:
        return True
    if obj_kind == "Kustomization" and obj_name == NEXTCLOUD_KUSTOMIZATION_NAME:
        return True
    return False


def should_pause(obj_kind, reason):
    if obj_kind == "HelmRelease" and reason in HR_OPEN_REASONS:
        return True
    if obj_kind == "HelmChart" and reason in CHART_OPEN_REASONS:
        return True
    if obj_kind == "Kustomization" and reason in KUSTOMIZATION_OPEN_REASONS:
        return True
    return False


def should_close(obj_kind, reason):
    if obj_kind == "HelmRelease" and reason in CLOSE_REASONS:
        return True
    if obj_kind == "Kustomization" and reason in KUSTOMIZATION_CLOSE_REASONS:
        return True
    return False


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def do_POST(self):
        global paused
        length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(length) if length else b""
        try:
            payload = json.loads(raw_body) if raw_body else {}
        except json.JSONDecodeError:
            log(f"[event:bad-json] body={raw_body!r}")
            payload = {}

        reason = payload.get("reason", "")
        severity = payload.get("severity", "")
        obj = payload.get("involvedObject", {})
        obj_kind = obj.get("kind", "")
        obj_name = obj.get("name", "")
        obj_namespace = obj.get("namespace", "")

        if DEBUG_EVENTS:
            log(f"[event:raw] {raw_body.decode(errors='replace')}")

        tag = "event" if is_nextcloud_event(obj_kind, obj_name, obj_namespace) else "event:skip"
        log(
            f"[{tag}] reason={reason} severity={severity} "
            f"object={obj_kind}/{obj_namespace}/{obj_name}"
        )

        if is_nextcloud_event(obj_kind, obj_name, obj_namespace):
            with lock:
                if should_pause(obj_kind, reason) and not paused:
                    if set_monitor_paused(True):
                        paused = True
                        _schedule_auto_unpause()
                        log(f"[betterstack] monitor {NEXTCLOUD_MONITOR_ID} paused (trigger={obj_kind}/{reason})")
                    else:
                        log(f"[betterstack] failed to pause monitor {NEXTCLOUD_MONITOR_ID}")

                elif should_close(obj_kind, reason) and paused:
                    if set_monitor_paused(False):
                        paused = False
                        _cancel_auto_unpause()
                        log(f"[betterstack] monitor {NEXTCLOUD_MONITOR_ID} unpaused (trigger={obj_kind}/{reason})")
                    else:
                        log(f"[betterstack] failed to unpause monitor {NEXTCLOUD_MONITOR_ID}")

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, fmt, *args):
        log(fmt % args)


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", 8080), Handler)
    log(
        f"betterstack-bridge listening on :8080 monitor_id={NEXTCLOUD_MONITOR_ID} "
        f"debug_events={DEBUG_EVENTS}"
    )
    server.serve_forever()
