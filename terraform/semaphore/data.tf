data "onepassword_item" "semaphore" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "43o3n6g5kkgxtgiof3xbeo4lgu"
}

# Dedicated webhook front-door secret (Design §3's HMAC gate on
# semaphoreui_project_integration) — deliberately a separate item from
# `semaphore` above, never the Semaphore admin API token. Same vault.
data "onepassword_item" "selfreg_webhook_secret" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "gdbvp6yfyzouv5hmf7mbamvrky"
}

# Reused, not new — this is the same item the NetBox MCP server and
# graylog-cert-renewal's netbox.yml inventory already source
# NETBOX_URL/NETBOX_TOKEN from (see the repo root README's "Claude Code
# MCP Setup" section). A LOGIN-category item, so .url resolves via its
# native urls[] field (unlike the semaphore item above, which is
# API_CREDENTIAL and needed the section_map workaround).
data "onepassword_item" "netbox" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "q7b4mjw54keaujuqyqezw7dv7i"
}

# The consolidated "SOPS Keys" note this repo already uses for every
# stack's age private key — confirmed live: age-netbox.agekey is a FILE
# attachment (not a field), in the item's single unlabeled section (empty
# string key), reachable via section_map[""].file_map["<name>"].content.
# No new 1Password item needed; SOPS_AGE_KEY_NETBOX was previously only a
# GitHub Actions secret with no 1Password-side source of truth.
data "onepassword_item" "sops_keys" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "wn3mf5oo36ys35v423ye7caipy"
}
