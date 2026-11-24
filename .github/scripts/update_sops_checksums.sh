#!/usr/bin/env bash
# Renovate postUpgradeTask (and the sops-checksum PR guard, with --check): keep
# the per-arch SOPS_SHA256 pins next to SOPS_VERSION in step with the release's
# published sops-vX.Y.Z.checksums.txt. Both files must pin the same version.
# Nothing is written unless every file validates and every replacement hits
# exactly one amd64 and one arm64 line.
#
#   update_sops_checksums.sh           rewrite the pins
#   update_sops_checksums.sh --check   only compare, exit 1 on any mismatch
#
# Test hooks: REPO_ROOT (default .) and SOPS_CHECKSUMS_FILE (use a local
# checksums file instead of downloading it).
set -euo pipefail

mode="update"
case "${1:-}" in
  "") ;;
  --check) mode="check" ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

root="${REPO_ROOT:-.}"
files=("awx-ee/execution-environment.yml" "docker/agents/ansible/Dockerfile")

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

version=""
for f in "${files[@]}"; do
  v="$(sed -n -E 's/.*SOPS_VERSION=([0-9][0-9.]*).*/\1/p' "$root/$f" | head -n1)"
  if ! [[ "$v" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo "invalid or missing SOPS_VERSION in $f: '${v}'" >&2
    exit 1
  fi
  if [ -n "$version" ] && [ "$v" != "$version" ]; then
    echo "SOPS_VERSION differs between files: ${version} vs ${v} (${f})" >&2
    exit 1
  fi
  version="$v"
done

sums="${SOPS_CHECKSUMS_FILE:-$tmpdir/checksums.txt}"
if [ -z "${SOPS_CHECKSUMS_FILE:-}" ]; then
  curl -fsSL --retry 3 -o "$sums" \
    "https://github.com/getsops/sops/releases/download/v${version}/sops-v${version}.checksums.txt"
fi

hash_for() {
  local name="sops-v${version}.linux.$1" out
  out="$(awk -v n="$name" '$2 == n { print $1 }' "$sums")"
  if [ "$(printf '%s\n' "$out" | grep -c .)" -ne 1 ] || ! [[ "$out" =~ ^[0-9a-f]{64}$ ]]; then
    echo "expected exactly one sha256 for ${name} in the checksums file, got: '${out}'" >&2
    exit 1
  fi
  printf '%s' "$out"
}
amd64="$(hash_for amd64)"
arm64="$(hash_for arm64)"

rc=0
for f in "${files[@]}"; do
  out="$tmpdir/$(echo "$f" | tr '/' '_')"
  awk -v amd="$amd64" -v arm="$arm64" '
    /SOPS_SHA256=[0-9a-f]+/ && /amd64/ { sub(/SOPS_SHA256=[0-9a-f]+/, "SOPS_SHA256=" amd); na++ }
    /SOPS_SHA256=[0-9a-f]+/ && /arm64/ { sub(/SOPS_SHA256=[0-9a-f]+/, "SOPS_SHA256=" arm); nr++ }
    { print }
    END { if (na != 1 || nr != 1) { printf "expected one amd64 and one arm64 SOPS_SHA256 line, found %d and %d\n", na, nr > "/dev/stderr"; exit 1 } }
  ' "$root/$f" > "$out" || { echo "cannot update $f" >&2; exit 1; }
  if ! cmp -s "$root/$f" "$out"; then
    if [ "$mode" = "check" ]; then
      echo "::error file=${f}::SOPS_SHA256 pins do not match the v${version} checksums file" >&2
      rc=1
    fi
  fi
done

if [ "$mode" = "check" ]; then
  [ "$rc" -eq 0 ] && echo "sops ${version}: pins match the published checksums"
  exit "$rc"
fi

for f in "${files[@]}"; do
  cat "$tmpdir/$(echo "$f" | tr '/' '_')" > "$root/$f"
done
echo "sops ${version}: SOPS_SHA256 refreshed in ${#files[@]} files"
