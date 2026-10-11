# 1Password item for Terraform's own Authentik API identity (bootstrap auth
# only). The service account, its role/group and this token are deliberately
# NOT managed by Terraform, so an RBAC apply can never revoke its own access.
#
# Expected item shape (vault 66qfxcmgwlhutunx6slav6fyve, same vault every
# other Terraform-consumed 1Password item lives in):
#   - url      = Authentik base URL (trimsuffix below guards a trailing slash)
#   - password = API token of the dedicated service account
data "onepassword_item" "authentik" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Authentik Terraform"
}

# FQDN-bearing provider attributes (OAuth2 redirect URIs, SAML ACS URL) - see
# terraform/CLAUDE.md's "Secrets provider by stack" entry for this stack.
data "sops_file" "authentik" {
  source_file = "secrets.sops.yaml"
}

locals {
  authentik_url  = trimsuffix(data.onepassword_item.authentik.url, "/")
  authentik_urls = yamldecode(data.sops_file.authentik.raw)
}
