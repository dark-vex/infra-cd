---
name: secrets-management
description: Secrets management patterns for infra-cd — 1Password Operator (OnePasswordItem/ExternalSecret), SOPS age encryption for FluxCD variable substitution, and Terraform 1Password provider.
---

# Secrets Management Skill

Use this skill when adding, rotating, or troubleshooting secrets in Kubernetes, Terraform, or FluxCD variable substitution.

## When to use

- Adding a new application that needs Kubernetes secrets
- Setting up SOPS-encrypted cluster variables for FluxCD substitution
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

## Pattern 3: Terraform 1Password provider

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
