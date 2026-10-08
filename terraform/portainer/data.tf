# 1Password item for Terraform's own Portainer service user (bootstrap auth
# only - non-secret URLs/FQDNs for managed objects live in secrets.sops.yaml).
#
# Expected item shape (vault 66qfxcmgwlhutunx6slav6fyve, k8s_secrets - verify
# the vault ID, not just the name):
#   - url                        = Portainer base URL (https, no redirects)
#   - section field "api_key"    = Portainer API access token of the dedicated
#                                  Terraform service user
#   - section field "cf_access_client_id" / "cf_access_client_secret"
#                                = Cloudflare Access service token, sent via
#                                  the provider's custom_headers
data "onepassword_item" "portainer" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Portainer-Terraform"
}

data "sops_file" "portainer" {
  source_file = "secrets.sops.yaml"
}

locals {
  portainer_url = trimsuffix(data.onepassword_item.portainer.url, "/")

  # Custom fields live in sections; flatten to label => value.
  portainer_fields = merge([
    for s in data.onepassword_item.portainer.section : {
      for f in s.field : f.label => f.value
    }
  ]...)

  portainer_values = yamldecode(data.sops_file.portainer.raw)
}
