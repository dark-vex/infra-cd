# The `aws` provider is reused here to talk to Backblaze B2's S3-compatible
# API, the same pattern already live in clusters/kubenuc/apps/velero/manifests/
# release.yml (provider: aws, s3ForcePathStyle: "true",
# s3Url: https://s3.eu-central-003.backblazeb2.com). There is no dedicated
# Backblaze Terraform provider needed for a single bucket - this is the
# documented, supported way to point the aws provider at an S3-compatible
# endpoint (per terraform/CLAUDE.md's local-exec-escape-hatch section: reach
# for a custom/community provider only when the real API isn't already
# wrapped by something that fits - here it is).
#
provider "aws" {
  region = "us-east-1" # required by the provider schema; Backblaze ignores it

  access_key = data.onepassword_item.nextcloud_fastnetserv.username
  secret_key = data.onepassword_item.nextcloud_fastnetserv.credential

  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "https://${local.backblaze_secrets.hostname}"
  }
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
