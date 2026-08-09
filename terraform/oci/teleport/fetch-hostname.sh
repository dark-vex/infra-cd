#!/usr/bin/env bash
# Retrieves the Teleport proxy hostname from 1Password (root-level custom
# field, not in a section - not exposed via the onepassword_item data
# source, hence this external data source workaround).
set -e

VAULT_ID="66qfxcmgwlhutunx6slav6fyve"
ITEM_ID="hzbfm4ovwqv5w5vbv475e4i2dm"

HOSTNAME=$(curl -s "$OP_ENDPOINT/v1/vaults/$VAULT_ID/items/$ITEM_ID" \
  -H "Authorization: Bearer $OP_TOKEN" | \
  jq -r '.fields[] | select(.label=="hostname") | .value')

echo "{\"hostname\": \"$HOSTNAME\"}"
