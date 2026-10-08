# Staged adoption of the live Portainer instance's own configuration: tags
# and endpoint groups (environments follow in a separate PR).
#
# The built-in "Unassigned" group (id 1) is not managed - Portainer cannot
# delete it.

# ---------------------------------------------------------------- tags

import {
  to = portainer_tag.dckh
  id = "1"
}

resource "portainer_tag" "dckh" {
  name = "dckh"
}

import {
  to = portainer_tag.oracle_cloud
  id = "2"
}

resource "portainer_tag" "oracle_cloud" {
  name = "oracle-cloud"
}

# ------------------------------------------------------- endpoint groups

import {
  to = portainer_endpoint_group.fastnetserv
  id = "2"
}

resource "portainer_endpoint_group" "fastnetserv" {
  name = "Fastnetserv"
}

import {
  to = portainer_endpoint_group.bioadventures
  id = "3"
}

resource "portainer_endpoint_group" "bioadventures" {
  name = "Bioadventures"
}

import {
  to = portainer_endpoint_group.oracle
  id = "4"
}

resource "portainer_endpoint_group" "oracle" {
  name = "Oracle"
}
