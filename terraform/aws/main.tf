import {
  to = aws_s3_bucket.cloudtrail_logs
  id = local.aws_secrets.buckets.cloudtrail_logs
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.aws_secrets.buckets.cloudtrail_logs
}

import {
  to = aws_s3_bucket.mysql_backups
  id = local.aws_secrets.buckets.mysql_backups
}

resource "aws_s3_bucket" "mysql_backups" {
  bucket = local.aws_secrets.buckets.mysql_backups
}

import {
  to = aws_s3_bucket.pgbackup_kubenuc
  id = local.aws_secrets.buckets.pgbackup_kubenuc
}

import {
  to = aws_s3_bucket_versioning.pgbackup_kubenuc
  id = local.aws_secrets.buckets.pgbackup_kubenuc
}

resource "aws_s3_bucket" "pgbackup_kubenuc" {
  bucket = local.aws_secrets.buckets.pgbackup_kubenuc
}

resource "aws_s3_bucket_versioning" "pgbackup_kubenuc" {
  bucket = aws_s3_bucket.pgbackup_kubenuc.id

  versioning_configuration {
    status = "Suspended"
  }
}
