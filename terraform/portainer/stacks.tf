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
  }

  stacks_to_import = { for k, v in local.stacks : k => v if try(v.stack_id, null) != null }
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

  stack_webhook   = false
  update_interval = try(each.value.update_interval, "30m")
  pull_image      = try(each.value.pull_image, false)
  force_update    = try(each.value.prune, false)

  lifecycle {
    prevent_destroy = true
  }
}
