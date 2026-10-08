# Portainer's global settings singleton (id "1"). Adopted last and
# deliberately minimal: every attribute and nested block of
# portainer_settings is optional+computed, so leaving them unset keeps the
# live values in state and the apply sends nothing different from live.
# Nothing here pins authentication: oauth_settings, ldap_settings and
# internal_auth_settings are intentionally omitted until SSO is proven and
# the break-glass admin is verified (keep hide_internal_auth = false).
#
# Single-owner rule: this resource OR portainer_ldap_settings, never both.
# Do not add portainer_auth (logs in on every apply and stores a JWT in
# state), portainer_settings_default_registry, or the backup/S3 and licence
# resources - all are explicitly out of scope for this stack.
#
# Explicit values (session timeout, snapshot interval, ...) can be added in
# follow-up PRs one at a time, each reviewed against the plan.

import {
  to = portainer_settings.this
  id = "1"
}

resource "portainer_settings" "this" {
  lifecycle {
    prevent_destroy = true
  }
}
