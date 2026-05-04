# Existing racks — imported from NetBox (IDs 1–2)

import {
  to = netbox_rack.bio
  id = "1"
}

resource "netbox_rack" "bio" {
  name        = "Bio Rack"
  site_id     = netbox_site.lgu.id
  location_id = netbox_location.balerna.id
  status      = "active"
  u_height    = 24
}

import {
  to = netbox_rack.bergamo
  id = "2"
}

resource "netbox_rack" "bergamo" {
  name        = "Ddlns Bergamo"
  site_id     = netbox_site.bgy.id
  location_id = netbox_location.bergamo.id
  status      = "active"
  u_height    = 48
}
