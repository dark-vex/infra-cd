# OPEN RISK, UNVERIFIED (this stack has NOT been terraform init/plan'd):
# this bucket's real name is "Nextcloud-Fastnetserv" (mixed case), confirmed
# from the live Velero manifest. Backblaze B2 allows mixed-case bucket
# names, but the upstream `aws_s3_bucket` resource schema historically
# validates bucket names against AWS's OWN naming rules (lowercase only)
# client-side, before any request reaches the API. If that validation is
# still enforced in the pinned provider version, `terraform validate`/
# `plan` will reject this resource outright even though the name is valid
# on the real B2 endpoint. This needs to be verified with a real
# `terraform init && terraform validate` before this stack is trusted - if
# it fails, alternatives are: a Backblaze-native provider, or the
# local-exec/terraform_data escape hatch from terraform/CLAUDE.md.
import {
  to = aws_s3_bucket.nextcloud_fastnetserv
  id = "Nextcloud-Fastnetserv"
}

resource "aws_s3_bucket" "nextcloud_fastnetserv" {
  bucket = "Nextcloud-Fastnetserv"
}
