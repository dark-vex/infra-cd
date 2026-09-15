# Item exists in this vault - the same vault every existing Terraform stack
# in this repo actually reads from, confirmed against
# terraform/hetzner/main.tf and terraform/proxmox/gozzi-hpelvisor/data.tf,
# both of which use this exact vault ID. A similarly-named item exists in
# a *different* vault ("Infrastructure") but that vault isn't what this
# repo's Terraform/CI is wired to read from - don't assume that one is
# reachable here.
#
# 2026-09-15: rotated to a fresh least-privilege key, scoped to exactly the
# read-only S3 actions aws_s3_bucket's Read function (+ its tagging
# interceptor) needs on these 3 bucket ARNs - see the policy in git history
# / PR discussion for the full action list, traced from
# hashicorp/terraform-provider-aws v5.100.0 source rather than assumed.
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
