data "onepassword_item" "gitops_source" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Portainer-GitOps-Source"
}

resource "portainer_gitops_source" "compose" {
  name                = "infra-cd-docker"
  url                 = local.stacks_repository_url
  interval            = "30m"
  username            = "x-access-token"
  password            = data.onepassword_item.gitops_source.password
  administrators_only = true

  lifecycle {
    prevent_destroy = true
  }
}
