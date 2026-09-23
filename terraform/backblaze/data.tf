data "onepassword_item" "nextcloud_backup" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Backblaze Nextcloud-Fastnetserv bucket"
}

data "sops_file" "backblaze_secrets" {
  source_file = "secrets.sops.yaml"
}

locals {
  backblaze_secrets = yamldecode(data.sops_file.backblaze_secrets.raw)
}
