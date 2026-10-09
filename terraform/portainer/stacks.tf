# GitOps stack catalog: Docker Compose stacks that Portainer pulls from the
# private infra-cd-docker repository (stacks/env-<id>/<stack>/compose.yaml).
# Terraform declares only the pointer (repo, path, poll interval); a compose
# edit needs no apply, Portainer redeploys it on its next poll. The catalog is
# empty on purpose in the scaffold PR so the plan shows no change; stacks are
# added one PR at a time (pilot first), each reviewed against the plan.
#
# Rules that come from the provider (portainer/portainer >= 2.0, < 3.0):
# - Create() adopts an existing stack with the same name on the same
#   environment and converts it in place, so "stop the old stack, then apply"
#   does NOT recreate anything. To get a real recreate, delete the old stack in
#   Portainer first. Importing works too: with provider v2.0.1 an import of a
#   git-backed stack read back the URL, path, reference and interval and planned
#   "1 to import, 0 to change, 0 to destroy" (import id
#   "<environment id>-<stack id>-standalone-repository").
# - name, endpoint_id, repository_url, tlsskip_verify, deployment_type, method
#   and support_relative_path are ForceNew. file_path_in_repository is not
#   ForceNew, but the provider's git-update call does not send it, so a path
#   change shows no effect and perpetual drift: treat a path change as a
#   replace, which prevent_destroy blocks on purpose (move the stack by hand).
# - for_each keys are the resource identity. Renaming a key destroys and
#   recreates the stack unless a moved {} block is added in the same PR.
# - Portainer 2.43+ replaced shared git credentials with "Sources": reference
#   one by source_id. Do not use the repository_*_wo write-only fields (their
#   version field is ForceNew) or inline repository_password (it lands in
#   state).
# - Polling can be silently inactive on 2.45 (the provider writes the legacy
#   AutoUpdate interval while the scheduler reads the Source's). After the pilot
#   apply, check that the Source has an interval and its last_sync advances.
# - Stack env values are read back in plaintext and stored in state. Credentials
#   come from 1Password, never from this file or from compose.

locals {
  stacks_repository_url = "https://github.com/dark-vex/infra-cd-docker"

  # Catalog: map key = "<env-alias>/<stack>" (matches stacks/<env-alias>/<stack>).
  #   env           key of local.environments (environments.tf)
  #   path          compose file path inside the repository
  #   source_id     Portainer Source (git credentials) id, on 2.43+
  #   pull_image    re-pull images on every redeploy (default false)
  #   prune         remove services no longer in the compose file (default false)
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

  # Polling only: a webhook would need a Cloudflare Access bypass.
  stack_webhook   = false
  update_interval = "5m"
  pull_image      = try(each.value.pull_image, false)
  force_update    = try(each.value.prune, false)

  lifecycle {
    prevent_destroy = true
  }
}
