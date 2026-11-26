"""Stand-in for the Zabbix JSON-RPC API in the psk-guard Molecule tests.

Answers every POST with {"jsonrpc": "2.0", "result": <contents of the JSON file>, "id": 1},
so a test picks the host record by rewriting the file. Usage: guard_stub.py PORT FILE; GET /quit stops it.
"""
import http.server
import json
import sys
import threading


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("Content-Length", 0)))
        with open(sys.argv[2], encoding="utf-8") as fh:
            result = json.load(fh)
        body = json.dumps({"jsonrpc": "2.0", "result": result, "id": 1}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        # GET /quit stops the stand-in (the test play has no pkill to do it).
        self.send_response(200)
        self.end_headers()
        threading.Thread(target=self.server.shutdown).start()

    def log_message(self, *args):
        pass


http.server.HTTPServer.allow_reuse_address = True
http.server.HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
