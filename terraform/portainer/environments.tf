# Docker agent environments, adopted separately from tags/groups (main.tf)
# because of the provider's import read gap. Names/addresses are FQDN-bearing
# and live in secrets.sops.yaml. The built-in "Unassigned" group (id 1) is
# referenced by literal id.

# --------------------------------------------------------- environments
# Docker agent environments (type 2). Never recreate: a destroy removes the
# environment's access policies and stack bindings in Portainer.

locals {
  environments = {
    env_6 = { id = "6", group_id = portainer_endpoint_group.fastnetserv.id }
    env_7 = { id = "7", group_id = portainer_endpoint_group.fastnetserv.id }
    env_8 = { id = "8", group_id = portainer_endpoint_group.bioadventures.id }
    env_9 = { id = "9", group_id = 1 } # built-in "Unassigned"
  }
}

import {
  for_each = local.environments
  to       = portainer_environment.this[each.key]
  id       = each.value.id
}

resource "portainer_environment" "this" {
  for_each = local.environments

  name                = local.portainer_values.environments[each.key].name
  environment_address = local.portainer_values.environments[each.key].address
  public_ip           = try(local.portainer_values.environments[each.key].public_ip, null)
  group_id            = each.value.group_id
  type                = 2

  # The provider does not read tls_* on import and defaults all three to
  # true, so the first apply writes them to the live agents even when unset.
  # They are declared explicitly so that write is visible: tls_enabled and
  # tls_skip_verify match live; tls_skip_client_verify is unset live (moot,
  # no client certificate is configured).
  tls_enabled            = true
  tls_skip_verify        = true
  tls_skip_client_verify = true

  lifecycle {
    prevent_destroy = true
  }
}
