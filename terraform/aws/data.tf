# OPEN ITEM (CODE-20) - do not apply until this exists: this item does NOT
# exist yet in this vault - the same vault every existing Terraform stack
# in this repo actually reads from, confirmed against
# terraform/hetzner/main.tf and terraform/proxmox/gozzi-hpelvisor/data.tf,
# both of which use this exact vault ID. A similarly-named item exists in
# a *different* vault ("Infrastructure") but that vault isn't what this
# repo's Terraform/CI is wired to read from - don't assume that one is
# reachable here.
#
# Needs a new item titled "AWS backup-s3" created in THIS vault with
# fields `username` (AWS access key ID) and `credential` (secret access
# key), ideally a fresh least-privilege IAM key scoped to only s3:* on
# these 3 bucket ARNs rather than copying the Infrastructure-vault item's
# key sight-unseen (its IAM policy was never confirmed).
data "onepassword_item" "aws_credentials" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "AWS backup-s3"
}

data "sops_file" "aws_secrets" {
  source_file = "secrets.sops.yaml"
}

locals {
  aws_secrets = yamldecode(data.sops_file.aws_secrets.raw)
}
