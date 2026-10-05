# 1Password item for Terraform's own Auth0 M2M application (bootstrap auth
# only - see terraform/CLAUDE.md's "Secrets provider by stack" entry for why
# this stack also needs SOPS for every FQDN-bearing resource attribute).
#
# Expected item shape (vault 66qfxcmgwlhutunx6slav6fyve, same vault every
# other Terraform-consumed 1Password item lives in):
#   - url      = Auth0 domain, e.g. "your-tenant.eu.auth0.com" (bare host -
#                the auth0 provider's `domain` argument rejects a scheme;
#                trimprefix below guards against someone pasting a full URL)
#   - username = M2M application's Client ID
#   - password = M2M application's Client Secret
data "onepassword_item" "auth0" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Auth0 Terraform M2M"
}

data "sops_file" "auth0" {
  source_file = "secrets.sops.yaml"
}

locals {
  auth0_domain = trimprefix(trimsuffix(data.onepassword_item.auth0.url, "/"), "https://")
  auth0_urls   = yamldecode(data.sops_file.auth0.raw)
}
