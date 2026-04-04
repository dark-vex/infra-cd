#!/usr/bin/env bash

set -e

echo '{"api_token": "'$(curl -s $OP_ENDPOINT/v1/vaults/66qfxcmgwlhutunx6slav6fyve/items/mfukjucb7uuljtldpncj3erlz4 -H "Authorization: Bearer $OP_TOKEN" | jq '.fields[]| select(.label=="api_token") | .value' | tr -d '"')'"}'
