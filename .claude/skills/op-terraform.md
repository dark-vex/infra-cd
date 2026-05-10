---
name: op-terraform
description: 1Password Terraform provider (v3) — provider config, data sources, field access patterns, resource management. Use when reading or writing 1Password items from Terraform (data.tf, provider.tf, modules).
---

# 1Password Terraform Provider Skill

Use this skill whenever reading credentials from 1Password in Terraform (`data.tf`) or managing 1Password items as Terraform resources.

## When to use

- Adding a new `data "onepassword_item"` to source credentials
- Accessing a specific custom field from an existing item
- Troubleshooting provider auth errors or missing-attribute errors
- Creating/managing 1Password items as Terraform resources
- Setting up provider config in a new environment

---

## Provider configuration (v3)

Provider source: `1Password/onepassword`, version `~> 3.0`.

```hcl
# terraform.tf
terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }
}
```

### Auth method 1 — Connect Server (used in this repo)

```hcl
provider "onepassword" {
  connect_url   = var.onepassword_endpoint   # OP_CONNECT_HOST env var alternative
  connect_token = var.onepassword_token      # OP_CONNECT_TOKEN env var alternative
}
```

Variables in `variables.tf`:

```hcl
variable "onepassword_token" {
  type      = string
  sensitive = true
}
variable "onepassword_endpoint" {
  type      = string
  sensitive = true
}
```

In CI (`terraform-psp.yml` pattern):

```yaml
run: terraform plan -var onepassword_token=$OP_TOKEN -var onepassword_endpoint=$OP_ENDPOINT
env:
  OP_TOKEN: '${{ secrets.OP_TOKEN }}'
  OP_ENDPOINT: '${{ secrets.OP_ENDPOINT }}'
```

### Auth method 2 — Service Account

```hcl
provider "onepassword" {
  service_account_token = var.op_service_account_token  # or OP_SERVICE_ACCOUNT_TOKEN env var
}
```

### Auth method 3 — 1Password Desktop App

```hcl
provider "onepassword" {
  account = "my.1password.com"  # or OP_ACCOUNT env var
}
```

---

## Data source: `onepassword_item`

```hcl
data "onepassword_item" "example" {
  vault = local.onepassword_vault   # vault UUID or name
  uuid  = "item-uuid-here"         # prefer UUID over title for stability
  # title = "My Item"              # alternative to uuid
}
```

---

## CRITICAL: Field access guide

### Well-known fields (direct attributes — always available)

These are always available as direct data source attributes regardless of item structure:

| Attribute | Category |
|---|---|
| `hostname` | database, login |
| `username` | login |
| `password` | login, password |
| `credential` | api_credential |
| `note_value` | secure_note |
| `url` | login |
| `database` | database |
| `port` | database |
| `type` | database, api_credential |
| `tags` | all |
| `private_key` / `private_key_openssh` | ssh_key |
| `public_key` | ssh_key |
| `valid_from` / `filename` | api_credential |

```hcl
endpoint  = data.onepassword_item.my_server.hostname
api_token = data.onepassword_item.my_creds.credential
password  = data.onepassword_item.my_creds.password
```

### Custom fields IN a named section — use `section_map` (preferred)

`section_map` is a map keyed by section label. Only works if the field is inside a named section in 1Password.

```hcl
data "onepassword_item" "example" {
  vault = local.onepassword_vault
  uuid  = "item-uuid"
}

locals {
  api_token = data.onepassword_item.example.section_map["Section Name"].field_map["api_token"].value
}
```

**Cannot use `section` and `section_map` together** — pick one.

### Custom fields IN a section — list approach (fallback)

```hcl
locals {
  api_token = one(flatten([
    for s in data.onepassword_item.example.section : [
      for f in s.field : f.value if f.label == "api_token"
    ]
  ]))
}
```

### Root-level custom fields (NO section) — NOT accessible via data source

