# Imported from the live instance (staged adoption, see terraform/CLAUDE.md).
# client_secret is intentionally not declared: it is generated server-side and
# must not be committed; consumers keep the secret they already hold.

resource "authentik_provider_oauth2" "harbor" {
  client_id           = local.authentik_urls.harbor_client_id
  name                = "Harbor-provider"
  client_type         = "confidential"
  authentication_flow = data.authentik_flow.default_authentication.id
  authorization_flow  = data.authentik_flow.default_provider_authorization_explicit_consent.id
  invalidation_flow   = data.authentik_flow.default_provider_invalidation.id
  property_mappings   = local.oauth2_mappings_basic
  sub_mode            = "hashed_user_id"
  grant_types = [
    "authorization_code", "hybrid", "implicit", "client_credentials", "password",
    "urn:ietf:params:oauth:grant-type:device_code", "refresh_token",
  ]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  refresh_token_validity     = "days=30"
  refresh_token_threshold    = "seconds=0"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  logout_method              = "backchannel"
  allowed_redirect_uris = [
    for u in local.authentik_urls.harbor_redirect_uris : {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = u
    }
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_provider_oauth2" "netbird" {
  client_id           = local.authentik_urls.netbird_client_id
  name                = "Netbird-Provider"
  client_type         = "public"
  authentication_flow = data.authentik_flow.default_authentication.id
  authorization_flow  = data.authentik_flow.default_provider_authorization_explicit_consent.id
  invalidation_flow   = data.authentik_flow.default_provider_invalidation.id
  property_mappings   = local.oauth2_mappings_netbird
  sub_mode            = "user_id"
  grant_types = [
    "authorization_code", "hybrid", "implicit", "client_credentials", "password",
    "urn:ietf:params:oauth:grant-type:device_code", "refresh_token",
  ]
  access_code_validity       = "minutes=10"
  access_token_validity      = "minutes=5"
  refresh_token_validity     = "days=30"
  refresh_token_threshold    = "seconds=0"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  logout_method              = "backchannel"
  # Order matters: the last live entry is a regex match, the others strict.
  allowed_redirect_uris = [
    for i, u in local.authentik_urls.netbird_redirect_uris : {
      matching_mode     = i == 2 ? "regex" : "strict"
      redirect_uri_type = "authorization"
      url               = u
    }
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_provider_oauth2" "pangolin" {
  client_id          = local.authentik_urls.pangolin_client_id
  name               = "Provider for Pangolin"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_provider_authorization_explicit_consent.id
  invalidation_flow  = data.authentik_flow.default_provider_invalidation.id
  property_mappings  = local.oauth2_mappings_basic
  signing_key        = data.authentik_certificate_key_pair.self_signed.id
  sub_mode           = "hashed_user_id"
  # The live list contains every entry twice; mirrored as-is so the import is
  # a no-op (de-duplicating is a separate, deliberate change).
  grant_types = [
    "authorization_code", "implicit", "hybrid", "refresh_token", "client_credentials",
    "password", "urn:ietf:params:oauth:grant-type:device_code",
    "authorization_code", "implicit", "hybrid", "refresh_token", "client_credentials",
    "password", "urn:ietf:params:oauth:grant-type:device_code",
  ]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  refresh_token_validity     = "days=30"
  refresh_token_threshold    = "hours=1"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  logout_method              = "backchannel"
  allowed_redirect_uris = [
    for u in local.authentik_urls.pangolin_redirect_uris : {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = u
    }
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_provider_saml" "wiz" {
  name                            = "Wiz-Provider"
  authorization_flow              = data.authentik_flow.default_provider_authorization_explicit_consent.id
  invalidation_flow               = data.authentik_flow.default_provider_invalidation.id
  property_mappings               = local.saml_mappings_wiz
  acs_url                         = local.authentik_urls.wiz_acs_url
  issuer_override                 = "authentik"
  signing_kp                      = data.authentik_certificate_key_pair.self_signed.id
  sp_binding                      = "post"
  sls_binding                     = "redirect"
  logout_method                   = "frontchannel_iframe"
  digest_algorithm                = "http://www.w3.org/2001/04/xmlenc#sha256"
  signature_algorithm             = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  sign_assertion                  = true
  sign_response                   = false
  sign_logout_request             = false
  sign_logout_response            = false
  assertion_valid_not_before      = "minutes=-5"
  assertion_valid_not_on_or_after = "minutes=5"
  session_valid_not_on_or_after   = "minutes=86400"

  lifecycle {
    prevent_destroy = true
  }
}
