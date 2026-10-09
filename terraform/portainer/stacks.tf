locals {
  stacks_repository_url = "https://github.com/dark-vex/infra-cd-docker"

  stacks = {}
}

resource "portainer_stack" "this" {
  for_each = local.stacks

  name            = element(split("/", each.key), 1)
  deployment_type = "standalone"
  method          = "repository"
  endpoint_id     = tonumber(portainer_environment.this[each.value.env].id)

  repository_url            = local.stacks_repository_url
  repository_reference_name = "refs/heads/main"
  file_path_in_repository   = each.value.path

  source_id                     = each.value.source_id
  git_repository_authentication = true

  stack_webhook   = false
  update_interval = "5m"
  pull_image      = try(each.value.pull_image, false)
  force_update    = try(each.value.prune, false)

  lifecycle {
    prevent_destroy = true
  }
}
