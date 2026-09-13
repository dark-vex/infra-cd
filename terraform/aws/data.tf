# OPEN QUESTION (CODE-20) - do not apply until a human resolves this:
# two 1Password items in the shared Infrastructure vault could plausibly be
# the automation credential for this stack, and their IAM permission scope
# relative to these 3 buckets is unconfirmed:
#   - "AWS backup-s3" - referenced below as the working assumption because
#     its name/vault placement look
#     purpose-built for backup-bucket automation, matching this stack's
#     job. NOT verified against IAM policy.
#   - "AWS-CLI" - looks like a general/interactive credential; unclear if
#     it's meant to be used for unattended Terraform runs at all.
# Confirm least-privilege scope (ideally: only s3:* on these 3 bucket ARNs)
# before this stack is ever applied against real state.
data "onepassword_item" "aws_credentials" {
  vault = "66qfxcmgwlhutunx6slav6fyve" # Infrastructure
  title = "AWS backup-s3"
}

data "sops_file" "aws_secrets" {
  source_file = "secrets.sops.yaml"
}

locals {
  aws_secrets = yamldecode(data.sops_file.aws_secrets.raw)
}
