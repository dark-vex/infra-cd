# Staged adoption plan (see terraform/CLAUDE.md "Both" secrets-provider
# entry): one resource at a time, each as its own PR with a verified
# zero-diff `terraform plan` after its `import {}` block is applied.
# Adoption order: one noncritical auth0_client (this PR) -> one audited
# auth0_connection -> auth0_connection_clients -> remaining
# clients/connections/resource servers/actions -> auth0_tenant +
# auth0_trigger_actions last. auth0_client_credentials and
# auth0_client.terraform_m2m (the client Terraform itself authenticates as)
# are deliberately out of scope - see terraform/CLAUDE.md and the plan doc.

# PR #1: Auth0's auto-created default application. Zero FQDN-bearing fields
# live on this client (every callback/origin/logout-URL list is empty,
# initiate_login_uri is null) - confirmed via `auth0 tf generate` discovery
# output, so no SOPS routing is needed for this specific resource.
import {
  id = "zUw2fEmbgzhrKg0nLLdiHHBjPGx6tJPp"
  to = auth0_client.default_app
}

resource "auth0_client" "default_app" {
  name                                                 = "Default App"
  app_type                                             = null
  is_first_party                                       = true
  oidc_conformant                                      = true
  cross_origin_auth                                    = true
  cross_origin_loc                                     = null
  custom_login_page                                    = null
  custom_login_page_on                                 = true
  description                                          = null
  encryption_key                                       = null
  form_template                                        = null
  logo_uri                                             = null
  resource_server_identifier                           = null
  compliance_level                                     = null
  initiate_login_uri                                   = null
  is_token_endpoint_ip_header_trusted                  = false
  require_proof_of_possession                          = false
  require_pushed_authorization_requests                = false
  sso                                                  = false
  sso_disabled                                         = false
  skip_non_verifiable_callback_uri_confirmation_prompt = jsonencode(null)
  grant_types                                          = ["authorization_code", "implicit", "refresh_token", "client_credentials"]
  allowed_clients                                      = []
  allowed_logout_urls                                  = []
  allowed_origins                                      = []
  async_approval_notification_channels                 = []
  callbacks                                            = []
  client_aliases                                       = []
  client_metadata                                      = {}
  organization_discovery_methods                       = []
  web_origins                                          = []

  default_organization {
    disable = true
    flows   = []
  }

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = 36000
    scopes              = {}
    secret_encoded      = false
  }

  refresh_token {
    expiration_type              = "non-expiring"
    idle_token_lifetime          = 0
    infinite_idle_token_lifetime = false
    infinite_token_lifetime      = false
    leeway                       = 0
    rotation_type                = "non-rotating"
    token_lifetime               = 0
  }
}
