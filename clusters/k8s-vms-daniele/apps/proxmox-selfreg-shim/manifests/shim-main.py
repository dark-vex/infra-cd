"""
proxmox-selfreg-shim: hardened webhook front-door that replaces Semaphore's
webhook in the Proxmox self-registration flow (Semaphore -> AWX migration,
Phase A4). A Proxmox guest's cloud-init callback POSTs {token, ip} here;
this service verifies it and launches the AWX job template that runs
scripts/semaphore-netbox-register.py (via ansible/proxmox-selfreg).

Deliberately NOT modeled on clusters/kubenuc/apps/fluxcd/betterstack-bridge-
main.py beyond deployment shape (stdlib http.server, ConfigMap-mounted,
non-root/read-only-fs) — that bridge has zero auth and is an internal-only
Flux-notification adapter, not a precedent for a public endpoint holding an
AWX bearer credential.

Trust boundary: the unguessable path segment (SELFREG_WEBHOOK_PATH) is
defense-in-depth only, same as Semaphore's own webhook design (see
terraform/semaphore/main.tf's selfreg_v2 alias comment — this repo already
had to rotate a leaked webhook URL once). The real authentication is the
HMAC-SHA256 signature; never rely on the path alone.
"""

import hashlib
import hmac
import http.server
import ipaddress
import json
import os
import socketserver
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

HMAC_SECRET = os.environ["SELFREG_HMAC_SECRET"].encode()
WEBHOOK_PATH = "/" + os.environ["SELFREG_WEBHOOK_PATH"].strip("/")
# In-cluster Service, not the public hostname — the NetworkPolicy in this
# same directory restricts this pod's egress to exactly this Service, so
# calling the public hostname (which would resolve to Cloudflare's edge)
# would simply be dropped. AWX's internal Service serves plain HTTP; TLS is
# only terminated at the Ingress/Tunnel edge for external traffic.
AWX_INTERNAL_URL = os.environ["AWX_INTERNAL_URL"]
AWX_LAUNCH_TOKEN = os.environ["AWX_LAUNCH_TOKEN"]
AWX_JOB_TEMPLATE_NAME = os.environ.get("AWX_JOB_TEMPLATE_NAME", "proxmox-selfreg")

MAX_BODY_BYTES = 8 * 1024  # {token, ip} is tiny; generous margin, not unbounded
READ_TIMEOUT_SECONDS = 5
AWX_CALL_TIMEOUT_SECONDS = 15

# Replay protection: short-lived dedup cache keyed by the request's own HMAC
# signature (locked design decision — NOT a signed-timestamp+window scheme:
# the cloud-init callback fires at first boot, before NTP has converged, so
# a tight timestamp window risks rejecting legitimate requests). A separate,
# coarser rate limit sits in front of this and is not a substitute for it.
DEDUP_WINDOW_SECONDS = 300
RATE_LIMIT_MAX_REQUESTS = 20
RATE_LIMIT_WINDOW_SECONDS = 60

_state_lock = threading.Lock()
_seen_signatures: dict[str, float] = {}
_recent_request_times: list[float] = []


def log(msg: str) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    # Never pass raw bodies, signatures, tokens, IPs, or the AWX bearer
    # token/its response body into this function.
    print(f"{ts} {msg}", flush=True)


def _prune_seen_signatures(now: float) -> None:
    expired = [sig for sig, expiry in _seen_signatures.items() if expiry <= now]
    for sig in expired:
        del _seen_signatures[sig]


def rate_limited(now: float) -> bool:
    with _state_lock:
        cutoff = now - RATE_LIMIT_WINDOW_SECONDS
        while _recent_request_times and _recent_request_times[0] < cutoff:
            _recent_request_times.pop(0)
        if len(_recent_request_times) >= RATE_LIMIT_MAX_REQUESTS:
            return True
        _recent_request_times.append(now)
        return False


def is_replay(signature_hex: str, now: float) -> bool:
    with _state_lock:
        _prune_seen_signatures(now)
        if signature_hex in _seen_signatures:
            return True
        _seen_signatures[signature_hex] = now + DEDUP_WINDOW_SECONDS
        return False


def verify_signature(raw_body: bytes, signature_header: str | None) -> str | None:
    """Returns the verified signature hex on success, None on failure."""
    if not signature_header:
        return None
    expected = hmac.new(HMAC_SECRET, raw_body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature_header.strip().lower()):
        return None
    return expected


