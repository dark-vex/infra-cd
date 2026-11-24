#!/usr/bin/env bash
# Print ONE fixed, generic hint for a failed terraform run, chosen by looking at
# the raw log. The log text itself is never echoed, filtered or transformed:
# Terraform errors can embed API response bodies, hostnames, import IDs or
# tokens, and the runner log and the PR comment are public. Every string below
# is a constant with no backticks, dollar-brace or backslashes, so it is safe to
# interpolate into a GitHub Actions JS template literal.
#
# usage: tf-error-hint.sh <logfile>
set -euo pipefail

log="${1:?usage: tf-error-hint.sh <logfile>}"

has() { grep -qiE -- "$1" "$log" 2>/dev/null; }

if has '<!doctype html|<html|invalid character .<. looking for beginning of value'; then
  echo "The API answered with an HTML page instead of JSON, typically a Cloudflare Access login redirect: check the Access service token and the app policies."
elif has 'stack_env allowlist'; then
  echo "A Portainer stack's declared env_vars do not match its 1Password item (a declared name is missing or invalid): run terraform plan locally to see which."
elif has 'error acquiring the state lock|state lock'; then
  echo "The Terraform state is locked by another run: wait for it or release the lock."
elif has '(^|[^0-9])(401|403)([^0-9]|$)|unauthori[sz]ed|forbidden|invalid (api )?(token|credentials)|authentication failed'; then
  echo "The provider was rejected (authentication or authorization failure): check the API token and its permissions."
elif has 'connection refused|no such host|i/o timeout|context deadline exceeded|dial tcp|tls: |connection reset|eof'; then
  echo "The provider could not reach the API (connectivity or TLS failure): check that the target service is up and reachable from the runner."
else
  echo "The failure does not match a known class."
fi
