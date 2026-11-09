#!/usr/bin/env bash
# Renovate postUpgradeTask: after Renovate bumps seaweedfs_version, recompute
# seaweedfs_download_checksum from the release asset. Upstream publishes only
# md5 sidecars, so the sha256 is taken from the downloaded archive itself
# (trust on first use). The vars file is only rewritten on full success.
set -euo pipefail

vars_file="ansible/seaweedfs/group_vars/seaweedfs.yml"

read_var() {
  sed -n -E "s/^$1:[[:space:]]*\"?([^\"#]*)\"?[[:space:]]*(#.*)?$/\1/p" "$vars_file" | head -n1 | sed -E 's/[[:space:]]+$//'
}

version="$(read_var seaweedfs_version)"
arch="$(read_var seaweedfs_arch)"

if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "invalid or missing seaweedfs_version in $vars_file: '${version}'" >&2
  exit 1
fi
if ! [[ "$arch" =~ ^[a-z0-9_]+$ ]]; then
  echo "invalid or missing seaweedfs_arch in $vars_file: '${arch}'" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

url="https://github.com/seaweedfs/seaweedfs/releases/download/${version}/${arch}.tar.gz"
curl -fsSL --retry 3 -o "$tmpdir/asset.tar.gz" "$url"

if command -v sha256sum >/dev/null 2>&1; then
  digest="$(sha256sum "$tmpdir/asset.tar.gz" | cut -d' ' -f1)"
else
  digest="$(shasum -a 256 "$tmpdir/asset.tar.gz" | cut -d' ' -f1)"
fi

if ! [[ "$digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "unexpected sha256 digest: '${digest}'" >&2
  exit 1
fi

awk -v new="seaweedfs_download_checksum: \"sha256:${digest}\"" '
  /^seaweedfs_download_checksum:/ { print new; done = 1; next }
  { print }
  END { if (!done) exit 1 }
' "$vars_file" > "$tmpdir/vars.yml"

cat "$tmpdir/vars.yml" > "$vars_file"
echo "seaweedfs_download_checksum set to sha256:${digest} for ${version} ${arch}"
