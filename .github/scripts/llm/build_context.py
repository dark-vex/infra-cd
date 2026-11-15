#!/usr/bin/env python3
"""Stage 1: build a bounded, filtered review-context bundle (stdlib only).

Runs on an untrusted PR checkout with NO secrets. Output is a single JSON file
that stage 2 treats strictly as data.

Inputs are plain files/args so this can be tested locally without flate:
  --render-base / --render-head   rendered multi-doc YAML (flate build output)
"""
import argparse
import difflib
import json
import os
import re
import subprocess
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from llmlib import est_tokens, filter_text, is_sensitive_path, redact  # noqa: E402

MAX_TOKENS = 100_000
PER_FILE_DIFF_LINES = 400
PER_RESOURCE_DIFF_LINES = 200
RELEASE_FETCH_THRESHOLD = 60_000
BREAKING_RE = re.compile(r"(?i)breaking|upgrad|migrat|deprecat|removed|renam|incompatib|action required")


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def changed_files(base, head):
    out = git("diff", "--name-only", "--diff-filter=ACMRD", "%s...%s" % (base, head))
    return [p for p in out.splitlines() if p]


def file_diff(base, head, path):
    d = git("diff", "-U3", "%s...%s" % (base, head), "--", path)
    lines = d.splitlines()
    if len(lines) > PER_FILE_DIFF_LINES:
        lines = lines[:PER_FILE_DIFF_LINES] + ["... (diff truncated)"]
    return "\n".join(lines)


def read_at(rev, path):
    try:
        return git("show", "%s:%s" % (rev, path))
    except subprocess.CalledProcessError:
        return ""


# ---- overrides ---------------------------------------------------------------

def _block(text, key, indent):
    """Return the indented block under `<indent>key:` (text-level, no YAML dep)."""
    lines = text.splitlines()
    pad = " " * indent
    for i, line in enumerate(lines):
        if re.match(r"^%s%s:\s*(#.*)?$" % (pad, re.escape(key)), line):
            out = [line]
            for nxt in lines[i + 1:]:
                if nxt.strip() == "" or len(nxt) - len(nxt.lstrip()) > indent:
                    out.append(nxt)
                else:
                    break
            return "\n".join(out)
    return ""


def helm_overrides(path, text):
    if "kind: HelmRelease" not in text:
        return None
    parts = [_block(text, "values", 2), _block(text, "valuesFrom", 2)]
    parts = [p for p in parts if p]
    return "\n".join(parts) if parts else None


def terraform_provider_usage(diff_text):
    """Resources in the repo that use a provider whose version was bumped."""
    providers = set(re.findall(r'provider "registry\.terraform\.io/[^/]+/([A-Za-z0-9_-]+)"', diff_text))
    if not providers:
        return None
    hits = []
    for prov in sorted(providers):
        short = prov.replace("-", "_")
        out = subprocess.run(
            ["git", "grep", "-nE", r'^(resource|data) "%s_[A-Za-z0-9_]+"' % re.escape(short), "--", "*.tf"],
            capture_output=True, text=True,
        ).stdout
        hits.extend(out.splitlines()[:60])
    return "\n".join(hits) if hits else None


# ---- rendered diff -------------------------------------------------------------

def split_docs(text):
    docs = {}
    for doc in re.split(r"(?m)^---\s*$", text):
        if not doc.strip():
            continue
        kind = re.search(r"(?m)^kind:\s*(\S+)", doc)
        name = re.search(r"(?m)^  name:\s*(\S+)", doc)
        ns = re.search(r"(?m)^  namespace:\s*(\S+)", doc)
        if not kind:
            continue
        if kind.group(1) == "Secret":
            continue
        key = "%s/%s/%s" % (kind.group(1), ns.group(1) if ns else "-", name.group(1) if name else "?")
        docs[key] = doc.strip("\n")
    return docs


def rendered_diff(base_path, head_path):
    if not (os.path.isfile(base_path) and os.path.isfile(head_path)):
        return None
    base = split_docs(open(base_path, errors="replace").read())
    head = split_docs(open(head_path, errors="replace").read())
    out = []
    for key in sorted(set(base) | set(head)):
        b, h = base.get(key), head.get(key)
        if b == h:
            continue
        if b is None:
            out.append("+++ added %s" % key)
            continue
        if h is None:
            out.append("--- removed %s" % key)
            continue
        d = list(difflib.unified_diff(b.splitlines(), h.splitlines(), "base/" + key, "head/" + key, n=2, lineterm=""))
        if len(d) > PER_RESOURCE_DIFF_LINES:
            d = d[:PER_RESOURCE_DIFF_LINES] + ["... (resource diff truncated)"]
        out.append("\n".join(d))
    return "\n".join(out) if out else ""


