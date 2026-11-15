#!/usr/bin/env python3
"""Stage 2 step 2: call the LLM, validate JSON, render Markdown, upsert PR comment.

Stdlib only. Model output is NEVER interpolated into workflow/script source: it
is parsed as JSON, schema-checked, and rendered into deterministic Markdown.

Env: LLM_BASE_URL, LLM_MODEL, LLM_API_KEY (provider swap = these three),
     LLM_JSON_MODE=object|schema (default object), LLM_EXTRA_BODY (JSON merged
     into the request; overrides defaults such as chat_template_kwargs),
     LLM_MAX_TOKENS (default 4000), GITHUB_TOKEN, GITHUB_API_URL.
"""
import argparse
import html
import json
import os
import random
import re
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ghapi  # noqa: E402
from llmlib import filter_text, redact, truncate_bytes  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MARKER_PREFIX = "<!-- llm-review "
RISKS = {"low", "medium", "high", "unknown"}
RECS = {"merge", "merge_with_followup", "hold"}
SCHEMA = {
    "name": "renovate_review",
    "strict": True,
    "schema": {
        "type": "object",
        "additionalProperties": False,
        "required": ["risk", "breaking", "values_impact", "recommendation"],
        "properties": {
            "risk": {"type": "string", "enum": sorted(RISKS)},
            "breaking": {"type": "array", "items": {
                "type": "object", "additionalProperties": False,
                "required": ["evidence", "file", "key"],
                "properties": {"evidence": {"type": "string"}, "file": {"type": "string"}, "key": {"type": "string"}}}},
            "values_impact": {"type": "string"},
            "recommendation": {"type": "string", "enum": sorted(RECS)},
        },
    },
}


class LLMUnavailable(Exception):
    pass


def _log_error_body(e):
    """Print the server's error text (never our request or key) to ease diagnosis."""
    try:
        text = e.read(600).decode("utf-8", errors="replace")
    except Exception:
        text = ""
    print("llm error body: %s" % redact(" ".join(text.split()))[:500], file=sys.stderr)


# ---- request ---------------------------------------------------------------------

def build_user_message(ctx):
    s = ctx["sections"]
    parts = ["PR title (data): %s" % ctx.get("pr_title", "")]
    parts.append("<overrides>\n%s\n</overrides>" % "\n\n".join("# %s (%s)\n%s" % (o["file"], o["kind"], o["content"]) for o in s["overrides"]))
    parts.append("<rendered_diff>\n%s\n</rendered_diff>" % "\n\n".join("# cluster %s\n%s" % (r["cluster"], r["content"]) for r in s["rendered_diff"]))
    parts.append("<diff>\n%s\n</diff>" % "\n\n".join("# %s\n%s" % (d["file"], d["content"]) for d in s["diff"]))
    parts.append("<release_notes>\n%s\n</release_notes>" % s["release_notes"])
    return "<data>\n" + "\n\n".join(parts) + "\n</data>\n\nReturn the JSON object now."


def call_llm(system, user, max_attempts=6):
    base = os.environ["LLM_BASE_URL"].rstrip("/")
    body = {
        "model": os.environ["LLM_MODEL"],
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "temperature": 0,
        # Phase 0: Qwen3.6 with thinking on can spend the whole budget on reasoning
        # and return empty content, so keep generous headroom.
        "max_tokens": int(os.environ.get("LLM_MAX_TOKENS", "4000")),
        # Thinking off by default (vLLM-style switch; probed working on the endpoint).
        "chat_template_kwargs": {"enable_thinking": False},
    }
    if os.environ.get("LLM_JSON_MODE", "object") == "schema":
        body["response_format"] = {"type": "json_schema", "json_schema": SCHEMA}
    else:
        body["response_format"] = {"type": "json_object"}
    if os.environ.get("LLM_EXTRA_BODY"):
        body.update(json.loads(os.environ["LLM_EXTRA_BODY"]))
    data = json.dumps(body).encode()
    last = "no attempt"
    for attempt in range(max_attempts):
        req = urllib.request.Request(base + "/chat/completions", data=data, method="POST", headers={
            "Content-Type": "application/json", "Authorization": "Bearer " + os.environ["LLM_API_KEY"]})
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                resp = json.load(r)
            return resp, time.time() - t0
        except urllib.error.HTTPError as e:
            last = "HTTP %d" % e.code
            _log_error_body(e)
            if e.code == 429:
                try:
                    delay = float(e.headers.get("Retry-After", ""))
                except ValueError:
                    delay = 15.0 * (attempt + 1)
            elif e.code >= 500:
                delay = 5.0 * (2 ** attempt)
            else:
                raise LLMUnavailable(last)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            last = type(e).__name__
            delay = 5.0 * (2 ** attempt)
        if attempt < max_attempts - 1:
            time.sleep(min(delay, 70.0) + random.uniform(0, 3))
    raise LLMUnavailable(last)


# ---- validation + rendering ----------------------------------------------------------

