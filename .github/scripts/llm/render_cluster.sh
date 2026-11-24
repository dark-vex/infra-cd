#!/usr/bin/env bash
# Render one cluster with flate at a given tree, for the LLM review context.
# Usage: render_cluster.sh <cluster> <tree-root> <out-file>
# Best-effort: a failed/timed-out render leaves no output file (context builder
# then reports "render unavailable" and the review runs diff-only).
set -uo pipefail
cluster="${1:?}"; tree="${2:?}"; out="${3:?}"
# Fixtures/script always come from the head checkout (base may predate them),
# so base and head render under identical substitutions.
here="$(cd "$(dirname "$0")" && pwd)"
FIXTURES_DIR="$here/../../fixtures" "$here/../apply_flate_fixtures.sh" "$cluster" "$tree" || exit 0
# --concurrency 1: works around flate#828 (see validate-flux-render.yml).
if timeout 240 flate build all --path "$tree/clusters/$cluster" --allow-missing-kinds Secret,ConfigMap --concurrency 1 -o yaml > "$out.tmp" 2> "$out.err"; then
  mv "$out.tmp" "$out"
else
  echo "render failed for $cluster at $tree (see $out.err)" >&2
  rm -f "$out.tmp"
fi
exit 0
