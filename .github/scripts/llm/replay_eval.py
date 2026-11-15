#!/usr/bin/env python3
"""Replay the LLM Renovate review over merged PRs and measure it (local, stdlib).

Never posts anywhere. Reads past Renovate PRs through `gh`, builds the same
filtered context as stage 1 (diff-only: no flate render, so Helm render diffs are
not part of this measurement), calls the model once per PR (throttled below the
per-key request limit), and writes per-PR results plus a recall / false-alarm
report.

Positives ("the PR later caused trouble") are guessed from git history and meant
to be corrected by hand in <out>/labels.json before trusting the report:
  - a later commit whose subject is a revert mentioning the PR number, or
  - a human (non-bot) commit pushed onto the Renovate branch before merge, or
  - a fix merge (branch fix/ or hotfix/) within --fix-days touching a file the
    PR changed (lockfile and version-only churn is not filtered; review them).

Usage (from the repo root, with the endpoint env set; key via file):
  LLM_BASE_URL=... LLM_MODEL=... LLM_API_KEY_FILE=~/.hetzner_llm_key \\
    python3 -I .github/scripts/llm/replay_eval.py --out /tmp/replay --limit 300
Resumable: PRs already in <out>/results.jsonl are skipped. --labels-only writes
labels.json and stops (review it, then rerun without the flag). --dry-run builds
contexts and prints sizes without calling the model.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import review  # noqa: E402
from llmlib import filter_text  # noqa: E402

BOT = "app/renovate-gihub-app"


def sh(*args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True).stdout


def list_prs(limit):
    out = sh("gh", "pr", "list", "--state", "merged", "--author", BOT, "-L", str(limit),
             "--json", "number,title,body,mergeCommit,mergedAt,headRefName")
    prs = json.loads(out)
    prs.sort(key=lambda p: p["mergedAt"])
    return prs


def parents(merge_oid):
    p = sh("git", "rev-list", "--parents", "-n", "1", merge_oid).split()
    return (p[1], p[2]) if len(p) == 3 else None  # None: squash/rebase, no merge commit


def history():
    """First-parent merge commits with the files they brought in."""
    raw = sh("git", "log", "--first-parent", "--merges", "--name-only",
             "--format=@@%H|%aI|%s")
    items, cur = [], None
    for line in raw.splitlines():
        if line.startswith("@@"):
            h, d, s = line[2:].split("|", 2)
            cur = {"oid": h, "date": datetime.fromisoformat(d), "subject": s, "files": set()}
            items.append(cur)
        elif line.strip() and cur is not None:
            cur["files"].add(line.strip())
    return items


def pr_files(base, head):
    return set(sh("git", "diff", "--name-only", "%s...%s" % (base, head)).split())


def guess_labels(prs, fix_days):
    hist = history()
    labels = {}
    for pr in prs:
        n = pr["number"]
        why = []
        t0 = datetime.fromisoformat(pr["mergedAt"].replace("Z", "+00:00"))
        for h in hist:
            if h["date"] <= t0:
                continue
            if re.search(r"(?i)\brevert\b", h["subject"]) and re.search(r"#%d\b" % n, h["subject"]):
                why.append("reverted by " + h["oid"][:8])
        par = parents(pr["mergeCommit"]["oid"]) if pr.get("mergeCommit") else None
        if par:
            files = {f for f in pr_files(*par) if not f.endswith((".lock", ".lock.hcl", "package-lock.json"))}
            for h in hist:
                if not (t0 < h["date"] <= t0 + timedelta(days=fix_days)):
                    continue
                if re.search(r"from \S+/(fix|hotfix)[/-]", h["subject"]) and files & h["files"]:
                    why.append("fix %s touches %s" % (h["oid"][:8], sorted(files & h["files"])[0]))
                    break
        if par:
            authors = sh("git", "log", "--no-merges", "--format=%an|%ae", "%s..%s" % (par[0], par[1])).splitlines()
            human = [x for x in authors if not re.search(r"(?i)renovate|\[bot\]", x)]
            if human:
                why.append("%d human commit(s) on the bot branch" % len(human))
        labels[str(n)] = {"positive": bool(why), "why": why, "title": pr["title"][:100]}
    return labels


def flagged(res):
    return res["risk"] in ("medium", "high") or res["recommendation"] in ("merge_with_followup", "hold") \
        or bool(res["breaking"])


def metrics(results, labels):
    rows = []
    for r in results:
        lab = labels.get(str(r["pr"]), {})
        rows.append((r, bool(lab.get("positive")), r["status"] == "ok" and flagged(r["result"])))
    ok = [x for x in rows if x[0]["status"] == "ok"]
    pos = [x for x in ok if x[1]]
    neg = [x for x in ok if not x[1]]
    return {
        "reviewed": len(rows), "usable": len(ok), "failed": len(rows) - len(ok),
        "positives": len(pos), "negatives": len(neg),
        "recall": (sum(1 for x in pos if x[2]) / len(pos)) if pos else None,
        "false_alarm_rate": (sum(1 for x in neg if x[2]) / len(neg)) if neg else None,
        "flagged_overall": (sum(1 for x in ok if x[2]) / len(ok)) if ok else None,
    }


def write_report(out, results, labels):
    m = metrics(results, labels)
    pct = lambda v: "n/a" if v is None else "%.0f%%" % (100 * v)
    lines = ["# LLM review replay", "",
             "Diff-only contexts (no flate render). Labels are heuristic unless you edited labels.json.", "",
             "- reviewed: %(reviewed)d (usable %(usable)d, failed %(failed)d)" % m,
             "- positives: %d, negatives: %d" % (m["positives"], m["negatives"]),
             "- **recall** (flagged among positives): %s" % pct(m["recall"]),
             "- **false-alarm rate** (flagged among negatives): %s" % pct(m["false_alarm_rate"]),
             "- flagged overall: %s" % pct(m["flagged_overall"]), "",
             "## Positives", ""]
    for r in results:
        lab = labels.get(str(r["pr"]), {})
        if lab.get("positive"):
            res = r.get("result") or {}
            lines.append("- #%d %s: %s (risk=%s, rec=%s) - %s" % (
                r["pr"], lab.get("title", ""), "FLAGGED" if r["status"] == "ok" and flagged(res) else "missed",
                res.get("risk", r["status"]), res.get("recommendation", "-"), "; ".join(lab.get("why", []))))
    with open(os.path.join(out, "report.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--limit", type=int, default=300)
    ap.add_argument("--rate-per-min", type=float, default=8.0)
    ap.add_argument("--fix-days", type=int, default=14)
    ap.add_argument("--labels-only", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    if os.environ.get("LLM_API_KEY_FILE") and not os.environ.get("LLM_API_KEY"):
        with open(os.path.expanduser(os.environ["LLM_API_KEY_FILE"])) as f:
            os.environ["LLM_API_KEY"] = f.read().strip()

    prs = list_prs(a.limit)
    lpath = os.path.join(a.out, "labels.json")
    if os.path.exists(lpath):
        labels = json.load(open(lpath))
    else:
        labels = guess_labels(prs, a.fix_days)
        with open(lpath, "w") as f:
            json.dump(labels, f, indent=1)
        print("wrote %s (%d positives guessed); edit it to correct labels" % (
            lpath, sum(1 for v in labels.values() if v["positive"])))
    if a.labels_only:
        return

    rpath = os.path.join(a.out, "results.jsonl")
    done = set()
    results = []
    if os.path.exists(rpath):
        for line in open(rpath):
            r = json.loads(line)
            done.add(r["pr"])
            results.append(r)

    system = open(os.path.join(HERE, "prompts", "renovate_review.md")).read()
    gap = 60.0 / a.rate_per_min
    last = 0.0
    for pr in prs:
        n = pr["number"]
        if n in done:
            continue
        par = parents(pr["mergeCommit"]["oid"]) if pr.get("mergeCommit") else None
        if not par:
            print("#%d skipped (no merge commit)" % n)
            continue
        with tempfile.TemporaryDirectory() as td:
            body = os.path.join(td, "body.md")
            with open(body, "w") as f:
                f.write(pr.get("body") or "")
            ctxf = os.path.join(td, "ctx.json")
            subprocess.run([sys.executable, "-I", os.path.join(HERE, "build_context.py"), "--base", par[0],
                            "--head", par[1], "--pr-title", pr["title"], "--pr-body-file", body, "--out", ctxf],
                           check=True, capture_output=True)
            ctx = json.load(open(ctxf))
        for sec in ("diff", "overrides"):  # same second pass as stage 2
            ctx["sections"][sec] = [x for x in ctx["sections"][sec] if filter_text(x.get("file", ""), x["content"]) is not None]
        rec = {"pr": n, "est_tokens": ctx.get("est_tokens"), "status": "dry-run"}
        if not a.dry_run:
            wait = gap - (time.time() - last)
            if wait > 0:
                time.sleep(wait)
            last = time.time()
            try:
                resp, latency = review.call_llm(system, review.build_user_message(ctx))
                content = resp["choices"][0]["message"]["content"]
                rec.update(status="ok", result=review.validate(review.extract_json(content)),
                           latency=round(latency, 1), usage=resp.get("usage"))
            except review.LLMUnavailable as e:
                rec.update(status="unavailable", error=str(e))
            except (ValueError, KeyError, IndexError) as e:
                rec.update(status="invalid", error=type(e).__name__)
        results.append(rec)
        with open(rpath, "a") as f:
            f.write(json.dumps(rec) + "\n")
        print("#%d %s ~%s tokens %s" % (n, rec["status"], rec["est_tokens"],
                                       (rec.get("result") or {}).get("risk", "")))
    if not a.dry_run:
        m = write_report(a.out, results, labels)
        print(json.dumps(m, indent=1))
        print("report:", os.path.join(a.out, "report.md"))


if __name__ == "__main__":
    main()
