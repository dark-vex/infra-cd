# Registries credentialed in Portainer. Passwords cannot be read back from
# Portainer, so the first apply writes the password from 1Password (a
# deliberate credential write - confirm the item holds the intended
# credential before approving the apply).
#
# Registry name/URL of the Harbor instance are FQDNs and live in
# secrets.sops.yaml. No registry_access entries exist live, so
# portainer_registry_access is not managed.

data "onepassword_item" "registry_harbor" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Portainer-Registry-Harbor"
}

data "onepassword_item" "registry_dockerhub" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Portainer-Registry-DockerHub"
}

import {
  to = portainer_registry.harbor
  id = "1"
}

resource "portainer_registry" "harbor" {
  name           = local.portainer_values.registries.harbor.name
  type           = 3 # custom registry
  url            = local.portainer_values.registries.harbor.url
  authentication = true
  username       = data.onepassword_item.registry_harbor.username
  password       = data.onepassword_item.registry_harbor.password

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = portainer_registry.dockerhub
  id = "2"
}

resource "portainer_registry" "dockerhub" {
  name           = "dockerhub"
  type           = 6 # Docker Hub
  url            = "docker.io"
  authentication = true
  username       = data.onepassword_item.registry_dockerhub.username
  password       = data.onepassword_item.registry_dockerhub.password

  lifecycle {
    prevent_destroy = true
  }
}
