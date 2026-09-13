# Unlike terraform/aws/, this credential's scope is unambiguous: this item
# is named for exactly one bucket and lives in the same shared Infrastructure
# vault every other stack in this repo already reads from.
data "onepassword_item" "nextcloud_fastnetserv" {
  vault = "66qfxcmgwlhutunx6slav6fyve" # Infrastructure
  title = "Backblaze Nextcloud-Fastnetserv bucket"
}
