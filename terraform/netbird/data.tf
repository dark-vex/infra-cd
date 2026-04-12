# Netbird API credentials stored in 1Password
# Required fields in the 1Password item:
#   credential — Netbird personal access token or service account token
data "onepassword_item" "netbird_credentials" {
  vault = "infra"
  title = "Netbird API Token"
}
