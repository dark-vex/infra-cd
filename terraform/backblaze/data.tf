# This credential's scope is unambiguous (named for exactly one bucket).
# Item now exists (created by repo owner, 2026-09-13).
data "onepassword_item" "nextcloud_fastnetserv" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Backblaze Nextcloud-Fastnetserv bucket"
}

# The endpoint hostname is sourced from SOPS rather than the 1Password
# item's own `hostname` field: that field was created as 1Password's URL
# field type, and the onepassword Terraform provider's `.hostname`
# attribute only maps from the native STRING-typed field for this
# category - a URL-typed field resolves to null at plan time even though
# it's visibly filled in (confirmed via live CI failure, 2026-09-13:
# "data.onepassword_item.nextcloud_fastnetserv.hostname is null"). Rather
# than fight that field-type mismatch, the hostname is stored here
# instead - which also matches this repo's own stated convention of using
# SOPS for hostnames/non-credential values, same pattern as
# terraform/aws/'s bucket name.
data "sops_file" "backblaze_secrets" {
  source_file = "secrets.sops.yaml"
}

locals {
  backblaze_secrets = yamldecode(data.sops_file.backblaze_secrets.raw)
}
