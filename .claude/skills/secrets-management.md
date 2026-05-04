---
name: secrets-management
description: Secrets management patterns for infra-cd — 1Password Operator (OnePasswordItem/ExternalSecret), SOPS age encryption for FluxCD variable substitution and bootstrap secrets, and Terraform 1Password provider.
---

# Secrets Management Skill

Use this skill when adding, rotating, or troubleshooting secrets in Kubernetes, Terraform, or FluxCD variable substitution.

## When to use

- Adding a new application that needs Kubernetes secrets
- Setting up SOPS-encrypted cluster variables for FluxCD substitution
- Adding SOPS-encrypted bootstrap secrets for apps that must exist before the 1Password Operator runs
- Configuring the 1Password Terraform provider for a new environment
- Troubleshooting missing or stale secrets in a cluster

## Pattern 1: 1Password Operator (Kubernetes secrets)

Use `OnePasswordItem` for injecting 1Password items directly as Kubernetes `Secret` resources.

### OnePasswordItem CRD

```yaml
# clusters/{cluster}/apps/{app}/secrets/my-secret.yml
apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: my-secret
  namespace: {app-namespace}
spec:
  itemPath: "vaults/{vault-name}/items/{item-title}"
```

The operator creates a matching `Secret` with the same name. Fields in the 1Password item become keys in the Secret.

**Convention:** Store all K8s secrets under vault `k8s_secrets`. Item title matches the Kubernetes secret name.

### ExternalSecret (alternative)

Used when you need to transform or select specific fields:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: {app-namespace}
spec:
  secretStoreRef:
    name: onepassword-connect
    kind: ClusterSecretStore
  target:
    name: my-secret
  data:
    - secretKey: username
      remoteRef:
        key: vaults/{vault}/items/{item}
        property: username
    - secretKey: password
      remoteRef:
        key: vaults/{vault}/items/{item}
        property: password
```

## Pattern 2: SOPS-encrypted cluster variables

FluxCD uses `cluster-vars` Secret for `${VAR}` substitution in manifests. The Secret is created from a SOPS-encrypted file.

### File location

```
clusters/{cluster}/vars/cluster-vars.sops.yaml
```

### Adding a new variable

1. Decrypt the file: `sops clusters/{cluster}/vars/cluster-vars.sops.yaml`
2. Add the new key under `data:` (all values must be base64 or plain string)
3. Save (SOPS re-encrypts on save)
4. Reference in manifests as `${MY_VAR_NAME}`

### Age key management

Each cluster has its own age key in `.sops.yaml`:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: clusters/{cluster}/vars/.*\.sops\.yaml
    age: age1...{cluster-public-key}...
```

**Never commit age private keys (`.agekey` files) — they are gitignored.**

The age private key must be available as a Kubernetes Secret named `sops-age` in `flux-system` namespace for FluxCD to decrypt during reconciliation.

## Pattern 3: SOPS-encrypted bootstrap secrets (K8s Secret)

Use this pattern for apps that must be provisioned **before** the 1Password Operator is running — specifically, any app whose credentials are required to start the 1Password Connect operator itself (e.g. `1password-connect-credentials`).

### Why SOPS instead of OnePasswordItem here

`OnePasswordItem` requires the 1Password Operator to already be running. For the operator's own credentials you need a chicken-and-egg workaround: encrypt the Secret with SOPS age and let a dedicated child Flux Kustomization (with `spec.decryption.provider: sops`) create it before the operator starts.

### Required file layout — TWO kustomization.yaml files are mandatory

```
clusters/{cluster}/apps/{app-name}/
├── kustomization.yaml          # app-level — lists ONLY deploy.yaml
├── deploy.yaml                 # defines {app}-secrets child Kustomization with decryption block
└── secrets/
    ├── kustomization.yaml      # secrets-level — lists the .sops.yaml file
    └── my-credentials.sops.yaml
```

**Why both files are required:**

The top-level `apps` Flux Kustomization auto-scans `clusters/{cluster}/apps/` recursively. Its behaviour:
- Directory **with** `kustomization.yaml` → treated as a kustomize component (recursion stops here)
- Directory **without** `kustomization.yaml` → recurse and include every YAML file directly

Without `apps/{app}/kustomization.yaml`, Flux recurses into `{app}/`, then into `{app}/secrets/`, finds the SOPS-encrypted file, and fails immediately with `Object 'Kind' is missing` because `apiVersion` and `kind` are both encrypted fields. The `apps` Kustomization has no SOPS decryption and cannot recover.

### app-level kustomization.yaml

