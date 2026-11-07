terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "netbox/terraform.tfstate"
    region = "auto"

    # R2 compatibility flags
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true

  }

  required_version = ">= 1.10.0"

  required_providers {
    netbox = {
      source = "e-breuninger/netbox"
      # The floor is kept at 5.6.1 (release notes: NetBox up to 4.6.1), but it
      # did not fix the intermittent "(*interface {}) is not supported by the
      # TextConsumer" error: NetBox Cloud sometimes answers a refresh burst with
      # a non-JSON reply the provider cannot decode, and a re-run passes on the
      # same provider version (5.8.0 failed and passed in the same days). The
      # provider never retries; terraform-netbox.yml retries the plan once
      # (CODE-97). Pinned below 6.0.0 deliberately: that is a from-scratch,
      # mostly auto-generated rewrite per the 5.8.0 release notes.
      version = "~> 6.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
  }
}
