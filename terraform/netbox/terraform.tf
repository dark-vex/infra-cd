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
      # 6.0 is a from-scratch rewrite (migration guide in the provider repo) and
      # supports NetBox 4.6.8-4.6.10 only. The intermittent "(*interface {}) is
      # not supported by the TextConsumer" error seen on 5.x (NetBox Cloud
      # answering a refresh burst with a non-JSON reply) may no longer match
      # that string; terraform-netbox.yml still retries the plan once (CODE-97).
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
