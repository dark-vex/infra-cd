#!/usr/bin/env bash
# Commits a single already-modified file to a branch via the GitHub Contents
# API instead of `git commit`+`git push`. Commits created this way carry
# GitHub's automatic Verified signature (server-side signing tied to the API
# call itself, independent of which token made the request) — this repo's
# branch protection requires signed commits, and a plain unsigned commit
# pushed from a runner would make a PR permanently unmergeable.
#
# Usage: commit-file-via-api.sh <path> <branch> <commit message>
# Requires: gh (authenticated via GH_TOKEN), git (repo checked out at <branch>
# with the working tree already containing the new file content on disk).
set -euo pipefail

FILE_PATH="$1"
BRANCH="$2"
MESSAGE="$3"

CURRENT_SHA=$(git rev-parse "HEAD:${FILE_PATH}")
CONTENT_B64=$(base64 <"$FILE_PATH" | tr -d '\n')

gh api --method PUT "repos/${GITHUB_REPOSITORY}/contents/${FILE_PATH}" \
  -f message="$MESSAGE" \
  -f content="$CONTENT_B64" \
  -f branch="$BRANCH" \
  -f sha="$CURRENT_SHA" \
  >/dev/null