**The data source cannot expose root-level custom fields** — fields that exist in the item but are not inside any named section and are not one of the well-known typed attributes above. Attempting `section.field` will return empty; attempting to set `section { field { label = ... } }` is invalid (read-only attribute error).

**Workaround — external data source via Connect API:**

```hcl
# data.tf
data "external" "my_custom_field" {
  program = ["${path.module}/read-op-field.sh"]
}
```

```bash
#!/usr/bin/env bash
# read-op-field.sh — requires OP_ENDPOINT and OP_TOKEN env vars
set -e
VAULT_ID="..."
ITEM_ID="..."
VALUE=$(curl -s "$OP_ENDPOINT/v1/vaults/$VAULT_ID/items/$ITEM_ID" \
  -H "Authorization: Bearer $OP_TOKEN" | \
  jq -r '.fields[] | select(.label=="api_token") | .value')
echo "{\"value\": \"$VALUE\"}"
```

```hcl
# provider.tf
api_token = data.external.my_custom_field.result.value
```

**Better long-term fix:** move the custom field into a named section in 1Password, then use `section_map`.

### INVALID patterns — DO NOT USE

```hcl
# WRONG: section/field blocks in a data source are read-only — will error at plan time
data "onepassword_item" "bad" {
  vault = local.vault
  uuid  = "..."
  section {
    field {
      label = "api_token"   # ERROR: Cannot set value for read-only attribute
    }
  }
}

# WRONG: .api_token is not a standard attribute on the data source
api_token = data.onepassword_item.example.api_token
```

---

## Resource: `onepassword_item`

Use only when Terraform should own and create the 1Password item. For reading existing items always use the data source.

```hcl
# Create an item with a section using section_map (preferred)
resource "onepassword_item" "my_service" {
  vault    = local.onepassword_vault
  title    = "My Service Credentials"
  category = "login"
  username = "admin"
  url      = "https://my-service.example.com"

  section_map = {
    "API" = {
      field_map = {
        "api_token" = {
          type  = "CONCEALED"
          value = var.api_token
        }
      }
    }
  }
}

# Create a login with a generated password
resource "onepassword_item" "db_user" {
  vault    = local.onepassword_vault
  title    = "Database User"
  category = "login"
  username = "app_user"

  password_recipe {
    length  = 32
    symbols = false
  }
}
```

### Import existing item

```hcl
import {
  id = "vaults/<vault-uuid>/items/<item-uuid>"
  to = onepassword_item.my_resource
}
```

---

## Data source: `onepassword_vault`

```hcl
data "onepassword_vault" "infra" {
  name = "infra"        # or uuid = "..."
}

data "onepassword_item" "example" {
  vault = data.onepassword_vault.infra.uuid
  uuid  = "item-uuid"
}
```

---

## Repo conventions (infra-cd)

- Vault UUIDs are hardcoded as `locals` in `data.tf` — not looked up by name
- Provider always uses `connect_url` / `connect_token` (Connect Server) — never service account
- `onepassword_token` and `onepassword_endpoint` variables are always in `variables.tf`
- CI passes them via `-var` flags; `OP_TOKEN`/`OP_ENDPOINT` are set as env vars in the workflow step
- Items with **root-level custom fields** use `data "external"` + shell script against the Connect API
- Items with **sectioned custom fields** use `section_map` lookup
- No `onepassword_item` resources — all items are pre-created manually; Terraform only reads them

---

## Verification checklist

- [ ] Provider uses `connect_url` / `connect_token` (not `token` / `url` — v1/v2 names, broken in v3)
- [ ] Well-known fields accessed as direct attributes (`hostname`, `password`, `credential`, etc.)
- [ ] Sectioned custom fields accessed via `section_map["Section"].field_map["label"].value`
- [ ] No `section { field { label = ... } }` blocks in data sources — read-only error
- [ ] Root-level custom fields use `data "external"` with a Connect API shell script
- [ ] `OP_TOKEN` and `OP_ENDPOINT` are exported as env vars in any step that calls an `external` data source
- [ ] `terraform validate` passes with no unsupported attribute errors
