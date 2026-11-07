#!/usr/bin/env bash
set -euo pipefail

vars_file="${1:-ansible/seaweedfs/group_vars/seaweedfs.yml}"

read_var() {
  sed -n -E "s/^$1:[[:space:]]*\"?([^\"#]*)\"?[[:space:]]*(#.*)?$/\1/p" "$vars_file" | head -n1 | sed -E 's/[[:space:]]+$//'
}

version="$(read_var seaweedfs_version)"
arch="$(read_var seaweedfs_arch)"
pinned="$(read_var seaweedfs_download_checksum)"

if [ -z "$version" ] || [ -z "$arch" ] || [ -z "$pinned" ]; then
  echo "::error::could not read seaweedfs_version, seaweedfs_arch and seaweedfs_download_checksum from $vars_file"
  exit 1
fi

upstream="$(gh api "repos/seaweedfs/seaweedfs/releases/tags/${version}" \
  --jq ".assets[] | select(.name == \"${arch}.tar.gz\") | .digest")"

if [ -z "$upstream" ]; then
  echo "::error::no ${arch}.tar.gz asset or digest found for SeaweedFS ${version}"
  exit 1
fi

if [ "$pinned" != "$upstream" ]; then
  echo "::error file=${vars_file}::seaweedfs_download_checksum does not match the ${version} ${arch}.tar.gz release asset"
  echo "pinned:   ${pinned}"
  echo "upstream: ${upstream}"
  echo "Update seaweedfs_download_checksum to the upstream value when bumping seaweedfs_version."
  exit 1
fi

echo "seaweedfs_download_checksum matches ${version} ${arch}.tar.gz (${upstream})"
