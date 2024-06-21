#!/usr/bin/env bash

set -e

echo '{"otp": "'$(curl -s $OP_ENDPOINT/v1/vaults/66qfxcmgwlhutunx6slav6fyve/items/h7fhsftvpum7r4b3rnqznz4lym -H "Authorization: Bearer $OP_TOKEN" | jq '.fields[]| select(.label=="token") | .totp' | tr -d '"')'", "api_token": "'$(curl -s $OP_ENDPOINT/v1/vaults/66qfxcmgwlhutunx6slav6fyve/items/h7fhsftvpum7r4b3rnqznz4lym -H "Authorization: Bearer $OP_TOKEN" | jq '.fields[]| select(.label=="api_token") | .value' | tr -d '"')'"}'
