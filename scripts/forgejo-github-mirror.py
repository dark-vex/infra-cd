#!/usr/bin/env python3
"""
Forgejo GitHub Bulk Mirror Script

One-off tool to bulk-create Forgejo pull mirrors for a curated list of GitHub
repositories. Not part of the Flux-managed manifests - run manually, once,
after the Forgejo instance (clusters/kubenuc/apps/forgejo/) is live and
reachable.

Deliberately scoped to a curated repo list rather than "every repo in the
account" - kubenuc has a documented disk-pressure incident history
(kubenuc-w2, 2026-07), and an unbounded account-wide mirror is a materially
larger, unbounded growth profile than a curated one.

Forgejo has no bulk/account-wide mirror toggle - this script drives the
per-repo "New Migration" API (POST /api/v1/repos/migrate) once per repo,
skipping any repo that already exists on the instance (idempotent - safe to
re-run against a partially-completed list).

Requires two distinct tokens, never the same credential:
  - FORGEJO_TOKEN: a Forgejo API token (Settings -> Applications -> Generate
    New Token), needs repo create/migrate scope.
  - GITHUB_TOKEN: a separate, least-privilege GitHub fine-grained PAT
    (read-only, Contents + Metadata, scoped to only the repos being
    mirrored). Never Forgejo's own admin credential, never a GitHub PAT with
    write access. Revoke it after the initial import unless ongoing
    authenticated pulls are actually needed.

Usage:
    export FORGEJO_TOKEN=...
    export GITHUB_TOKEN=...
    python3 forgejo-github-mirror.py \\
        --forgejo-url https://<forgejo-host> \\
        --forgejo-owner myorg \\
        --repos-file repos.txt

repos.txt format: one "github_owner/repo_name" per line, blank lines and
lines starting with # ignored. The mirrored repo is created in Forgejo under
the same repo_name as GitHub.

Every migrated repo is created as mirror=true, private=true, pull-only - no
push-back capability to GitHub is configured.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

RETRYABLE_STATUSES = {429, 500, 502, 503, 504}
MAX_RETRIES = 5
BACKOFF_BASE_SECONDS = 2


def redact(token: str) -> str:
    if not token or len(token) < 8:
        return "***"
    return f"{token[:4]}...{token[-4:]}"


def api_request(
    url: str,
    method: str,
    token: str,
    body: dict | None = None,
) -> tuple[int, dict]:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"token {token}")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")

    last_status = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read()
                parsed = json.loads(raw) if raw else {}
                return resp.status, parsed
        except urllib.error.HTTPError as e:
            last_status = e.code
            raw = e.read()
            try:
                parsed = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                parsed = {"message": raw.decode("utf-8", errors="replace")}
            if e.code not in RETRYABLE_STATUSES or attempt == MAX_RETRIES:
                return e.code, parsed
            sleep_for = BACKOFF_BASE_SECONDS**attempt
            print(
                f"  [retry {attempt}/{MAX_RETRIES}] HTTP {e.code}, "
                f"backing off {sleep_for}s",
                file=sys.stderr,
            )
            time.sleep(sleep_for)
        except urllib.error.URLError as e:
            last_status = -1
            if attempt == MAX_RETRIES:
                print(f"  network error: {e}", file=sys.stderr)
                return -1, {"message": str(e)}
            sleep_for = BACKOFF_BASE_SECONDS**attempt
            print(
                f"  [retry {attempt}/{MAX_RETRIES}] network error, "
                f"backing off {sleep_for}s",
                file=sys.stderr,
            )
            time.sleep(sleep_for)
    return last_status, {}


def repo_exists(forgejo_url: str, forgejo_token: str, owner: str, repo: str) -> bool:
    status, _ = api_request(
        f"{forgejo_url}/api/v1/repos/{owner}/{repo}", "GET", forgejo_token
    )
    return status == 200


def migrate_repo(
    forgejo_url: str,
    forgejo_token: str,
    github_token: str,
    forgejo_owner: str,
    github_owner: str,
    repo: str,
) -> bool:
    body = {
        "clone_addr": f"https://github.com/{github_owner}/{repo}.git",
        "repo_owner": forgejo_owner,
        "repo_name": repo,
        "service": "github",
        "mirror": True,
        "private": True,
        "auth_token": github_token,
        "wiki": True,
        "releases": True,
        "mirror_interval": "8h0m0s",
    }
    status, resp = api_request(
        f"{forgejo_url}/api/v1/repos/migrate", "POST", forgejo_token, body
    )
    if status in (200, 201):
        return True
    message = resp.get("message", "") if isinstance(resp, dict) else ""
    print(f"  FAILED: HTTP {status} {message}", file=sys.stderr)
    return False


def parse_repos_file(path: str) -> list[tuple[str, str]]:
    repos = []
    with open(path) as f:
        for lineno, line in enumerate(f, start=1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "/" not in line:
                print(
                    f"  skipping malformed line {lineno} in {path}: {line!r} "
                    "(expected github_owner/repo_name)",
                    file=sys.stderr,
                )
                continue
            owner, repo = line.split("/", 1)
            repos.append((owner.strip(), repo.strip()))
    return repos


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--forgejo-url", required=True, help="e.g. https://<forgejo-host>")
    parser.add_argument("--forgejo-owner", required=True, help="Forgejo user/org to own the mirrors")
    parser.add_argument("--repos-file", required=True, help="Path to curated github_owner/repo list")
    args = parser.parse_args()

    forgejo_token = os.environ.get("FORGEJO_TOKEN")
    github_token = os.environ.get("GITHUB_TOKEN")
    if not forgejo_token or not github_token:
        print(
            "FORGEJO_TOKEN and GITHUB_TOKEN must both be set in the environment",
            file=sys.stderr,
        )
        return 1

    forgejo_url = args.forgejo_url.rstrip("/")
    repos = parse_repos_file(args.repos_file)
    if not repos:
        print(f"No repos parsed from {args.repos_file}, nothing to do", file=sys.stderr)
        return 1

    print(
        f"Forgejo: {forgejo_url} (token {redact(forgejo_token)})  "
        f"GitHub PAT: {redact(github_token)}  repos: {len(repos)}"
    )

    created, skipped, failed = 0, 0, 0
    for github_owner, repo in repos:
        print(f"{github_owner}/{repo} -> {args.forgejo_owner}/{repo}")
        if repo_exists(forgejo_url, forgejo_token, args.forgejo_owner, repo):
            print("  already exists, skipping")
            skipped += 1
            continue
        if migrate_repo(
            forgejo_url,
            forgejo_token,
            github_token,
            args.forgejo_owner,
            github_owner,
            repo,
        ):
            print("  migrated")
            created += 1
        else:
            failed += 1

    print(f"\nDone. created={created} skipped={skipped} failed={failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
