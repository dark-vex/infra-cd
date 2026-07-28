# Proxmox self-registration: Semaphore project (item 1 of the self-
# registration follow-up list — see PR #1733 and
# docs/proxmox-modules-cloud-init-handoff-plan.md). Runs
# scripts/semaphore-netbox-register.py when a Proxmox guest's cloud-init
# callback POSTs {token, ip} to the webhook this creates.
#
# Design verified against the real semaphoreui/semaphore backend source
# (api/integration.go, db/sql/integration_alias.go) and the vendored
# semaphoreui/semaphore provider 0.3.9 schema — not just the plan text —
# via two independent reviews (Codex + Fable) that both read the same
# source and converged. Key findings baked into this file, not obvious
# from the provider docs alone:
#
# - auth_secret_id MUST reference a login_password-type key, never a
#   "none" key: ReceiveIntegration reads
#   integration.AuthSecret.LoginPassword.Password for hmac/token auth.
# - searchable must stay false (the default) on the integration — a
#   single-integration alias (integration_id set, our design) resolves via
#   GetIntegrationsByAlias's IntegrationAliasSingle path, which 404s if the
#   target integration has searchable=true.
# - The same single-integration-alias path means matchers never evaluate
#   here — only the /values extract-value mapping matters, so no matcher
#   sync is needed (see the terraform_data block below for why /values
#   itself still needs a local-exec escape hatch).
# - One "none"-type key covers both inventory (schema requires
#   ssh_key_id but nothing here ever touches a real host) and the
#   repository (dark-vex/infra-cd is public — confirmed via `gh api
#   repos/dark-vex/infra-cd -q .private` returning false — so an https
#   clone needs no credentials).

resource "semaphoreui_project" "proxmox_selfreg" {
  name = "proxmox-self-registration"
}

# Single "none" key: satisfies both the inventory's and repository's
# required ssh_key_id without a real credential existing for either.
resource "semaphoreui_project_key" "none" {
  project_id = semaphoreui_project.proxmox_selfreg.id
  name       = "none"
  none       = {}
}

# Webhook front-door secret (HMAC gate on semaphoreui_project_integration
# below) — deliberately NOT the Semaphore admin API token used by this
# stack's own provider config (data.onepassword_item.semaphore): that
# token has full instance access and must never be handed to a
# guest-facing webhook. password_wo (write-only) keeps the secret out of
# Terraform state entirely; bump password_wo_version to rotate it.
resource "semaphoreui_project_key" "webhook_secret" {
  project_id = semaphoreui_project.proxmox_selfreg.id
  name       = "proxmox-selfreg-webhook-hmac"
  login_password = {
    password_wo         = data.onepassword_item.selfreg_webhook_secret.credential
    password_wo_version = 1
  }
}

# Required by project_template's schema even though app="python" never
# reads inventory content — the "none" key + a throwaway localhost target
# satisfies it without implying any real host access.
resource "semaphoreui_project_inventory" "selfreg" {
  project_id = semaphoreui_project.proxmox_selfreg.id
  name       = "unused-selfreg-inventory"
  ssh_key_id = semaphoreui_project_key.none.id
  static = {
    inventory = "localhost ansible_connection=local\n"
  }
}

# Static, template-scoped config only — SELFREG_TOKEN/SELFREG_IP (the
# actual per-request values) come from the extract-value sync below, never
# from here. Delivered to the runner at task-dispatch time by Semaphore's
# own control plane, scoped to this one project's tasks only — distinct
# from (and narrower than) the runner pod's own SEMAPHORE_FORWARDED_ENV_VARS
# mechanism, which is runner-wide and would leak these into unrelated
# Ansible task executions if used instead. See terraform/CLAUDE.md.
#
# GITHUB_APP_ID/GITHUB_APP_INSTALLATION_ID/GITHUB_APP_PRIVATE_KEY_PATH and
# TF_TOKEN_app_terraform_io are still not added: the GitHub App's
# credentials aren't in 1Password yet, and the scoped TFC "Read outputs
# only" token doesn't exist yet either (needs creating in HCP Terraform's
# own UI first). Add them here once they do, rather than guessing at
# vault/item references now.
resource "semaphoreui_project_environment" "selfreg" {
  project_id = semaphoreui_project.proxmox_selfreg.id
  name       = "proxmox-selfreg"

  environment = {
    GITHUB_REPOSITORY = "dark-vex/infra-cd"
  }

  # NETBOX_URL lives here, not in `environment` above: per this repo's own
  # convention (root CLAUDE.md — hostnames/FQDNs are sensitive regardless
  # of how they look), a plain map value would show up in plan/apply
  # output and Terraform state in cleartext. `secrets` values are marked
  # sensitive by the provider schema, matching how NETBOX_TOKEN is already
  # handled below.
  secrets = [
    {
      type  = "env"
      name  = "NETBOX_URL"
      value = data.onepassword_item.netbox.url
    },
    {
      type  = "env"
      name  = "NETBOX_TOKEN"
      value = data.onepassword_item.netbox.password
    },
    {
      type  = "env"
      name  = "SOPS_AGE_KEY_NETBOX"
      value = data.onepassword_item.sops_keys.section_map[""].file_map["age-netbox.agekey"].content
    },
  ]
}

