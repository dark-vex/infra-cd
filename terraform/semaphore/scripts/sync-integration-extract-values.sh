#!/usr/bin/env bash
# Upserts IntegrationExtractValue rows on a Semaphore integration via its
# raw REST API — see the terraform_data.selfreg_extract_values comment in
# ../main.tf for why this exists (no Terraform resource wraps these
# endpoints). Invoked as a local-exec provisioner; not meant to be run by
# hand outside that context, though it's safe to (idempotent).
#
# Env vars (all set by the calling terraform_data block):
#   SEMAPHORE_API_URL    e.g. https://<host>/api
#   SEMAPHORE_API_TOKEN  Semaphore admin API token (same one the provider
#                        itself uses — this project doesn't have its own
#                        least-privilege token for this narrow write)
#   PROJECT_ID
#   INTEGRATION_ID
#   EXTRACT_VALUES_JSON  JSON array of {name, key, variable}
set -euo pipefail

api="${SEMAPHORE_API_URL}/project/${PROJECT_ID}/integrations/${INTEGRATION_ID}/values"
auth=(-H "Authorization: Bearer ${SEMAPHORE_API_TOKEN}" -H "Content-Type: application/json")

existing=$(curl --fail-with-body -sS "${auth[@]}" "$api")

echo "$EXTRACT_VALUES_JSON" | jq -c '.[]' | while read -r want; do
  variable=$(jq -r '.variable' <<<"$want")

  matches=$(jq -r --arg v "$variable" '[.[] | select(.variable == $v) | .id]' <<<"$existing")
  match_count=$(jq -r 'length' <<<"$matches")
  if [[ "$match_count" -gt 1 ]]; then
    echo "ERROR: ${match_count} existing extract-values already target variable=${variable} — refusing to guess which to update. Resolve manually in the Semaphore UI first." >&2
    exit 1
  fi
  match_id=$(jq -r '.[0] // empty' <<<"$matches")

  # value_source/body_data_type/variable_type are fixed for this design
  # (flat JSON body -> environment var) — not part of `want` since every
  # entry uses the same shape.
  body=$(jq -c --argjson integration_id "$INTEGRATION_ID" \
    '. + {value_source: "body", body_data_type: "json", variable_type: "environment", integration_id: $integration_id}' \
    <<<"$want")

  if [[ -n "$match_id" ]]; then
    curl --fail-with-body -sS -X PUT "${auth[@]}" -d "$body" "${api}/${match_id}" >/dev/null
    echo "updated extract-value id=${match_id} (${variable})"
  else
    curl --fail-with-body -sS -X POST "${auth[@]}" -d "$body" "$api" >/dev/null
    echo "created extract-value (${variable})"
  fi
done
