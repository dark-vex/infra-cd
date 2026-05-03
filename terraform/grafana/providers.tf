terraform {
  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "infra-cd-grafana"
    }
  }

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3"
    }
  }
}

# ---------------------------------------------------------------------------
# 1Password: Grafana Cloud service account
#
# Create a 1Password item with:
#   - Website URL  = https://<your-stack>.grafana.net   (used as provider URL)
#   - Password     = glsa_<service-account-token>        (Editor role required)
#
# Then replace the vault/uuid placeholders below with the actual UUIDs from
# your 1Password vault (visible in the item's URL or via `op item get`).
# ---------------------------------------------------------------------------
data "onepassword_item" "grafana" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "fnpmabehc3obdrdwbdosw63z6m"
}

provider "grafana" {
  url  = data.onepassword_item.grafana.url
  auth = data.onepassword_item.grafana.password
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

variable "onepassword_token" {
  sensitive = true
}

variable "onepassword_endpoint" {
  sensitive = true
}