# ---- release notes -------------------------------------------------------------

def trim_notes(body, budget_chars):
    if len(body) <= budget_chars:
        return body
    paras = re.split(r"\n{2,}", body)
    keep = [p for p in paras if BREAKING_RE.search(p)]
    head = body[: budget_chars // 3]
    text = head + "\n\n[...]\n\n" + "\n\n".join(keep)
    return text[:budget_chars]


def fetch_release_notes(body):
    """Only for truncated PR bodies; only github.com repos linked from the body."""
    repos = []
    for owner, repo in re.findall(r"https://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/releases", body):
        if (owner, repo) not in repos:
            repos.append((owner, repo))
    token = os.environ.get("GITHUB_TOKEN", "")
    notes = []
    for owner, repo in repos[:3]:
        req = urllib.request.Request(
            "https://api.github.com/repos/%s/%s/releases?per_page=5" % (owner, repo),
            headers={"Accept": "application/vnd.github+json", **({"Authorization": "Bearer " + token} if token else {})},
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                for rel in json.load(r):
                    notes.append("### %s/%s %s\n%s" % (owner, repo, rel.get("tag_name", ""), (rel.get("body") or "")[:6000]))
        except Exception as exc:  # advisory only
            notes.append("(release fetch failed for %s/%s: %s)" % (owner, repo, type(exc).__name__))
    return "\n\n".join(notes)


# ---- main --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--head", required=True)
    ap.add_argument("--pr-title", default="")
    ap.add_argument("--pr-body-file")
    ap.add_argument("--render-dir", help="dir with <cluster>.base.yaml / <cluster>.head.yaml")
    ap.add_argument("--out", required=True)
    ap.add_argument("--fetch-releases", action="store_true")
    a = ap.parse_args()

    files = changed_files(a.base, a.head)
    kept, dropped = [], []
    sections = {"overrides": [], "rendered_diff": [], "diff": [], "release_notes": ""}
    budget = MAX_TOKENS * 3  # chars, ~ MAX_TOKENS tokens

    def room():
        used = sum(len(json.dumps(v)) for v in sections.values())
        return budget - used

    # 1. overrides
    for p in files:
        if is_sensitive_path(p):
            dropped.append(p)
            continue
        if p.endswith((".yml", ".yaml")):
            txt = read_at(a.head, p)
            ov = helm_overrides(p, txt) if txt else None
            if ov:
                red = filter_text(p, ov)
                if red:
                    sections["overrides"].append({"file": p, "kind": "helm-values", "content": red})
    all_diff = ""

    # 2. rendered diff
    if a.render_dir and os.path.isdir(a.render_dir):
        for fn in sorted(os.listdir(a.render_dir)):
            if fn.endswith(".base.yaml"):
                cluster = fn[: -len(".base.yaml")]
                rd = rendered_diff(os.path.join(a.render_dir, fn), os.path.join(a.render_dir, cluster + ".head.yaml"))
                if rd is None:
                    sections["rendered_diff"].append({"cluster": cluster, "content": "(render unavailable)"})
                elif rd:
                    sections["rendered_diff"].append({"cluster": cluster, "content": redact(rd)[: max(room() // 2, 0)]})

    # 3. file diffs (also needed for Terraform provider detection)
    for p in files:
        if is_sensitive_path(p):
            continue
        d = file_diff(a.base, a.head, p)
        all_diff += d
        red = filter_text(p, d)
        if red is None:
            dropped.append(p)
            continue
        if room() < 2000:
            dropped.append(p + " (budget)")
            continue
        kept.append(p)
        sections["diff"].append({"file": p, "content": red})

    tf = terraform_provider_usage(all_diff)
    if tf:
        sections["overrides"].append({"file": "(terraform)", "kind": "provider-usage", "content": redact(tf)})

    # 4. release notes
    body = open(a.pr_body_file, errors="replace").read() if a.pr_body_file and os.path.isfile(a.pr_body_file) else ""
    notes = trim_notes(body, max(min(room(), 120_000), 0))
    if a.fetch_releases and len(body) >= RELEASE_FETCH_THRESHOLD:
        notes += "\n\n" + fetch_release_notes(body)
    sections["release_notes"] = redact(notes)[: max(room(), 0)]

    bundle = {
        "schema": 1,
        "base_sha": a.base,
        "head_sha": a.head,
        "pr_title": redact(a.pr_title)[:300],
        "files": kept,
        "dropped": dropped,
        "sections": sections,
    }
    text = json.dumps(bundle)
    bundle["est_tokens"] = est_tokens(text)
    with open(a.out, "w") as f:
        json.dump(bundle, f)
    print("context: %d files kept, %d dropped, ~%d tokens" % (len(kept), len(dropped), bundle["est_tokens"]))


if __name__ == "__main__":
    main()
