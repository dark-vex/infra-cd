#!/usr/bin/env bash
# Retrieves API token from 1Password for rabbit-01-psp
set -e

VAULT_ID="66qfxcmgwlhutunx6slav6fyve"
ITEM_ID="h7fhsftvpum7r4b3rnqznz4lym"

# Get API token from 1Password
API_TOKEN=$(curl -s "$OP_ENDPOINT/v1/vaults/$VAULT_ID/items/$ITEM_ID" \
  -H "Authorization: Bearer $OP_TOKEN" | \
  jq -r '.fields[] | select(.label=="api_token") | .value')

# Output as JSON for Terraform external data source
echo "{\"api_token\": \"$API_TOKEN\"}"