def launch_awx_job(token: str, ip: str) -> tuple[bool, str]:
    """Resolves the job template by name, then launches it. Returns
    (accepted, detail) — detail is safe to log, never echoes secrets."""
    headers = {
        "Authorization": f"Bearer {AWX_LAUNCH_TOKEN}",
        "Content-Type": "application/json",
    }

    lookup_url = (
        f"{AWX_INTERNAL_URL}/api/v2/job_templates/"
        f"?name={urllib.parse.quote(AWX_JOB_TEMPLATE_NAME)}"
    )
    req = urllib.request.Request(lookup_url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=AWX_CALL_TIMEOUT_SECONDS) as resp:
            data = json.loads(resp.read())
    except urllib.error.URLError as exc:
        return False, f"job template lookup failed: {type(exc).__name__}"

    results = data.get("results", [])
    if not results:
        return False, "job template not found"
    job_template_id = results[0]["id"]

    launch_url = f"{AWX_INTERNAL_URL}/api/v2/job_templates/{job_template_id}/launch/"
    body = json.dumps(
        {"extra_vars": {"selfreg_token": token, "selfreg_ip": ip}}
    ).encode()
    req = urllib.request.Request(launch_url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=AWX_CALL_TIMEOUT_SECONDS) as resp:
            if resp.status in (200, 201):
                return True, "launched"
            return False, f"unexpected launch status {resp.status}"
    except urllib.error.HTTPError as exc:
        return False, f"launch rejected: HTTP {exc.code}"
    except TimeoutError:
        # Ambiguous: AWX may have already accepted the launch even though we
        # never got the response. Do not treat this as safe to retry.
        return False, "launch call timed out (ambiguous outcome, not retried)"
    except urllib.error.URLError as exc:
        return False, f"launch call failed: {type(exc).__name__}"


class Handler(http.server.BaseHTTPRequestHandler):
    # socketserver.BaseRequestHandler applies this to the connection socket
    # before handle() runs, covering the initial request-line/header read
    # too — not just the body read below. Without this, a client that
    # trickles header bytes slowly (slowloris-style) could hold a
    # ThreadingHTTPServer thread open indefinitely, since the manual
    # settimeout() call in do_POST only takes effect after headers are
    # already fully parsed.
    timeout = READ_TIMEOUT_SECONDS

    def _respond(self, status: int) -> None:
        self.send_response(status)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        if self.path == "/healthz":
            self._respond(200)
            return
        self._respond(404)

    def do_POST(self):
        now = time.time()

        # Unguessable path check first, before anything else — identical
        # response to "not found" for both a wrong path and a real 404, so
        # this endpoint gives no oracle to a scanner.
        if self.path != WEBHOOK_PATH:
            self._respond(404)
            return

        if rate_limited(now):
            log("[selfreg] rejected: rate limit exceeded")
            self._respond(429)
            return

        content_type = self.headers.get("Content-Type", "")
        if not content_type.startswith("application/json"):
            log("[selfreg] rejected: bad content-type")
            self._respond(415)
            return

        if self.headers.get("Transfer-Encoding"):
            log("[selfreg] rejected: chunked transfer-encoding not supported")
            self._respond(411)
            return

        content_length_header = self.headers.get("Content-Length")
        if content_length_header is None:
            log("[selfreg] rejected: missing content-length")
            self._respond(411)
            return
        try:
            content_length = int(content_length_header)
        except ValueError:
            self._respond(400)
            return
        if content_length <= 0 or content_length > MAX_BODY_BYTES:
            log("[selfreg] rejected: oversized or empty body")
            self._respond(413)
            return

        try:
            raw_body = self.rfile.read(content_length)
        except (TimeoutError, OSError):
            log("[selfreg] rejected: body read timeout")
            self._respond(408)
            return
        if len(raw_body) != content_length:
            self._respond(400)
            return

        signature_hex = verify_signature(
            raw_body, self.headers.get("X-Selfreg-Signature")
        )
        if signature_hex is None:
            log("[selfreg] rejected: bad or missing signature")
            self._respond(401)
            return

        if is_replay(signature_hex, now):
            log("[selfreg] rejected: replayed request")
            self._respond(409)
            return

        try:
            payload = json.loads(raw_body)
        except json.JSONDecodeError:
            log("[selfreg] rejected: invalid json")
            self._respond(400)
            return

        if not isinstance(payload, dict) or set(payload.keys()) != {"token", "ip"}:
            log("[selfreg] rejected: unexpected payload shape")
            self._respond(400)
            return

        token = payload["token"]
        ip = payload["ip"]
        if not isinstance(token, str) or not (1 <= len(token) <= 512):
            log("[selfreg] rejected: invalid token field")
            self._respond(400)
            return
        if not isinstance(ip, str):
            log("[selfreg] rejected: invalid ip field")
            self._respond(400)
            return
        try:
            ipaddress.ip_address(ip)
        except ValueError:
            log("[selfreg] rejected: ip does not parse")
            self._respond(400)
            return

        accepted, detail = launch_awx_job(token, ip)
        if accepted:
            log(f"[selfreg] accepted: {detail}")
            self._respond(202)
        else:
            log(f"[selfreg] awx launch failed: {detail}")
            self._respond(502)

    def log_message(self, fmt, *args):
        # Silence BaseHTTPRequestHandler's default per-request access log —
        # it would print the raw request line (method + path), and the
        # path here is the secret. All real logging goes through log()
        # above, which is careful about what it prints.
        pass


class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    log(
        f"proxmox-selfreg-shim listening on :{port} "
        f"awx_job_template={AWX_JOB_TEMPLATE_NAME}"
    )
    server.serve_forever()
