terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "cloudflare-dns"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # 5.26.0 is a confirmed-broken release: cloudflare/terraform-provider-cloudflare#7396
      # (new include_shadow_metadata attribute forces a PUT on every dns_record,
      # fails with code 1046 on any record now owned by Cloudflare Email Routing)
      # and #7387 (modified_on inconsistent-result regression). No .terraform.lock.hcl
      # is committed for this stack (gitignored), so every CI run re-resolves fresh
      # within this constraint - excluding the bad version, not an exact pin, so
      # Renovate/future runs still pick up the real fix once #7403 (v5.27.0) ships.
      version = ">= 5.0.0, != 5.26.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
  }
}

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from environment; no config needed here
}

provider "sops" {}
