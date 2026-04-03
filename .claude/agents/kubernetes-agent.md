---
name: kubernetes-agent
description: Kubernetes/Helm/FluxCD specialist agent. Use for kubectl operations, helm template rendering, flux manifest validation, kustomize builds, and GitOps troubleshooting. Runs in an isolated Docker container with kubectl, helm, flux, and kustomize installed.
---

# Kubernetes / Helm / FluxCD Agent

This agent specializes in Kubernetes, Helm, and FluxCD operations for the infra-cd repository.

## Available tools in the container

- `kubectl` (v1.33.x)
- `helm` (v3.17.x)
- `flux` CLI (v2.7.5)
- `kustomize` (v5.6.x)
- `yq`, `jq`, `git`, `curl`

## How to invoke

```bash
# Start the container (once)
cd docker/agents && docker compose up -d kubernetes-agent

# Validate kustomize builds for a cluster
docker compose exec kubernetes-agent kustomize build /workspace/clusters/kubenuc/apps/nextcloud/manifests

# Render Helm chart values
docker compose exec kubernetes-agent helm template nextcloud nextcloud/nextcloud -f /workspace/clusters/kubenuc/apps/nextcloud/manifests/release.yml

# Validate Flux Kustomization manifests
docker compose exec kubernetes-agent flux check --pre

# Run kubectl against a live cluster (requires kubeconfig mount)
docker compose exec kubernetes-agent kubectl get pods -A
```

## Workspace layout

All cluster configs mounted read-only at `/workspace/clusters/`:
- `/workspace/clusters/kubenuc/`
- `/workspace/clusters/kubenuc-test/`
- `/workspace/clusters/k8s-vms-daniele/`
- `/workspace/clusters/k3s-prod-test/`
- `/workspace/clusters/common/`

## Notes

- kubeconfig mounted from host's `~/.kube/config` (read-only)
- For production cluster operations, always prefer GitOps (commit → PR → merge)
- Ollama available at `$OLLAMA_HOST` for YAML generation (recommended: `qwen2.5-coder:32b` on RTX5090)
