# Reference-only lookups for objects owned by image-bundled default blueprints.
# Blueprints re-apply on a schedule, so these are never imported - resources
# below just point at them by slug / managed ID instead of a hardcoded UUID.

data "authentik_flow" "default_authentication" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "default_provider_authorization_explicit_consent" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default_provider_invalidation" {
  slug = "default-provider-invalidation-flow"
}

# Looked up one by one (not via managed_list) because provider.property_mappings
# is an ordered list and the bulk lookup's order does not match the live one.
data "authentik_property_mapping_provider_scope" "oauth2" {
  for_each = toset(["authentik_api", "email", "offline_access", "openid", "profile"])
  managed  = "goauthentik.io/providers/oauth2/scope-${each.key}"
}

data "authentik_property_mapping_provider_saml" "saml" {
  for_each = toset(["email", "groups", "ms-windowsaccountname", "name", "uid", "upn", "username"])
  managed  = "goauthentik.io/providers/saml/${each.key}"
}

locals {
  # Orders mirror the live objects so the post-import plan is empty.
  oauth2_mappings_basic = [for k in ["profile", "openid", "email"] : data.authentik_property_mapping_provider_scope.oauth2[k].id]
  oauth2_mappings_netbird = [
    for k in ["authentik_api", "profile", "offline_access", "openid", "email"] :
    data.authentik_property_mapping_provider_scope.oauth2[k].id
  ]
  saml_mappings_wiz = [
    for k in ["upn", "name", "email", "username", "uid", "groups", "ms-windowsaccountname"] :
    data.authentik_property_mapping_provider_saml.saml[k].id
  ]
}

# fetch_key / fetch_certificate stay false: the private key must never enter
# Terraform state. Only the ID is needed to reference the pair.
data "authentik_certificate_key_pair" "self_signed" {
  name              = "authentik Self-signed Certificate"
  fetch_key         = false
  fetch_certificate = false
}
