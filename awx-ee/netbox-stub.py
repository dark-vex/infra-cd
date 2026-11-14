"""Stand-in NetBox for the EE smoke test: answers every request with an empty
page and records the Authorization header of each request to a file, so the test
can assert how the nb_inventory `token: {type, value}` templating sent the token.
Usage: netbox-stub.py <port> <header-log>"""
import http.server
import json
import sys

PORT, LOG = int(sys.argv[1]), sys.argv[2]


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        with open(LOG, "a", encoding="utf-8") as fh:
            fh.write((self.headers.get("Authorization") or "-") + "\n")
        if self.path.startswith("/api/status"):
            body = {"netbox-version": "4.5.0"}
        elif self.path.startswith(("/api/docs", "/api/schema")):
            # the plugin reads the filter parameters of the device/VM list endpoints
            get = {"get": {"parameters": []}}
            body = {"paths": {"/api/dcim/devices/": get, "/api/virtualization/virtual-machines/": get}}
        else:
            body = {"count": 0, "next": None, "previous": None, "results": []}
        data = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
