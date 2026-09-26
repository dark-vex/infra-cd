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
      # >= 5.6.1 required: NetBox Cloud upgraded server-side sometime around
      # 2026-09-25 (SaaS, no changelog we control) and every netbox_ip_address
      # refresh started failing with "(*interface {}) is not supported by the
      # TextConsumer" against provider 5.3.0 - the provider's swagger client
      # can't decode newer NetBox 4.x response shapes (e.g. the primary MAC
      # address split into its own object). 5.6.1's release notes say
      # explicitly "adds support for NetBox versions up to 4.6.1". Pinned
      # below 6.0.0 deliberately: that will be a from-scratch, mostly
      # auto-generated rewrite per the 5.8.0 release notes.
      version = ">= 5.6.1, ~> 5.8"
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
