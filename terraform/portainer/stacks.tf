locals {
  stacks_repository_url = "https://github.com/dark-vex/infra-cd-docker"

  stacks = {
    "env-6/nut-exporter" = {
      env             = "env_6"
      stack_id        = 18
      path            = "portainer/dcknuc/nut-exporter/docker-compose.yml"
      repository_url  = "https://github.com/dark-vex/infra-cd"
      update_interval = "5m"
    }
    "env-8/ripe-atlas" = {
      env        = "env_8"
      source_id  = tonumber(portainer_gitops_source.compose.id)
      pull_image = true
    }
    "env-8/wg-easy" = {
      env        = "env_8"
      source_id  = tonumber(portainer_gitops_source.compose.id)
      pull_image = true
    }
    "env-6/ripe-probes" = {
      env        = "env_6"
      source_id  = tonumber(portainer_gitops_source.compose.id)
      pull_image = true
    }
    "env-8/bareos" = {
      env        = "env_8"
      source_id  = tonumber(portainer_gitops_source.compose.id)
      pull_image = true
      env_item   = "Portainer-Stack-env8-bareos"
    }
    "env-6/bareos" = {
      env        = "env_6"
      source_id  = tonumber(portainer_gitops_source.compose.id)
      pull_image = true
      env_item   = "Portainer-Stack-env6-bareos"
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
    }
    "env-7/acme-nas-certificate" = {
      env       = "env_7"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env7-acme-nas-certificate"
    }
    "env-6/n8n" = {
      env       = "env_6"
      source_id = tonumber(portainer_gitops_source.compose.id)
      env_item  = "Portainer-Stack-env6-n8n"
    }
  }

  stacks_to_import = { for k, v in local.stacks : k => v if try(v.stack_id, null) != null }

  stack_env_items = toset([for v in values(local.stacks) : v.env_item if try(v.env_item, null) != null])

  stack_env = {
    for k, v in local.stacks : k => merge([
      for s in data.onepassword_item.stack_env[v.env_item].section : { for f in s.field : f.label => f.value }
    ]...)
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

  dynamic "env" {
    for_each = toset(nonsensitive(keys(try(local.stack_env[each.key], {}))))
    content {
      name  = env.value
      value = local.stack_env[each.key][env.value]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
