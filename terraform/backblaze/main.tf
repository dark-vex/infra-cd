import {
  to = b2_bucket.nextcloud_backup
  id = "5e3c3b5f8dcc43807ce50718"
}

resource "b2_bucket" "nextcloud_backup" {
  bucket_name = local.backblaze_secrets.buckets.nextcloud_backup
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  lifecycle {
    ignore_changes = [file_lock_configuration]
  }
}
