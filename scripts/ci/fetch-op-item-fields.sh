#!/usr/bin/env bash
# Fetches named fields from a 1Password Connect item and prints them as
# NAME=value lines (uppercased), one per requested field, for consumption by
# `echo "$line" >> "$GITHUB_OUTPUT"` in a workflow step. Mirrors the same
# 1Password Connect REST call already used by
# terraform/proxmox/*/setup-*.sh (data.external token fetch) — this script
# just generalizes it to any field name and adds the item's `hostname`.
#
# Usage: fetch-op-item-fields.sh <vault_id> <item_id> <field>...
set -euo pipefail

VAULT_ID="$1"
ITEM_ID="$2"
shift 2

ITEM_JSON=$(curl -s "${OP_ENDPOINT}/v1/vaults/${VAULT_ID}/items/${ITEM_ID}" \
  -H "Authorization: Bearer ${OP_TOKEN}")

for field in "$@"; do
  if [ "$field" = "hostname" ]; then
    value=$(echo "$ITEM_JSON" | jq -r '.urls[]? | select(.primary==true) | .href' 2>/dev/null)
    if [ -z "$value" ] || [ "$value" = "null" ]; then
      value=$(echo "$ITEM_JSON" | jq -r '.fields[] | select(.label=="hostname" or .id=="hostname") | .value')
    fi
  else
    value=$(echo "$ITEM_JSON" | jq -r --arg f "$field" '.fields[] | select(.label==$f) | .value')
  fi
  name=$(echo "$field" | tr '[:lower:]' '[:upper:]')
  echo "${name}=${value}"
done
