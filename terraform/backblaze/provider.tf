# Second migration for this stack. First used `hashicorp/aws` pointed at B2's
# S3-compatible endpoint, then `aminueza/minio` (see git history) - both
# S3-compatibility-shim providers, both hit real bugs specific to going
# through that shim (a CORS-response case-mismatch in aws_s3_bucket, an
# unconditionally-fatal GetBucketPolicy call on import in minio_s3_bucket,
# since B2 doesn't implement bucket policies at all). Neither bug was
# B2-specific in the sense of "B2 is broken" - both were the shim providers
# assuming AWS/MinIO response shapes B2 doesn't match.
#
# Backblaze/b2 is the official Backblaze-published provider. It talks to B2's
# own native API via the embedded B2 Python SDK, not an S3-compatible shim -
# so neither prior bug class applies structurally: cors_rules is a native
# inline attribute on b2_bucket (no separate probed sub-resource), and B2's
# native access-control model has no bucket-policy concept at all (it's
# bucket_type + application-key scoping instead), so there's nothing
# analogous to fail on import.
provider "b2" {
  application_key    = data.onepassword_item.nextcloud_fastnetserv.credential
  application_key_id = data.onepassword_item.nextcloud_fastnetserv.username
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
