# This credential's scope is unambiguous (named for exactly one bucket),
# but like terraform/aws/, this item does NOT exist yet in this vault -
# the same vault every existing Terraform stack in this repo actually
# reads from. A similarly-named item exists in a *different* vault
# ("Infrastructure") - that one isn't wired into this repo's
# Terraform/CI, don't assume it's reachable here.
#
# Needs a new item titled "Backblaze Nextcloud-Fastnetserv bucket" created
# in THIS vault with fields `username` (B2 application key ID),
# `credential` (application key), and `hostname` (bare endpoint host,
# e.g. s3.eu-central-003.backblazeb2.com per the live Velero config).
# Safe to copy the existing Infrastructure-vault key's value here since B2
# application keys are already bucket-scopable at creation.
data "onepassword_item" "nextcloud_fastnetserv" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Backblaze Nextcloud-Fastnetserv bucket"
}
