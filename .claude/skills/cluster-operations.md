---
name: cluster-operations
description: Cluster lifecycle operations — setting up new clusters, kubenuc-test overlay pattern, kustomize patch conventions, and FluxCD bootstrap structure for infra-cd clusters.
---

# Cluster Operations Skill

Use this skill when bootstrapping a new cluster, understanding the kubenuc-test overlay pattern, or troubleshooting cluster Kustomization structure.

## When to use

- Adding a brand new cluster under `clusters/`
- Creating kubenuc-test-style overlay patches that reuse kubenuc manifests
- Understanding what files are required for a functioning FluxCD cluster
- Checking which apps exist on which clusters

## Cluster directory structure

Every cluster needs:

```
clusters/{cluster-name}/
  kustomization.yaml          # Root Kustomization (optional, for direct apply)
  flux-instance.yaml          # FluxInstance or flux-system bootstrap
  apps.yaml                   # Flux Kustomization → ./apps/
  charts.yaml                 # Flux Kustomization → ./charts/
  cluster-vars.yaml           # Reference to SOPS-encrypted cluster-vars Secret
  vars/
    cluster-vars.sops.yaml    # SOPS-encrypted cluster variables
  apps/
    kustomization.yaml        # Lists all app directories
    {app-name}/
      deploy.yaml
      manifests/
      secrets/
  charts/
    kustomization.yaml        # Lists all HelmRepository/GitRepository files
    {repo-name}.yml
  flux-system/
    kustomization.yaml
    gotk-components.yaml      # FluxCD controllers (managed by flux bootstrap)
    gotk-sync.yaml            # GitRepository + Kustomization for flux-system
```

## kubenuc-test overlay pattern

`kubenuc-test` is a resource-reduced overlay of `kubenuc`. It reuses production manifests directly and patches them:

```yaml
# clusters/kubenuc-test/apps/{app}/deploy.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: {app-name}
  namespace: flux-system
spec:
  interval: 5m
  path: ./clusters/kubenuc/apps/{app}/manifests   # <-- points to kubenuc
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: {app-namespace}
  dependsOn:
    - name: {dependency}
  postBuild:
    substituteFrom:
      - kind: Secret
        name: cluster-vars
  patches:
    # Scale down replicas
    - patch: |-
        - op: replace
          path: /spec/values/replicaCount
          value: 1
      target:
        kind: HelmRelease
        name: {app-name}
    # Shrink storage
    - patch: |-
        - op: replace
          path: /spec/values/persistence/size
          value: 1Gi
      target:
        kind: HelmRelease
        name: {app-name}
```

**Chart sources**: `kubenuc-test/charts.yaml` points its Kustomization path to `./clusters/kubenuc/charts`, so it inherits all kubenuc chart sources automatically. No separate chart file changes are needed for apps that only exist on kubenuc-test.

## Cluster variable substitution

Each cluster needs its own SOPS-encrypted variables. Variables use the cluster prefix convention:
- `kubenuc`: `${S3_API_HOST}`, `${CLUSTER_DOMAIN}`
- `kubenuc-test`: `${TST_S3_API_HOST}`, `${TST_CLUSTER_DOMAIN}`

## App dependency ordering

Standard ordering that must be respected:

```
cert-manager (if TLS needed)
    ↓
openebs
    ↓
{database} (PostgreSQL via Zalando operator)
    ↓
{application}
```

For apps without storage or database needs, omit the preceding steps.

## Kubernetes clusters in this repo

| Cluster | Type | Purpose | Special notes |
|---|---|---|---|
| `kubenuc` | Bare metal | Primary production | 3 CP + 3 workers, HAProxy ingress |
| `kubenuc-test` | Bare metal | Pre-production | Overlays kubenuc manifests, reduced resources |
| `k3s-prod-test` | k3s | Production-like test | Independent manifests |
| `k3s-rabbit` | k3s | Rabbit server cluster | Lightweight |
| `k8s-vms-daniele` | VMs | Development | AWX, independent apps |
| `oc-ampere` | OpenShift | ARM/Ampere OCI | Teleport agent only |

## Agent delegation

Use kubernetes-agent to validate Kustomization builds:

```bash
cd docker/agents && docker compose up -d kubernetes-agent

# Validate cluster structure
docker compose exec kubernetes-agent kustomize build \
  /workspace/clusters/{cluster-name}/apps/{app}/manifests

# Check all clusters build cleanly
for cluster in kubenuc kubenuc-test k3s-prod-test k3s-rabbit k8s-vms-daniele; do
  echo "=== $cluster ==="
  docker compose exec kubernetes-agent kustomize build \
    /workspace/clusters/$cluster/apps 2>&1 | tail -3
done
```

## Verification checklist

- [ ] All required files present in new cluster directory
- [ ] `kustomize build` succeeds for modified cluster(s)
- [ ] SOPS age key added to `.sops.yaml` for new clusters
- [ ] FluxCD bootstrap completed on the actual cluster (`flux bootstrap`)
- [ ] `cluster-vars` Secret decryptable by cluster's age key
- [ ] `dependsOn` chains are complete
- [ ] kubenuc-test patches apply without errors if the app is mirrored
