#!/usr/bin/env python3
"""Minimal in-memory stand-in for the Graylog REST API paths graylog-alerting uses.

Mimics the behaviours the role has to survive: streams created paused, secrets
(webhook) not returned on GET, server-added fields on every object, token auth
and the X-Requested-By header on writes. Logs method+path only (never bodies or
credentials) to /var/log/stub-graylog-requests.log.
"""
import base64
import json
import os
import re
import sys
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TOKEN = "molecule-stub-token"
STATE = {"streams": {}, "notifications": {}, "definitions": {}}
INDEX_SETS = [
    {"id": "idx-other", "title": "other", "default": False},
    {"id": "idx-default", "title": "Default index set", "default": True},
]
# Properties of slack-notification-v1 on Graylog 7.1 (from its own 400 reply).
SLACK_KEYS = {
    "type", "webhook_url", "channel", "user_name", "color", "backlog_size", "notify_channel", "notify_here",
    "link_names", "icon_url", "icon_emoji", "include_title", "include_event_procedure", "custom_message", "time_zone",
}
LOG = os.environ.get("STUB_LOG", "/var/log/stub-graylog-requests.log")


def new_id():
    return uuid.uuid4().hex[:24]


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def _send(self, code, body=None):
        data = b"" if body is None else json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _handle(self, method):
        path, _, query = self.path.partition("?")
        schedule = "schedule=false" not in query
        with open(LOG, "a") as fh:
            fh.write(f"{method} {path}\n")
        auth = self.headers.get("Authorization", "")
        expected = base64.b64encode(f"{TOKEN}:token".encode()).decode()
        if auth != f"Basic {expected}":
            return self._send(401, {"message": "unauthorized"})
        length = int(self.headers.get("Content-Length") or 0)
        # Real Graylog answers 400 to a bodiless request that claims a JSON body
        # (found on the first live run: uri body_format json set on GETs).
        if method in ("GET", "DELETE") and "json" in self.headers.get("Content-Type", ""):
            return self._send(400, {"message": "bodiless request with a JSON content type"})
        body = json.loads(self.rfile.read(length)) if length else {}
        if method != "GET" and not self.headers.get("X-Requested-By"):
            return self._send(400, {"message": "missing X-Requested-By"})

        if path == "/api/system/indices/index_sets" and method == "GET":
            return self._send(200, {"index_sets": INDEX_SETS})
        if path == "/api/streams" and method == "GET":
            return self._send(200, {"streams": list(STATE["streams"].values())})
        # Graylog 7 create endpoints take {"entity": {...}}; reject a bare body
        # the way the real server does (found on the first real run).
        if method == "POST" and path in ("/api/streams", "/api/events/notifications", "/api/events/definitions"):
            if body.get("entity") is None:
                return self._send(400, {"type": "RequestError", "message": 'Error at "" [1, 1]: entity cannot be null'})
            body = body["entity"]
            if path == "/api/events/notifications":
                unknown = set(body["config"]) - SLACK_KEYS
                if unknown:
                    return self._send(400, {"type": "RequestError", "message": f"Unable to map property {sorted(unknown)[0]}"})
        if path == "/api/streams" and method == "POST":
            sid = new_id()
            STATE["streams"][sid] = {**body, "id": sid, "disabled": True}
            return self._send(201, {"stream_id": sid})
        m = re.fullmatch(r"/api/streams/(\w+)/resume", path)
        if m and method == "POST":
            STATE["streams"][m.group(1)]["disabled"] = False
            return self._send(204)

        if path == "/api/events/notifications" and method == "GET":
            return self._send(200, {"notifications": list(STATE["notifications"].values())})
        if path == "/api/events/notifications" and method == "POST":
            nid = new_id()
            STATE["notifications"][nid] = self._mask(body, nid)
            STATE["notifications"][nid]["_webhook_len"] = len(body["config"]["webhook_url"])
            return self._send(200, {"id": nid})
        m = re.fullmatch(r"/api/events/notifications/(\w+)", path)
        if m and method == "PUT":
            STATE["notifications"][m.group(1)] = self._mask(body, m.group(1))
            return self._send(200, {"id": m.group(1)})

        if path == "/api/events/definitions" and method == "GET":
            return self._send(200, {"event_definitions": list(STATE["definitions"].values())})
        if path == "/api/events/definitions/validate" and method == "POST":
            if body["config"]["streams"][0] not in STATE["streams"]:
                return self._send(400, {"message": "unknown stream"})
            if not body["config"]["query"]:
                return self._send(400, {"message": "empty query"})
            return self._send(200, {"errors": {}})
        if path == "/api/events/definitions" and method == "POST":
            did = new_id()
            STATE["definitions"][did] = self._decorate(body, did, schedule)
            return self._send(200, {"id": did})
        m = re.fullmatch(r"/api/events/definitions/(\w+)", path)
        if m and method == "PUT":
            STATE["definitions"][m.group(1)] = self._decorate(body, m.group(1), schedule)
            return self._send(200, {"id": m.group(1)})
        if m and method == "DELETE":
            STATE["definitions"].pop(m.group(1), None)
            return self._send(204)
        if path == "/state" and method == "GET":
            return self._send(200, STATE)
        return self._send(404, {"message": f"no route {method} {path}"})

    @staticmethod
    def _mask(body, nid):
        out = json.loads(json.dumps(body))
        out["id"] = nid
        out["config"]["webhook_url"] = {"is_set": True}
        return out

    @staticmethod
    def _decorate(body, did, schedule=True):
        out = json.loads(json.dumps(body))
        out.update({"id": did, "_scope": "DEFAULT", "state": "ENABLED" if schedule else "DISABLED", "updated_at": "now"})
        out["config"].update({"use_cron_scheduling": False, "cron_expression": None})
        return out

    def do_GET(self):
        self._handle("GET")

    def do_POST(self):
        self._handle("POST")

    def do_PUT(self):
        self._handle("PUT")

    def do_DELETE(self):
        self._handle("DELETE")


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9000
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
