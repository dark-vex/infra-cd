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
