terraform {
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
