#!/bin/sh
set -eu

# The base image's own /usr/local/bin/runner-wrapper only supports
# `--no-config` env-var mode, which has no way to set `web_host` (it's a
# config-file-only field - confirmed empirically, no SEMAPHORE_* env var
# exists for it). So this replaces that wrapper entirely: it uses the
# static config file baked/mounted at CONFIG_FILE (which carries web_host)
# and only calls `runner register` the first time, guarded by whether a
# runner identity has already been persisted to TOKEN_FILE - the PVC this
# is mounted from is what makes that guard meaningful across pod restarts.
CONFIG_FILE=/etc/semaphore/config.runner.json
TOKEN_FILE=/data/runner_token.txt

if [ ! -s "$TOKEN_FILE" ]; then
  echo "No persisted runner token at ${TOKEN_FILE}; registering with server" >&2
  # --enabled=true is required, not just documentation: the "enabled" cobra
  # flag defaults to true but is only applied when explicitly passed
  # (registerRunner's applyRunnerRegisterFlags checks Changed("enabled")),
  # so without this flag the server persists Active=false (Go's bool
  # zero-value) and the runner polls successfully but never receives real
  # tasks until an admin flips it on via the API/UI - confirmed against a
  # live registration.
  printf '%s' "$SEMAPHORE_RUNNER_REGISTRATION_TOKEN" |
    semaphore runner register --config "$CONFIG_FILE" --stdin-registration-token --enabled=true
fi

exec semaphore runner start --config "$CONFIG_FILE"