```yaml
# clusters/{cluster}/apps/{app-name}/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deploy.yaml
```

This is intentionally minimal — `deploy.yaml` defines the child Kustomizations, which own `manifests/` and `secrets/` separately.

### secrets-level kustomization.yaml

```yaml
# clusters/{cluster}/apps/{app-name}/secrets/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - my-credentials.sops.yaml
```

This is used by the `{app}-secrets` child Kustomization (which has `spec.decryption.provider: sops`). Without it, Flux auto-generates the resource list and still finds the SOPS file — having the explicit file is better practice and matches the `falco/secrets/kustomization.yaml` pattern.

### deploy.yaml child Kustomization with SOPS decryption

```yaml
# clusters/{cluster}/apps/{app-name}/deploy.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: {app-name}-secrets
  namespace: flux-system
spec:
  targetNamespace: {app-namespace}
  interval: 15m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/{cluster}/apps/{app-name}/secrets
  prune: true
  decryption:
    provider: sops
    secretRef:
      name: sops-age   # age private key pre-loaded in flux-system during bootstrap
```

### SOPS configuration in .sops.yaml

Add a creation rule for the new path so `sops` uses the correct age key:

```yaml
# .sops.yaml
creation_rules:
  # existing cluster-vars rule ...
  - path_regex: clusters/{cluster}/apps/{app-name}/secrets/.*\.sops\.yaml$
    age: {cluster-age-public-key}
```

### Encrypting the bootstrap secret

```bash
# Create the plain Secret manifest first (NEVER commit this file)
cat > /tmp/my-credentials.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-credentials
  namespace: {app-namespace}
stringData:
  token: "..."
  credentials: "..."
EOF

# Encrypt in-place using .sops.yaml path rules
sops --encrypt /tmp/my-credentials.yaml > \
  clusters/{cluster}/apps/{app-name}/secrets/my-credentials.sops.yaml

rm /tmp/my-credentials.yaml
```

### Verification

```bash
# Confirm decryption works (requires SOPS_AGE_KEY env var or ~/.config/sops/age/keys.txt)
sops -d clusters/{cluster}/apps/{app-name}/secrets/my-credentials.sops.yaml

# Dry-run the kustomize build for the secrets path
kustomize build clusters/{cluster}/apps/{app-name}/secrets  # should fail (can't decrypt locally without key)
flux build kustomization {app-name}-secrets --path clusters/{cluster}/apps/{app-name}/secrets  # cluster-side
```

## Pattern 4: Terraform 1Password provider

Always source Terraform provider credentials from 1Password, never hardcode:

```hcl
# variables.tf
variable "onepassword_token" {
  type      = string
  sensitive = true
}
variable "onepassword_endpoint" {
  type      = string
  sensitive = true
}

# provider.tf
provider "onepassword" {
  token = var.onepassword_token
  url   = var.onepassword_endpoint
}

# data.tf
data "onepassword_item" "my_credentials" {
  vault = "infra"
  title = "My Service"
}

# main.tf (usage)
resource "some_resource" "example" {
  api_key = data.onepassword_item.my_credentials.credential
}
```

In CI, `OP_TOKEN` and `OP_ENDPOINT` are passed as environment variables from GitHub Actions secrets.

## Never commit

- Raw Kubernetes `Secret` manifests with `data:` base64 values
- `.env` files
- TLS certificates or SSH private keys
- API tokens or passwords in plaintext
- Age private keys (`.agekey`)

## Verification checklist

- [ ] 1Password item created in correct vault (`k8s_secrets` for K8s, `infra` for Terraform)
- [ ] `OnePasswordItem` itemPath matches the exact vault + item title
- [ ] SOPS-encrypted file re-encrypted after adding new variables
- [ ] FluxCD `postBuild.substituteFrom` references `cluster-vars` Secret
- [ ] `sops -d clusters/{cluster}/vars/cluster-vars.sops.yaml` decrypts without error
- [ ] No plaintext secrets in git history (`git log -p` check)
- [ ] **SOPS bootstrap secrets only:** `apps/{app}/kustomization.yaml` exists and lists only `deploy.yaml`
- [ ] **SOPS bootstrap secrets only:** `apps/{app}/secrets/kustomization.yaml` exists and lists the `.sops.yaml` file
- [ ] **SOPS bootstrap secrets only:** child Kustomization in `deploy.yaml` has `spec.decryption.provider: sops` + `secretRef: sops-age`
- [ ] **SOPS bootstrap secrets only:** `.sops.yaml` has a `path_regex` rule covering the new secrets path
