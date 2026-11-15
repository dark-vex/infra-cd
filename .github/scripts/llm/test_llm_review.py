#!/usr/bin/env python3
"""Offline tests for the LLM PR review scripts (stdlib unittest, mock servers).

Run: python3 -I .github/scripts/llm/test_llm_review.py   (from the repo root)
"""
import http.server
import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import llmlib  # noqa: E402
import review  # noqa: E402

GOOD = {"risk": "medium", "breaking": [{"evidence": "key `foo` renamed @everyone https://evil.example/x", "file": "a.yml", "key": "foo"}],
        "values_impact": "<script>x</script> still applies", "recommendation": "merge_with_followup"}


class Mock(http.server.BaseHTTPRequestHandler):
    llm_calls = 0
    comments = []
    llm_script = []  # list of (status, headers, body)

    def log_message(self, *a):
        pass

    def _send(self, code, obj, headers=None):
        raw = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(n) or b"{}")
        if self.path.endswith("/chat/completions"):
            Mock.llm_calls += 1
            code, hdr, payload = Mock.llm_script.pop(0) if Mock.llm_script else (200, {}, GOOD)
            if code != 200:
                return self._send(code, {"error": "x"}, hdr)
            return self._send(200, {"choices": [{"message": {"content": json.dumps(payload)}}], "usage": {"prompt_tokens": 10, "completion_tokens": 5}})
        if "/comments" in self.path:
            Mock.comments.append({"id": len(Mock.comments) + 1, "body": body["body"], "user": {"login": "github-actions[bot]"}})
            return self._send(201, {})
        self._send(404, {})

    def do_GET(self):
        if "/comments" in self.path:
            return self._send(200, Mock.comments)
        self._send(404, {})

    def do_PATCH(self):
        n = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(n))
        cid = int(self.path.rsplit("/", 1)[1])
        Mock.comments[cid - 1]["body"] = body["body"]
        self._send(200, {})


class RedirectAuth(unittest.TestCase):
    def test_redirect_drops_auth_header(self):
        seen = {}

        class H(http.server.BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def do_GET(self):
                if self.path == "/start":
                    self.send_response(302)
                    self.send_header("Location", "http://127.0.0.1:%d/blob" % self.server.server_address[1])
                    self.end_headers()
                else:
                    seen["auth"] = self.headers.get("Authorization")
                    self.send_response(200)
                    self.send_header("Content-Length", "2")
                    self.end_headers()
                    self.wfile.write(b"ok")

        srv = http.server.HTTPServer(("127.0.0.1", 0), H)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        import ghapi
        data, _ = ghapi.request("GET", "http://127.0.0.1:%d/start" % srv.server_address[1], raw=True)
        srv.shutdown()
        self.assertEqual(data, b"ok")
        self.assertIsNone(seen["auth"])


class Redaction(unittest.TestCase):
    def test_sensitive_paths(self):
        for p in ("a/b.sops.yaml", "x/.env", "k/tls.key", "c/secrets/x.yml", "a/secret.yaml"):
            self.assertTrue(llmlib.is_sensitive_path(p), p)
        self.assertFalse(llmlib.is_sensitive_path("clusters/k/apps/x/release.yml"))

    def test_redact(self):
        fake_pat = "ghp_" + "A1b2C3d4" * 4
        age = "AGE-SECRET" + "-KEY-" + "1QQQ9ZZ" * 8
        out = llmlib.redact("host app.corp-internal.eu ip 10.1.2.3 tok %s k %s password: hunter2hunter2 see github.com/x" % (fake_pat, age))
        for leak in ("corp-internal", "10.1.2.3", fake_pat, age, "hunter2"):
            self.assertNotIn(leak, out)
        self.assertIn("github.com/x", out)

    def test_keeps_versions_and_digests(self):
        sha = "a" * 40
        self.assertIn(sha, llmlib.redact("rev " + sha))
        self.assertIn("1.34.13", llmlib.redact("v1.34.13+k3s1 and 1.34.13"))

    def test_keeps_long_paths(self):
        p = "a/clusters/oc-ampere/apps/system-upgrade-controller/manifests/plan.yml"
        self.assertIn(p, llmlib.redact("diff --git " + p))

    def test_sops_content_dropped(self):
        self.assertIsNone(llmlib.filter_text("a.yml", "k: ENC[AES256_GCM,data:abc]"))

    def test_truncate_bytes(self):
        s = "é" * 40000
        self.assertLessEqual(len(llmlib.truncate_bytes(s, 55000).encode()), 55000)


class Render(unittest.TestCase):
    def test_validate_rejects(self):
        for bad in ({}, {"risk": "x"}, dict(GOOD, recommendation="approve")):
            with self.assertRaises(ValueError):
                review.validate(bad)

    def test_sanitised_output(self):
        ctx = {"head_sha": "f" * 40, "files": ["a.yml"]}
        md = review.render(review.validate(dict(GOOD)), ctx, "m", 1.0, {})
        self.assertNotIn("@everyone", md)
        self.assertNotIn("<script>", md)
        self.assertNotIn("https://", md)
        self.assertTrue(md.startswith("<!-- llm-review sha=" + "f" * 40))

    def test_unlisted_file_flagged(self):
        ctx = {"head_sha": "f" * 40, "files": []}
        self.assertIn("not in diff", review.render(review.validate(dict(GOOD)), ctx, "m", 1.0, {}))


class EndToEnd(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Mock)
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()
        cls.url = "http://127.0.0.1:%d" % cls.srv.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()

    def run_review(self, force=False):
        d = tempfile.mkdtemp()
        with open(os.path.join(d, "context.json"), "w") as f:
            json.dump({"schema": 1, "head_sha": "c" * 40, "files": ["a.yml"], "est_tokens": 1, "pr_title": "t",
                   "sections": {"overrides": [], "rendered_diff": [], "release_notes": "n",
                                "diff": [{"file": "a.sops.yaml", "content": "ENC[AES256_GCM,x]"}, {"file": "a.yml", "content": "+x: 1"}]}}, f)
        with open(os.path.join(d, "pr.json"), "w") as f:
            json.dump({"number": 7}, f)
        env = dict(os.environ, LLM_BASE_URL=self.url, LLM_MODEL="m", LLM_API_KEY="k", GITHUB_API_URL=self.url, GITHUB_TOKEN="t")
        args = [sys.executable, "-I", os.path.join(HERE, "review.py"), "--repo", "o/r", "--in-dir", d]
        if force:
            args.append("--force")
        return subprocess.run(args, env=env, capture_output=True, text=True)

    def test_flow(self):
        Mock.comments.clear()
        Mock.llm_calls = 0
        Mock.llm_script = [(429, {"Retry-After": "0"}, None)]
        r = self.run_review()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(Mock.llm_calls, 2)  # one 429 then success
        self.assertEqual(len(Mock.comments), 1)
        r = self.run_review()  # same SHA: skipped, no new LLM call
        self.assertIn("already reviewed", r.stdout)
        self.assertEqual(Mock.llm_calls, 2)
        self.run_review(force=True)  # upsert, not duplicate
        self.assertEqual(len(Mock.comments), 1)

    def test_garbage_output_fails_soft(self):
        Mock.comments.clear()
        Mock.llm_script = [(200, {}, {"risk": "nope"})]
        r = self.run_review()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("LLM unavailable", Mock.comments[0]["body"])


if __name__ == "__main__":
    unittest.main()
