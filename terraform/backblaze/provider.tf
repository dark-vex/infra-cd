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
# ASSUMPTION TO VERIFY (this stack has NOT been terraform init/plan'd):
# the 1Password item's `hostname` field is assumed to hold the bare B2
# endpoint host, matching the live Velero config
# (s3.eu-central-003.backblazeb2.com) - confirm the field actually contains
# that before first apply, since this pass could only read field *labels*,
# not values, for this item.
provider "aws" {
  region = "us-east-1" # required by the provider schema; Backblaze ignores it

  access_key = data.onepassword_item.nextcloud_fastnetserv.username
  secret_key = data.onepassword_item.nextcloud_fastnetserv.credential

  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "https://${data.onepassword_item.nextcloud_fastnetserv.hostname}"
  }
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
