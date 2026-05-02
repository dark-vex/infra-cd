# ── Device Roles ─────────────────────────────────────────────────────────────

# Existing role — imported from NetBox (ID 1)

import {
  to = netbox_device_role.switch
  id = "1"
}

import {
  to = netbox_device_role.server
  id = "2"
}

resource "netbox_device_role" "switch" {
  name      = "Switch"
  slug      = "switch"
  color_hex = "00ffff"
  vm_role   = false
}

# New roles — not yet in NetBox

resource "netbox_device_role" "server" {
  name      = "Server"
  slug      = "server"
  color_hex = "4caf50"
  vm_role   = false
}

resource "netbox_device_role" "hypervisor" {
  name      = "Hypervisor"
  slug      = "hypervisor"
  color_hex = "2196f3"
  vm_role   = false
}

resource "netbox_device_role" "vps" {
  name      = "VPS"
  slug      = "vps"
  color_hex = "ff9800"
  vm_role   = true
}