def extract_json(text):
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*|\s*```$", "", text)
    try:
        return json.loads(text)
    except ValueError:
        m = re.search(r"\{.*\}", text, re.DOTALL)
        if not m:
            raise
        return json.loads(m.group(0))


def validate(obj):
    if not isinstance(obj, dict):
        raise ValueError("not an object")
    if obj.get("risk") not in RISKS or obj.get("recommendation") not in RECS:
        raise ValueError("bad risk/recommendation")
    br = obj.get("breaking")
    if not isinstance(br, list) or len(br) > 25:
        raise ValueError("bad breaking")
    for b in br:
        if not isinstance(b, dict) or not all(isinstance(b.get(k), str) for k in ("evidence", "file", "key")):
            raise ValueError("bad breaking item")
    if not isinstance(obj.get("values_impact"), str):
        raise ValueError("bad values_impact")
    return obj


def clean(text, limit=400):
    """Neutralise mentions, HTML, links, and markdown structure in model text."""
    text = redact(str(text))[:limit]
    text = html.escape(text, quote=False)
    text = text.replace("@", "@​")
    text = re.sub(r"(?i)https?://", "hxxp://", text)
    text = re.sub(r"[`\[\]|]", "'", text)
    return " ".join(text.split())


def render(obj, ctx, model, latency, usage):
    files = set(ctx.get("files", []))
    sha = ctx["head_sha"]
    icon = {"low": "🟢", "medium": "🟡", "high": "🔴", "unknown": "⚪"}[obj["risk"]]
    lines = [
        "%ssha=%s -->" % (MARKER_PREFIX, sha),
        "### LLM review (advisory)",
        "",
        "**Risk:** %s %s · **Suggestion:** `%s`" % (icon, obj["risk"], obj["recommendation"]),
        "",
    ]
    if obj["breaking"]:
        lines += ["| Evidence | File | Key |", "|---|---|---|"]
        for b in obj["breaking"]:
            f = b["file"] if b["file"] in files else "%s (not in diff)" % b["file"]
            lines.append("| %s | `%s` | `%s` |" % (clean(b["evidence"]), clean(f, 200).replace("'", ""), clean(b["key"], 120).replace("'", "")))
        lines.append("")
    else:
        lines += ["No breaking changes identified from the supplied context.", ""]
    lines += ["**Values impact:** " + clean(obj["values_impact"]), ""]
    lines.append("<sub>Reviewed `%s` at %s UTC with `%s` (%.1fs, %s tokens). Advisory only; not an approval. May be wrong.</sub>" % (
        sha[:12], time.strftime("%Y-%m-%d %H:%M", time.gmtime()), clean(model, 80), latency,
        "%s/%s" % (usage.get("prompt_tokens", "?"), usage.get("completion_tokens", "?"))))
    return truncate_bytes("\n".join(lines), 55_000)


def render_unavailable(ctx, why):
    return "%ssha=%s -->\n### LLM review (advisory)\n\nLLM unavailable (%s). Review manually; this check never blocks merging." % (
        MARKER_PREFIX, ctx["head_sha"], clean(why, 80))


# ---- comment upsert --------------------------------------------------------------------

def find_comment(repo, pr):
    for c in ghapi.paginate("/repos/%s/issues/%d/comments" % (repo, pr)):
        if c["user"]["login"] == "github-actions[bot]" and MARKER_PREFIX in c["body"]:
            return c
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--in-dir", required=True)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()

    ctx = json.load(open(os.path.join(a.in_dir, "context.json")))
    pr = json.load(open(os.path.join(a.in_dir, "pr.json")))["number"]
    marker = "%ssha=%s -->" % (MARKER_PREFIX, ctx["head_sha"])

    # Second filtering pass: the artifact is untrusted.
    for sec in ("diff", "overrides"):
        ctx["sections"][sec] = [x for x in ctx["sections"][sec]
                                if filter_text(x.get("file", ""), x["content"]) is not None]
        for x in ctx["sections"][sec]:
            x["content"] = redact(x["content"])
    for r in ctx["sections"]["rendered_diff"]:
        r["content"] = redact(r["content"])
    ctx["sections"]["release_notes"] = redact(ctx["sections"]["release_notes"])

    existing = None if a.dry_run else find_comment(a.repo, pr)
    if existing and marker in existing["body"] and not a.force:
        print("already reviewed this SHA; skipping")
        return

    system = open(os.path.join(HERE, "prompts", "renovate_review.md")).read()
    model = os.environ["LLM_MODEL"]
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    try:
        resp, latency = call_llm(system, build_user_message(ctx))
        usage = resp.get("usage", {})
        content = resp["choices"][0]["message"]["content"]
        body = render(validate(extract_json(content)), ctx, model, latency, usage)
        status = "ok"
    except LLMUnavailable as e:
        body, status, latency, usage = render_unavailable(ctx, str(e)), "unavailable", 0.0, {}
    except (ValueError, KeyError, IndexError) as e:
        body, status, latency, usage = render_unavailable(ctx, "invalid model output"), "invalid", 0.0, {}
        print("validation failure: %s" % type(e).__name__, file=sys.stderr)

    line = "llm-review pr=%d status=%s model=%s latency=%.1fs prompt_tokens=%s completion_tokens=%s ctx_est_tokens=%s" % (
        pr, status, model, latency, usage.get("prompt_tokens", "?"), usage.get("completion_tokens", "?"), ctx.get("est_tokens"))
    print(line)
    if summary:
        with open(summary, "a") as f:
            f.write("```\n%s\n```\n" % line)

    if a.dry_run:
        print(body)
        return
    if existing:
        ghapi.request("PATCH", "/repos/%s/issues/comments/%d" % (a.repo, existing["id"]), {"body": body})
    else:
        ghapi.request("POST", "/repos/%s/issues/%d/comments" % (a.repo, pr), {"body": body})


if __name__ == "__main__":
    main()
