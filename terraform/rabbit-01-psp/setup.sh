#!/usr/bin/env bash

set -e

echo '{"otp": "'$(curl -s "${{ secrets.OP_ENDPOINT }}"/v1/vaults/66qfxcmgwlhutunx6slav6fyve/items/h7fhsftvpum7r4b3rnqznz4lym -H "Authorization: Bearer "${{ secrets.OP_TOKEN }}"" | jq '.fields[]| select(.label=="token") | .totp' | tr -d '"')'"}'
