# Tailscale API credentials stored in 1Password
# Required fields in the 1Password item:
#   credential — Tailscale API key (generated in admin console)
#   username   — Tailnet name (e.g. example@github or your tailnet domain)
data "onepassword_item" "tailscale_credentials" {
  vault = "infra"
  title = "Tailscale API Key"
}
