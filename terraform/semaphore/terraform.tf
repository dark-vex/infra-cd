terraform {
  # >= 1.11.0: required for write-only attributes (password_wo on
  # semaphoreui_project_key.login_password below) — keeps the webhook HMAC
  # secret out of Terraform state entirely.
  required_version = ">= 1.11.0"

  cloud {
    organization = "Fastnetserv"
    workspaces {
      name = "semaphore"
    }
  }

  required_providers {
    # Registry source is semaphoreui/semaphore, NOT semaphoreui/semaphoreui -
    # the chart repo (semaphoreui/charts) and this provider repo
    # (semaphoreui/terraform-provider-semaphore) have similar-but-different
    # names, easy to mix up.
    semaphoreui = {
      source  = "semaphoreui/semaphore"
      version = "~> 0.3"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }
}
