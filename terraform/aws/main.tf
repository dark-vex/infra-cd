# Live inventory confirmed 2026-09-13 via `aws s3api list-buckets` +
# get-bucket-location/get-bucket-versioning/get-bucket-tagging against the
# real account. All 3 buckets are in eu-south-1, none are
# tagged. Import blocks below bring them under Terraform WITHOUT changing
# any of their current settings - every resource here mirrors observed
# live state, nothing is "fixed" or hardened as part of this pass.

# ============================================================================
# aws-cloudtrail-logs-290469793140-6f955cbe
#
# CAUTION: the name strongly suggests this is the bucket AWS/CloudTrail
# auto-creates when trail logging is enabled on this account. Bringing it
# under Terraform is fine for drift *visibility*, but do not let a future
# apply touch its bucket policy/lifecycle/encryption without first diffing
# against whatever CloudTrail's own delivery configuration expects -
# breaking that silently kills audit logging. No versioning is configured
# live, so none is declared here.
# ============================================================================
import {
  to = aws_s3_bucket.cloudtrail_logs
  id = "aws-cloudtrail-logs-290469793140-6f955cbe"
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-290469793140-6f955cbe"
}

# ============================================================================
# MySQL backups bucket
#
# Real bucket name is SOPS-encrypted (terraform/aws/secrets.sops.yaml,
# local.aws_secrets.buckets.mysql_backups) rather than a literal string here
# - this repo previously ran a full history-purge (filter-repo + force-push,
# closed 2026-08-09) to remove this exact brand string from the public repo,
# so it's routed through the same secrets-indirection pattern already used
# for VM/LXC hostnames in terraform/proxmox/gozzi-hpelvisor and rabbit,
# per user direction (2026-09-13).
#
# No versioning configured live (never enabled, not merely suspended).
# Left unmanaged here on purpose - enabling versioning is a hardening
# decision for a separate, deliberate change, not a side effect of this
# import.
# ============================================================================
import {
  to = aws_s3_bucket.mysql_backups
  id = local.aws_secrets.buckets.mysql_backups
}

resource "aws_s3_bucket" "mysql_backups" {
  bucket = local.aws_secrets.buckets.mysql_backups
}

# ============================================================================
# pgbackup-kubenuc-s3
#
# Likely the Postgres backup target tied to kubenuc's Zalando
# postgres-operator (see memory: project_postgres_exporter_pgmonitor_hardening
# and the kubenuc pgbackup work) - not confirmed by reading kubenuc manifests
# in this pass, worth double-checking before merge.
#
# Versioning is live "Suspended" (i.e. it was enabled once, then turned
# off) - the resource below reflects that REAL state exactly. Do not change
# it to "Enabled" without a separate, deliberate decision; a naive
# "shouldn't backups have versioning on" assumption here would be a policy
# change disguised as a GitOps-tracking import.
# ============================================================================
import {
  to = aws_s3_bucket.pgbackup_kubenuc
  id = "pgbackup-kubenuc-s3"
}

import {
  to = aws_s3_bucket_versioning.pgbackup_kubenuc
  id = "pgbackup-kubenuc-s3"
}

resource "aws_s3_bucket" "pgbackup_kubenuc" {
  bucket = "pgbackup-kubenuc-s3"
}

resource "aws_s3_bucket_versioning" "pgbackup_kubenuc" {
  bucket = aws_s3_bucket.pgbackup_kubenuc.id

  versioning_configuration {
    status = "Suspended"
  }
}
