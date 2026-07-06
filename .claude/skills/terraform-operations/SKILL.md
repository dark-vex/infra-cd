---
name: terraform-operations
description: Terraform operations for infra-cd — create new environments, write modules, set up CI workflows, update renovate config. Delegates HCL generation and validation to terraform-agent with Ollama.
---

# Terraform Operations Skill

Use this skill when creating new Terraform environments, writing modules, or setting up CI pipelines for Terraform.

## When to use

- Creating a new Terraform environment directory
- Writing or updating a reusable module under `terraform/modules/`
- Setting up a GitHub Actions CI workflow for a new environment
- Importing existing infrastructure into Terraform state
- Updating `renovate.json` for new provider/environment coverage
- Running `terraform fmt`, `validate`, `plan` via the agent

## Directory convention

Each environment follows this layout:

```
terraform/{environment}/
  terraform.tf      # Cloud backend + required_providers (always split from provider.tf)
  provider.tf       # Provider configs (sourced from 1Password data sources)
  variables.tf      # onepassword_token, onepassword_endpoint, plus env-specific vars
  data.tf           # 1Password data sources for credentials
  main.tf           # Resources and module calls
  outputs.tf        # Exported values
```

### terraform.tf template

```hcl
terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "{workspace-name}"
    }
  }
  required_providers {
    {provider} = {
      source  = "{source}"
      version = "~> {major}.{minor}"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.5.0"
}
```

### 1Password secret pattern

```hcl
# data.tf
data "onepassword_item" "credentials" {
  vault = "infra"
  title = "My Service API Credentials"
}

# provider.tf
provider "myservice" {
  api_token = data.onepassword_item.credentials.credential
}

provider "onepassword" {
  token    = var.onepassword_token
  url      = var.onepassword_endpoint
}

# variables.tf
variable "onepassword_token" {
  type      = string
  sensitive = true
}
variable "onepassword_endpoint" {
  type      = string
  sensitive = true
}
```

### Module convention

Reusable modules live under `terraform/modules/{module-name}/`:
- `main.tf` — resource with `lifecycle { prevent_destroy = true }`
- `variables.tf` — typed, documented variables
- `outputs.tf` — id, IPs, key identifiers
- `versions.tf` — `required_providers` with minimum version constraint

### Import blocks (Terraform 1.5+)

Prefer declarative import blocks over `terraform import` CLI:

```hcl
import {
  id = "provider-specific-resource-id"
  to = resource_type.resource_name
}
```

## CI workflow pattern

Copy from `.github/workflows/terraform.yml`. Adjust:
- `on.push.paths` and `on.pull_request.paths` to match the new directory
- `env.TF_WORKING_DIR` to the new directory
- `runs-on` to the appropriate runner:
  - `self-hosted` — generic / Hetzner / PSP (BGY)
  - `LGU` — Gozzi-01 / hpelvisor (LUG, Switzerland)
  - `mxp` — OVH EC200 (MXP, Italy)

Workflow stages: `fmt -check` → `init` → `validate` → `plan` (PR comment) → `apply` (main only).

## renovate.json update

When adding a new Terraform directory, add a matching `packageRules` entry in `renovate.json` if the directory needs separate grouping or a different commit scope from the defaults:

```json
{
  "description": "Terraform providers - {environment}",
  "matchManagers": ["terraform"],
  "matchFileNames": ["terraform/{environment}/**"],
  "groupName": "terraform-{environment}-providers",
  "semanticCommitType": "chore",
  "semanticCommitScope": "terraform-{environment}"
}
```

## Always run terraform fmt

CI enforces `terraform fmt -check`. Always format before committing:

```bash
docker compose exec terraform-agent sh -c "cd /workspace/terraform/{env} && terraform fmt"
```

## Agent delegation

```bash
cd docker/agents && docker compose up -d terraform-agent

# Validate a new environment
docker compose exec terraform-agent sh -c \
  "cd /workspace/terraform/{env} && terraform init && terraform validate"

# Security scan
docker compose exec terraform-agent checkov -d /workspace/terraform/{env} --quiet

# Generate HCL via Ollama (for boilerplate)
# Provide environment variables: TF_API_TOKEN, OP_TOKEN, OP_ENDPOINT
```

## Verification checklist

- [ ] `terraform fmt -check` passes
- [ ] `terraform init && terraform validate` succeeds
- [ ] Terraform Cloud workspace created in Fastnetserv org
- [ ] No raw secrets in `.tf` files — all sourced from 1Password
- [ ] `renovate.json` updated if directory needs separate tracking
- [ ] CI workflow file created and triggers on the correct path
- [ ] `CLAUDE.md` directory structure section updated
- [ ] PR created and CI plan output looks correct
