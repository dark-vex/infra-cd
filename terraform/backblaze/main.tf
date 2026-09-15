# Mixed-case bucket name ("Nextcloud-Fastnetserv") is a non-issue here,
# confirmed from source: `resource_b2_bucket.go`'s `bucket_name` schema only
# validates `validation.NoZeroValues` (non-empty) - no AWS-style lowercase
# rule at all, since B2's native API allows mixed case.
#
# Real live values below (bucket_type, default_server_side_encryption)
# confirmed via a direct B2 API call (b2_list_buckets), not assumed - the
# app key stored in 1Password has read access to those fields but not to
# file_lock_configuration/replication_configuration (missing
# readBucketRetentions capability), so file_lock_configuration is
# deliberately left undeclared here rather than guessed; see the
# lifecycle.ignore_changes note below.
import {
  to = b2_bucket.nextcloud_fastnetserv
  id = "5e3c3b5f8dcc43807ce50718" # B2's own bucket ID, not the bucket name - this provider imports by ID
}

resource "b2_bucket" "nextcloud_fastnetserv" {
  bucket_name = "Nextcloud-Fastnetserv"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  lifecycle {
    # The 1Password-stored application key lacks readBucketRetentions
    # (confirmed via a real b2_authorize_account call), so this stack can't
    # verify the live file_lock_configuration value - ignore drift on it
    # rather than asserting a guessed value that could silently disable a
    # real setting on apply.
    ignore_changes = [file_lock_configuration]
  }
}
