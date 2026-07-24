# ── Sites ───────────────────────────────────────────────────────────────────

# Existing sites — imported from NetBox (IDs 1–4)

import {
  to = netbox_site.lgu
  id = "1"
}

resource "netbox_site" "lgu" {
  name      = "ddlns-lgu"
  slug      = "ddlns-lgu"
  status    = "active"
  facility  = "LGU"
  region_id = 1
  timezone  = "Europe/Rome"
}

import {
  to = netbox_site.bgy
  id = "2"
}

resource "netbox_site" "bgy" {
  name      = "ddlns-bgy"
  slug      = "ddlns-bgy"
  status    = "active"
  facility  = "BGY"
  region_id = 2
  timezone  = "Europe/Rome"
}

import {
  to = netbox_site.mxp
  id = "3"
}

resource "netbox_site" "mxp" {
  name      = "ddlns-mxp"
  slug      = "ddlns-mxp"
  status    = "active"
  facility  = "MXP"
  region_id = 3
  timezone  = "Europe/Rome"
}

import {
  to = netbox_site.prg
  id = "4"
}

resource "netbox_site" "prg" {
  name      = "ddlns-prg"
  slug      = "ddlns-prg"
  status    = "planned"
  facility  = "PRG"
  region_id = 4
}

# New sites — not yet in NetBox

resource "netbox_site" "zrh" {
  name   = "ddlns-zrh"
  slug   = "ddlns-zrh"
  status = "active"
}

resource "netbox_site" "nbg" {
  name   = "ddlns-nbg"
  slug   = "ddlns-nbg"
  status = "active"
}

resource "netbox_site" "nl" {
  name   = "ddlns-nl"
  slug   = "ddlns-nl"
  status = "active"
}

# ── Locations ────────────────────────────────────────────────────────────────

# Existing locations — imported from NetBox (IDs 1–4)

import {
  to = netbox_location.bergamo
  id = "1"
}

resource "netbox_location" "bergamo" {
  name    = "Bergamo"
  slug    = "bergamo"
  site_id = netbox_site.bgy.id
}

import {
  to = netbox_location.balerna
  id = "2"
}

resource "netbox_location" "balerna" {
  name        = "Balerna"
  slug        = "balerna"
  site_id     = netbox_site.lgu.id
  description = "Balerna site - Bioadventures"
}

import {
  to = netbox_location.milan
  id = "3"
}

resource "netbox_location" "milan" {
  name    = "Milan"
  slug    = "milan"
  site_id = netbox_site.mxp.id
}

import {
  to = netbox_location.prague
  id = "4"
}

resource "netbox_location" "prague" {
  name    = "Prague"
  slug    = "prague"
  site_id = netbox_site.prg.id
}

# New locations — not yet in NetBox

resource "netbox_location" "zurich" {
  name    = "Zurich"
  slug    = "zurich"
  site_id = netbox_site.zrh.id
}

resource "netbox_location" "nuremberg" {
  name    = "Nuremberg"
  slug    = "nuremberg"
  site_id = netbox_site.nbg.id
}

resource "netbox_location" "netherlands" {
  name    = "Netherlands"
  slug    = "netherlands"
  site_id = netbox_site.nl.id
}