resource "semaphoreui_project_repository" "infra_cd" {
  project_id = semaphoreui_project.proxmox_selfreg.id
  name       = "infra-cd"
  url        = "https://github.com/dark-vex/infra-cd.git"
  branch     = "main"
  ssh_key_id = semaphoreui_project_key.none.id
}

resource "semaphoreui_project_template" "selfreg" {
  project_id     = semaphoreui_project.proxmox_selfreg.id
  name           = "proxmox-netbox-selfreg"
  app            = "python"
  playbook       = "scripts/semaphore-netbox-register.py"
  inventory_id   = semaphoreui_project_inventory.selfreg.id
  repository_id  = semaphoreui_project_repository.infra_cd.id
  environment_id = semaphoreui_project_environment.selfreg.id
}

resource "semaphoreui_project_integration" "selfreg" {
  project_id     = semaphoreui_project.proxmox_selfreg.id
  template_id    = semaphoreui_project_template.selfreg.id
  name           = "proxmox-selfreg-webhook"
  auth_method    = "hmac"
  auth_header    = "X-Selfreg-Signature"
  auth_secret_id = semaphoreui_project_key.webhook_secret.id
  searchable     = false # see file header: true breaks single-alias resolution
}

# integration_id is set (a dedicated URL per integration, not a
# project-wide shared one) -> resolution level is IntegrationAliasSingle ->
# matchers never evaluate for this alias. No matcher sync needed, only the
# extract-value sync below.
resource "semaphoreui_integration_alias" "selfreg" {
  project_id     = semaphoreui_project.proxmox_selfreg.id
  integration_id = semaphoreui_project_integration.selfreg.id
}

output "selfreg_webhook_url" {
  value       = semaphoreui_integration_alias.selfreg.url
  description = "POST target for the cloud-init additional_runcmd callback (docs/proxmox-modules-cloud-init-handoff-plan.md)."
}

# ---------------------------------------------------------------------------
# Escape hatch: IntegrationExtractValue mapping (maps the incoming webhook
# JSON body's {token, ip} fields into SELFREG_TOKEN/SELFREG_IP task env
# vars). No resource in semaphoreui/semaphore's provider (checked every
# tag v0.1.0 through the current 0.3.9) wraps
# POST/GET/PUT /project/{id}/integrations/{id}/values, even though the
# real Semaphore API has always supported it — confirmed against
# semaphoreui/semaphore's own api-docs.yml. A dedicated custom provider for
# two REST endpoints would be over-engineering; deferring this to a manual
# UI step would violate this repo's own no-config-drift convention.
# terraform_data + local-exec is the standard, documented Terraform escape
# hatch for exactly this situation.
#
# Idempotency: the helper script GETs the existing extract-values, matches
# by `variable` (the stable identity — `name` is just a display label),
# and PUTs (update) or POSTs (create) accordingly — never blindly POSTs,
# which would duplicate entries on every apply. triggers_replace includes
# a hash of both the desired mapping AND the helper script itself, so
# either changing (e.g. renaming SELFREG_TOKEN) or fixing the helper
# re-runs the sync; terraform_data's provisioner otherwise only fires on
# create. Known limitation, accepted: this doesn't detect out-of-band
# drift (someone manually deleting an extract-value via the Semaphore UI)
# on an otherwise-unchanged apply — only a full custom provider resource
# would close that gap, which isn't justified for two endpoints.
# ---------------------------------------------------------------------------

locals {
  selfreg_extract_values = [
    { name = "token", key = "token", variable = "SELFREG_TOKEN" },
    { name = "ip", key = "ip", variable = "SELFREG_IP" },
  ]
}

resource "terraform_data" "selfreg_extract_values" {
  triggers_replace = [
    semaphoreui_project_integration.selfreg.id,
    sha256(jsonencode(local.selfreg_extract_values)),
    filesha256("${path.module}/scripts/sync-integration-extract-values.sh"),
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      # See provider.tf's comment: .url doesn't resolve for this item, the
      # host lives in the "Config" section's "hostname" field instead —
      # and that stored value already includes its own "https://" scheme,
      # so no second one is prepended here either (same live bug
      # provider.tf hit).
      #
      # SEMAPHORE_API_TOKEN here is the same admin token provider.tf uses —
      # unlike the webhook secret above (password_wo, never persisted),
      # this value DOES land in Terraform state via this provisioner's
      # config, same as it already does via provider.tf's own api_token.
      # Not a new exposure, but don't assume password_wo's treatment
      # covers this credential too.
      SEMAPHORE_API_URL   = "${trimsuffix(data.onepassword_item.semaphore.section_map["Config"].field_map["hostname"].value, "/")}/api"
      SEMAPHORE_API_TOKEN = data.onepassword_item.semaphore.credential
      PROJECT_ID          = tostring(semaphoreui_project.proxmox_selfreg.id)
      INTEGRATION_ID      = tostring(semaphoreui_project_integration.selfreg.id)
      EXTRACT_VALUES_JSON = jsonencode(local.selfreg_extract_values)
    }
    command = "${path.module}/scripts/sync-integration-extract-values.sh"
  }
}
