locals {
  stacks_repository_url = "https://github.com/dark-vex/infra-cd-docker"

  stacks = {
    "env-6/nut-exporter" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-8/ripe-atlas" = {
      env       = "env_8"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-8/wg-easy" = {
      env       = "env_8"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-6/ripe-probes" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-8/bareos" = {
      env       = "env_8"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env8-bareos"
      env_vars = [
        "BAREOS_FD_PASSWORD",
        "BAREOS_SD_PASSWORD",
        "BAREOS_WEBUI_PASSWORD",
        "DB_ADMIN_PASSWORD",
        "DB_ADMIN_USER",
        "DB_PASSWORD",
        "S3_ACCESS_KEY_ID",
        "S3_SECRET_ACCESS_KEY",
        "SLACK_WEBHOOK_URL",
      ]
    }
    "env-6/bareos" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env6-bareos"
      env_vars = [
        "BAREOS_FD_PASSWORD",
        "BAREOS_SD_PASSWORD",
        "BAREOS_WEBUI_PASSWORD",
        "DB_ADMIN_PASSWORD",
        "DB_ADMIN_USER",
        "DB_PASSWORD",
        "S3_ACCESS_KEY_ID",
        "S3_SECRET_ACCESS_KEY",
        "SLACK_WEBHOOK_URL",
      ]
    }
    "env-6/netbootxyz" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-7/homeassistant" = {
      env       = "env_7"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-6/grafana-unifi" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env6-grafana-unifi"
      env_vars = [
        "SELFHOSTED_LOGS_HOST",
        "SELFHOSTED_METRICS_HOST",
        "password",
      ]
    }
    "env-6/network-monitoring" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
      active    = false
    }
    "env-7/minio" = {
      env       = "env_7"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env7-minio"
      env_vars = [
        "MINIO_ROOT_PASSWORD",
        "MINIO_ROOT_USER",
      ]
    }
    "env-7/seaweedfs" = {
      env       = "env_7"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env7-seaweedfs"
      env_vars = [
        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY",
        "SEAWEEDFS_ADMIN_PASSWORD",
      ]
    }
    "env-7/acme-nas-certificate" = {
      env       = "env_7"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env7-acme-nas-certificate"
      env_vars = [
        "CF_Email",
        "CF_Token",
        "SYNO_CERTIFICATE",
        "SYNO_HOSTNAME_FQDN",
        "SYNO_HOSTNAME_IP",
        "SYNO_PASSWORD",
        "SYNO_USERNAME",
      ]
    }
    "env-6/n8n" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env6-n8n"
      env_vars = [
        "POSTGRES_DB",
        "POSTGRES_NON_ROOT_PASSWORD",
        "POSTGRES_NON_ROOT_USER",
        "POSTGRES_PASSWORD",
        "POSTGRES_USER",
      ]
    }
    "env-7/downloads" = {
      env       = "env_7"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
    "env-6/wg-easy" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
    }
  }

  stacks_to_import = { for k, v in local.stacks : k => v if try(v.stack_id, null) != null }

  stack_env_items = toset([for v in values(local.stacks) : v.env_item if try(v.env_item, null) != null])

  # Every field of every section of the stack's 1Password item (values stay
  # sensitive). Only the names a catalog entry lists in env_vars are exported
  # to the stack (see the env block on portainer_stack.this).
  stack_env = {
    for k, v in local.stacks : k => merge([
      for s in data.onepassword_item.stack_env[v.env_item].section : { for f in s.field : f.label => f.value }
    ]...)
    if try(v.env_item, null) != null
  }

  # Field labels only (names, never values): labels are not secret.
  stack_env_labels = nonsensitive({ for k, f in local.stack_env : k => toset(keys(f)) })

  # Declared names that the 1Password item does not have, per stack.
  stack_env_missing = {
    for k, v in local.stacks : k => sort(setsubtract(toset(try(v.env_vars, [])), local.stack_env_labels[k]))
    if try(v.env_item, null) != null
  }
}

data "onepassword_item" "stack_env" {
  for_each = local.stack_env_items

  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = each.value
}

import {
  for_each = local.stacks_to_import
  to       = portainer_stack.this[each.key]
  id       = "${local.environments[each.value.env].id}-${each.value.stack_id}-standalone-repository"
}

resource "portainer_stack" "this" {
  for_each = local.stacks

  name            = element(split("/", each.key), 1)
  deployment_type = "standalone"
  method          = "repository"
  endpoint_id     = tonumber(portainer_environment.this[each.value.env].id)

  repository_url            = try(each.value.repository_url, local.stacks_repository_url)
  repository_reference_name = "refs/heads/main"
  file_path_in_repository   = try(each.value.path, "stacks/${local.portainer_values.environments[each.value.env].name}/${element(split("/", each.key), 1)}/compose.yaml")

  source_id                     = try(each.value.source_id, null)
  git_repository_authentication = try(each.value.source_id, null) != null

  active          = try(each.value.active, true)
  stack_webhook   = false
  update_interval = try(each.value.update_interval, "30m")
  pull_image      = try(each.value.pull_image, false)
  force_update    = try(each.value.prune, false)

  # Only the names declared in env_vars are exported; extra fields in the
  # 1Password item are ignored. A declared name missing from the item fails the
  # plan (preconditions below), so the env can never shrink silently by a typo.
  dynamic "env" {
    for_each = setintersection(toset(try(each.value.env_vars, [])), try(local.stack_env_labels[each.key], toset([])))
    content {
      name  = env.value
      value = local.stack_env[each.key][env.value]
    }
  }

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = (try(each.value.env_item, null) != null) == (try(each.value.env_vars, null) != null)
      error_message = "stack_env allowlist: env_item and env_vars must be set together on a catalog entry."
    }

    precondition {
      condition     = alltrue([for n in try(each.value.env_vars, []) : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", n))])
      error_message = "stack_env allowlist: env_vars entries must be plain variable names."
    }

    precondition {
      condition     = length(lookup(local.stack_env_missing, each.key, [])) == 0
      error_message = "stack_env allowlist: ${each.key} declares env_vars missing from its 1Password item: ${join(", ", lookup(local.stack_env_missing, each.key, []))}"
    }
  }
}
