---
name: flux-operations
description: FluxCD/GitOps operations for infra-cd — add/update apps, HelmRepositories, SOPS variable substitution, and dependency chains. Delegates YAML generation to kubernetes-agent with Ollama.
---

# FluxCD / GitOps Operations Skill

Use this skill when adding or modifying Kubernetes applications, Helm chart sources, or Flux configuration in any cluster.

## When to use

- Adding a new application to a cluster
- Adding a new Helm chart repository
- Updating a HelmRelease values
- Configuring SOPS-encrypted variable substitution
- Setting up `dependsOn` chains between applications
- Creating kubenuc-test overlay patches from kubenuc manifests

## Repository patterns

### Application directory structure

```
clusters/{cluster}/apps/{app-name}/
  deploy.yaml          # Flux Kustomization (namespace: flux-system)
  manifests/
    release.yml        # HelmRelease with chart sourceRef and values
    namespace.yaml     # Namespace (if needed)
    backup.yml         # Optional: PostgreSQL backup CronJob
  secrets/             # 1Password-backed secrets
    secret-name.yml    # OnePasswordItem CRD
```

### deploy.yaml template (Flux Kustomization)

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: {app-name}
  namespace: flux-system
spec:
  interval: 5m
  path: ./clusters/{cluster}/apps/{app-name}/manifests
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: {app-namespace}
  dependsOn:
    - name: openebs           # if app needs storage
    - name: {db-name}         # if app needs a database
  postBuild:
    substituteFrom:
      - kind: Secret
        name: cluster-vars    # for ${VAR} substitution from SOPS
```

### HelmRelease template

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: {app-name}
  namespace: {app-namespace}
spec:
  interval: 5m
  chart:
    spec:
      chart: {chart-name}
      version: ">=1.0.0 <2.0.0"
      sourceRef:
        kind: HelmRepository
        name: {repo-name}
        namespace: flux-system
  values:
    {}
```

### Dependency chain convention

```
openebs → {database} → {application}
```

Always declare `dependsOn` in Kustomization, not in HelmRelease.

### kubenuc-test overlay pattern

`kubenuc-test` reuses `kubenuc` manifests via path reference and applies JSON patches:

```yaml
# clusters/kubenuc-test/apps/{app}/deploy.yaml
spec:
  path: ./clusters/kubenuc/apps/{app}/manifests  # reuse production manifests
  patches:
    - patch: |-
        - op: replace
          path: /spec/values/replicas
          value: 1
      target:
        kind: HelmRelease
        name: {app-name}
```

### Storage class

Use `openebs-hostpath` for all persistent volumes (the default storage class on kubenuc).

### Sync intervals

- Apps: `5m` (default, do not go below)
- Charts: `15m`
- Infrastructure (openebs, cert-manager): `15m`

## SOPS variable substitution

Variables encrypted in `clusters/{cluster}/vars/cluster-vars.sops.yaml` are available as `${VAR_NAME}` in manifests when `postBuild.substituteFrom` references the `cluster-vars` Secret.

Common variables: `${S3_API_HOST}`, `${S3_WEB_HOST}`, `${CLUSTER_DOMAIN}`.

## Agent delegation

For YAML generation and kustomize validation, use the kubernetes-agent with Ollama:

```bash
cd docker/agents && docker compose up -d kubernetes-agent

# Validate after changes
docker compose exec kubernetes-agent kustomize build \
  /workspace/clusters/kubenuc/apps/{app-name}/manifests

# Generate HelmRelease values YAML via Ollama
docker compose exec kubernetes-agent sh -c \
  "echo 'Generate a HelmRelease for {chart} with openebs-hostpath storage' | \
   curl -s $OLLAMA_HOST/api/generate -d @-"
```

## Verification checklist

- [ ] `kustomize build` renders without errors for modified clusters
- [ ] `pre-commit run --all-files` passes (YAML lint, whitespace)
- [ ] `dependsOn` chain is complete and correct
- [ ] Secrets reference 1Password items (not raw values)
- [ ] `kubenuc-test` patches apply correctly if the app exists on both clusters
- [ ] PR created and CI validation passes
