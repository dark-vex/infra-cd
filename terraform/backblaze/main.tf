# OPEN RISK, MOSTLY VERIFIED: this bucket's real name is "Nextcloud-Fastnetserv"
# (mixed case), confirmed from the live Velero manifest. Backblaze B2 allows
# mixed-case bucket names. The `hashicorp/aws` provider historically validates
# bucket names against AWS's OWN naming rules (lowercase only) client-side,
# which is part of why this stack moved to `aminueza/minio` instead (see
# provider.tf). Traced directly in that provider's source
# (resource_minio_s3_bucket.go): the schema only enforces
# `StringLenBetween(0, 63)` on `bucket` - the lowercase-enforcing
# `validateS3BucketName()` function in that file is dead code, referenced only
# by its own unit test, never wired into Create/Update/the schema's
# ValidateFunc. Confirmed locally: `terraform init && terraform validate`
# passes clean against aminueza/minio v3.42.0 with this exact mixed-case name,
# so the provider schema does not reject it. What's still unverified: whether
# the underlying minio-go SDK enforces its own bucket-name validation before
# issuing requests - only a real `plan` against B2 settles that.
import {
  to = minio_s3_bucket.nextcloud_fastnetserv
  id = "Nextcloud-Fastnetserv"
}

resource "minio_s3_bucket" "nextcloud_fastnetserv" {
  bucket        = "Nextcloud-Fastnetserv"
  force_destroy = false
}
