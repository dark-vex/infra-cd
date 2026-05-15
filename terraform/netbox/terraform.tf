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

    # Native state locking (Terraform 1.10+)
    use_lockfile = true
  }

  required_version = ">= 1.10.0"

  required_providers {
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 5.0"
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
