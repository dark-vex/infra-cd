#!/usr/bin/env python3
"""Stage 2 step 1: fetch the stage-1 artifact and re-verify every gate.

Runs from the default branch with GITHUB_TOKEN only (no LLM key in this step).
The PR number/author/labels come from the API, never from the artifact.
"""
import argparse
import io
import json
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ghapi  # noqa: E402

MAX_ZIP = 8 * 1024 * 1024
MAX_JSON = 4 * 1024 * 1024
RENOVATE_LOGINS = {"renovate-gihub-app[bot]", "renovate[bot]"}


def fail(msg):
    print("fetch_context: " + msg, file=sys.stderr)
    sys.exit(1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--run-id", required=True)
    ap.add_argument("--head-sha", required=True)
    ap.add_argument("--out-dir", required=True)
    a = ap.parse_args()

    # PR via the head commit; must be open, same-repo, matching SHA.
    prs, _ = ghapi.request("GET", "/repos/%s/commits/%s/pulls" % (a.repo, a.head_sha))
    cands = [p for p in prs if p["state"] == "open" and p["head"]["sha"] == a.head_sha
             and p["head"]["repo"] and p["head"]["repo"]["full_name"] == a.repo
             and p["base"]["ref"] == "main"]
    if len(cands) != 1:
        fail("expected exactly one open same-repo PR for %s, got %d" % (a.head_sha, len(cands)))
    pr = cands[0]
    labels = {l["name"] for l in pr["labels"]}
    if pr["user"]["login"] not in RENOVATE_LOGINS and "renovate" not in labels:
        fail("PR is not a Renovate PR")

    arts, _ = ghapi.request("GET", "/repos/%s/actions/runs/%s/artifacts" % (a.repo, a.run_id))
    match = [x for x in arts["artifacts"] if x["name"] == "llm-context" and not x["expired"]]
    if len(match) != 1 or match[0]["size_in_bytes"] > MAX_ZIP:
        fail("llm-context artifact missing or oversized")
    blob, _ = ghapi.request("GET", match[0]["archive_download_url"], raw=True, timeout=120)
    zf = zipfile.ZipFile(io.BytesIO(blob))
    if [i.filename for i in zf.infolist()] != ["context.json"]:
        fail("unexpected artifact contents")
    info = zf.infolist()[0]
    if info.file_size > MAX_JSON:
        fail("context.json too large")
    ctx = json.loads(zf.read("context.json"))
    if ctx.get("schema") != 1 or ctx.get("head_sha") != a.head_sha:
        fail("context schema/head_sha mismatch")

    os.makedirs(a.out_dir, exist_ok=True)
    with open(os.path.join(a.out_dir, "context.json"), "w") as f:
        json.dump(ctx, f)
    with open(os.path.join(a.out_dir, "pr.json"), "w") as f:
        json.dump({"number": pr["number"], "head_sha": a.head_sha, "title_len": len(pr["title"])}, f)
    print("pr=%d" % pr["number"])


if __name__ == "__main__":
    main()
