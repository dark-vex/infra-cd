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

# The dedicated Semaphore GitHub App's credentials (Design §4/§5 step 5) —
# a separate installation from the existing Renovate App, kept
# purpose-built rather than reused (see scripts/semaphore-netbox-
# register.py's docstring). app-id/installation-id/private-key live in a
# named "GitHub App" section, confirmed live via section_map (a bare
# field, as with the semaphore item's hostname, isn't reachable).
data "onepassword_item" "semaphore_github_app" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "dgupwizpl3lfzd2esxbfrkoyvq"
}

# HCP Terraform credential for the registration script's `terraform output
# -json registration_manifest` calls (Design §1/§4/§5 step 1).
#
# ACCEPTED DEVIATION FROM THE ORIGINAL DESIGN, not an oversight: Design §4
# specified a token scoped to the "Read outputs only" workspace permission
# (narrower than full state read, since terraform/proxmox/* state also
# holds Proxmox root credentials). That permission is only assignable via
# custom Teams, which requires HCP Terraform's Standard tier
# (confirmed live: this org's Settings -> Teams page shows only the
# default "owners" team with no way to create another — a Free-tier
# limitation, not a bug or a permissions issue on this account). Rather
# than upgrading the org's billing tier for this one narrow credential,
# a dedicated bot HCP Terraform user (isolated from any individual's own
# login, invited to the org under Free tier's unlimited-users allowance)
# was created and this is its user API token. Its actual access is
# whatever this org's default (non-team-scoped) membership grants on
# Free tier — almost certainly full read on every workspace's state, not
# just registration_manifest's output. This is a real, accepted security
# tradeoff, not the original design's intent; revisit if this org ever
# moves to Standard tier or above.
data "onepassword_item" "semaphore_tfc_token" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "bhqt7trhp7vftdabmrihvmdnpq"
}
