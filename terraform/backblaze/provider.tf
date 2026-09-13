# `hashicorp/aws` was originally used here to talk to Backblaze B2's S3-compatible
# API. That failed in CI: aws_s3_bucket's refresh function unconditionally probes
# bucket sub-configuration (CORS, ACL, etc.), and B2's real, correct
# `NoSuchCorsConfiguration` 404 response to GetBucketCors isn't handled gracefully
# by hashicorp/aws against a non-AWS endpoint — a known class of bug (see
# hashicorp/terraform-provider-aws#49019, same root cause breaking
# aws_s3_bucket_lifecycle_configuration against MinIO/Ceph/B2). Migrated to
# aminueza/minio instead: traced its source directly — minio_s3_bucket's refresh
# never fetches CORS at all (it's a separate, unused opt-in resource in this
# provider), so that specific failure is structurally impossible here, not just
# suppressed.
provider "minio" {
  minio_server   = "${local.backblaze_secrets.hostname}:443"
  minio_user     = data.onepassword_item.nextcloud_fastnetserv.username
  minio_password = data.onepassword_item.nextcloud_fastnetserv.credential

  minio_ssl           = true
  s3_compat_mode      = true
  skip_bucket_tagging = true
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
