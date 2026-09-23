provider "b2" {
  application_key    = data.onepassword_item.nextcloud_backup.credential
  application_key_id = data.onepassword_item.nextcloud_backup.username
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
