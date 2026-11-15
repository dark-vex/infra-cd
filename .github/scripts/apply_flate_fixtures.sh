#!/usr/bin/env bash
# Overwrite offline-unresolvable files with CI fixtures so `flate` can render a
# cluster. Usage: apply_flate_fixtures.sh <cluster> [repo-root]
#
# Every fixture overwrites a real file in an ephemeral workspace only - nothing
# is ever committed or pushed. Shared by validate-flux-render.yml and the LLM
# PR review context build (llm-pr-review-context.yml).
#
# cluster-vars-ci.yaml replaces the SOPS-encrypted vars file (a non-sensitive
# placeholder for every ${VAR} referenced across all 4 clusters). The rest are
# per-app HelmRelease valuesFrom secrets that flate cannot resolve offline
# (1Password-backed) and whose charts hard-require a non-empty value - without
# them `flate build` fails outright for the whole cluster.
set -euo pipefail

cluster="${1:?usage: apply_flate_fixtures.sh <cluster> [repo-root]}"
root="${2:-.}"
fx="${FIXTURES_DIR:-$root/.github/fixtures}"

cp "$fx/cluster-vars-ci.yaml" "$root/clusters/$cluster/vars/cluster-vars.sops.yaml"

case "$cluster" in
  kubenuc)
    cp "$fx/kubenuc-grafana-cloud-credentials.yaml" "$root/clusters/kubenuc/apps/grafana-alloy/secrets/grafana-cloud-credentials.yml"
    cp "$fx/kubenuc-graylog-alloy-creds.yaml" "$root/clusters/kubenuc/apps/grafana-alloy/secrets/graylog-credentials.yml"
    cp "$fx/selfhosted-credentials.yaml" "$root/clusters/kubenuc/apps/grafana-alloy/secrets/selfhosted-credentials.yml"
    ;;
  k8s-vms-daniele)
    cp "$fx/kubenuc-grafana-cloud-credentials.yaml" "$root/clusters/k8s-vms-daniele/apps/grafana-alloy/secrets/grafana-cloud-credentials.yml"
    cp "$fx/k8s-vms-daniele-graylog-alloy-creds.yaml" "$root/clusters/k8s-vms-daniele/apps/grafana-alloy/secrets/graylog-credentials.yml"
    cp "$fx/selfhosted-credentials.yaml" "$root/clusters/k8s-vms-daniele/apps/grafana-alloy/secrets/selfhosted-credentials.yml"
    ;;
esac
