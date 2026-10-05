# Staged adoption plan (see terraform/CLAUDE.md "Both" secrets-provider
# entry): one resource at a time, each as its own PR with a verified
# zero-diff `terraform plan` after its `import {}` block is applied.
# Adoption order: one noncritical auth0_client (#2108, landed) -> one
# audited auth0_connection (#2109, landed) -> auth0_connection_clients
# (this PR) -> remaining clients/connections/resource servers/actions ->
# auth0_tenant + auth0_trigger_actions last. auth0_client_credentials and
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
    infinite_idle_token_lifetime = false
    infinite_token_lifetime      = false
    leeway                       = 0
    rotation_type                = "non-rotating"
    # idle_token_lifetime/token_lifetime deliberately omitted: both are
    # live-reported as 0 (inert when expiration_type is non-expiring), but
    # the provider's plan-time CustomizeDiff (auth0/terraform-provider-auth0
    # v1.58.1+) rejects idle_token_lifetime >= token_lifetime unconditionally
    # whenever both appear in config, with no exception for non-expiring -
    # 0 >= 0 always fails it. Both are Optional+Computed, so omitting them
    # avoids the check entirely without creating a diff against live state.
  }
}

# PR #2: the tenant's one database connection. Zero FQDN-bearing fields
# (every URL-shaped option is null) - no SOPS routing needed here either.
# options_client_secret_wo is null because this is a database connection,
# not a social/enterprise one with an upstream secret to backfill.
#
# Deliberately NOT bundling auth0_connection_clients in this PR - per the
# plan, that resource is authoritative for the connection's entire
# enabled-client set, and omitting a production client there silently
# revokes its login access. It gets its own PR with its own review.
import {
  id = "con_cACfRKfNmeVChBlu"
  to = auth0_connection.username_password_authentication
}

resource "auth0_connection" "username_password_authentication" {
  is_domain_connection             = false
  metadata                         = {}
  name                             = "Username-Password-Authentication"
  options_client_secret_wo         = null
  options_client_secret_wo_version = null
  realms                           = ["Username-Password-Authentication"]
  show_as_button                   = null
  strategy                         = "auth0"

  authentication {
    active = true
  }

  connected_accounts {
    active = false
  }

  options {
    access_token_url                       = null
    adfs_server                            = null
    allowed_audiences                      = []
    api_enable_groups                      = false
    api_enable_users                       = false
    app_id                                 = null
    auth_params                            = {}
    brute_force_protection                 = true
    client_id                              = null
    client_secret                          = null
    community_base_url                     = null
    configuration                          = null
    consumer_key                           = null
    consumer_secret                        = null
    custom_scripts                         = {}
    debug                                  = false
    destination_url                        = null
    digest_algorithm                       = null
    disable_cache                          = false
    disable_self_service_change_password   = false
    disable_sign_out                       = false
    disable_signup                         = false
    discovery_url                          = null
    domain                                 = null
    domain_aliases                         = []
    dpop_signing_alg                       = null
    email                                  = false
    enable_script_context                  = false
    enabled_database_customization         = false
    entity_id                              = null
    fed_metadata_xml                       = null
    fields_map                             = null
    forward_request_info                   = false
    from                                   = null
    gateway_url                            = null
    global_token_revocation_jwt_iss        = null
    global_token_revocation_jwt_sub        = null
    icon_url                               = null
    id_token_session_expiry_supported      = false
    id_token_signed_response_algs          = []
    identity_api                           = null
    import_mode                            = false
    ips                                    = []
    key_id                                 = null
    map_user_id_to_id                      = false
    max_groups_to_retrieve                 = null
    messaging_service_sid                  = null
    metadata_url                           = null
    metadata_xml                           = null
    name                                   = null
    non_persistent_attrs                   = []
    password_policy                        = "good"
    ping_federate_base_url                 = null
    pkce_enabled                           = false
    precedence                             = []
    protocol_binding                       = null
    provider                               = null
    realm_fallback                         = false
    recipient_url                          = null
    request_template                       = null
    request_token_url                      = null
    requires_username                      = false
    scopes                                 = []
    scripts                                = {}
    send_back_channel_nonce                = false
    session_key                            = null
    should_trust_email_verified_connection = null
    sign_saml_request                      = false
    signature_algorithm                    = null
    signature_method                       = null
    strategy_version                       = 2
    subject                                = null
    syntax                                 = null
    team_id                                = null
    template                               = null
    tenant_domain                          = null
    token_endpoint_auth_method             = null
    token_endpoint_auth_signing_alg        = null
    token_endpoint_jwtca_aud_format        = null
    twilio_sid                             = null
    twilio_token                           = null
    upstream_params                        = null
    use_cert_auth                          = false
    use_kerberos                           = false
    use_oauth_spec_scope                   = false
    use_wsfed                              = false
    user_authorization_url                 = null
    user_id_attribute                      = null
    waad_common_endpoint                   = false
    waad_protocol                          = null

    mfa {
      active                 = true
      return_enroll_settings = true
    }
  }
}

# PR #3: the enabled-client set for the one database connection. This
# resource is authoritative for the entire list - omitting a client here
# silently revokes its login access via this connection. Cross-checked
# the generated list against a direct Management API call independent of
# Terraform (GET connections/<id>/clients) before trusting it: both agree
# on the same 7 client IDs, which is every client in the tenant (including
# terraform_m2m - harmless here, this list only controls which apps can
# offer this connection as a login option, not what terraform_m2m's own
# client_credentials grant does).
import {
  id = "con_cACfRKfNmeVChBlu"
  to = auth0_connection_clients.username_password_authentication
}

resource "auth0_connection_clients" "username_password_authentication" {
  connection_id = auth0_connection.username_password_authentication.id
  enabled_clients = [
    auth0_client.default_app.client_id,
    "OerKxEvVuBjkDxN0RYxYm4bJQXgQT7gQ", # cloudflare_zero - not yet adopted
    "Sey67NbQ51IL1G5luRr22kVSm31UBDDR", # sysdig - not yet adopted
    "d1ByxDggtxic266rnC6E8eR4FUIl5Eo5", # netbird - not yet adopted
    "iDav21a9ZKFUmSoO1f2zykIoT63NrvCJ", # terraform_m2m - permanently out of scope
    "jnfZFacjDpQjs22dFXIP7wbAdIlwGM6b", # proxmox - not yet adopted
    "qpVGSraZse0OXPzMT0Xp8YuT5yo9YVRI", # pangolin - not yet adopted
  ]
}
