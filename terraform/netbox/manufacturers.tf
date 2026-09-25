import {
  to = netbox_manufacturer.aruba-hpe
  id = "1"
}

import {
  to = netbox_manufacturer.unifi
  id = "2"
}

import {
  to = netbox_manufacturer.hpe
  id = "3"
}

import {
  to = netbox_manufacturer.minisforum
  id = "4"
}

import {
  to = netbox_manufacturer.intel
  id = "5"
}

resource "netbox_manufacturer" "hpe" {
  name = "HPE"
  slug = "hpe"
}

resource "netbox_manufacturer" "intel" {
  name = "Intel"
  slug = "intel"
}

resource "netbox_manufacturer" "unifi" {
  name = "Unifi"
  slug = "unifi"
}

resource "netbox_manufacturer" "aruba-hpe" {
  name = "Aruba HPE"
  slug = "aruba-hpe"
}

resource "netbox_manufacturer" "minisforum" {
  name = "Minisforum"
  slug = "minisforum"
}

resource "netbox_device_type" "dl360_gen9" {
  manufacturer_id = netbox_manufacturer.hpe.id
  model           = "ProLiant DL360 Gen9"
  slug            = "proliant-dl360-gen9"
  u_height        = 1
  is_full_depth   = true
}

resource "netbox_device_type" "dl380e_gen8" {
  manufacturer_id = netbox_manufacturer.hpe.id
  model           = "ProLiant DL380e Gen8"
  slug            = "proliant-dl380e-gen8"
  u_height        = 2
  is_full_depth   = true
}

resource "netbox_device_type" "ms01" {
  manufacturer_id = netbox_manufacturer.minisforum.id
  model           = "MS-01"
  slug            = "ms-01"
  u_height        = 0
}

resource "netbox_platform" "proxmox" {
  name = "Proxmox VE"
  slug = "proxmox-ve"
}

resource "netbox_platform" "debian" {
  name = "Debian"
  slug = "debian"
}

resource "netbox_platform" "ubuntu" {
  name = "Ubuntu"
  slug = "ubuntu"
}

resource "netbox_manufacturer" "sophos" {
  name = "Sophos"
  slug = "sophos"
}

resource "netbox_device_type" "sophos_xg" {
  manufacturer_id = netbox_manufacturer.sophos.id
  model           = "XG"
  slug            = "sophos-xg"
  u_height        = 1
  is_full_depth   = false
}

# dcknuc (MXP) — an Intel NUC7CJYH running Debian 13 + Docker, per repo owner.
resource "netbox_device_type" "nuc7cjyh" {
  manufacturer_id = netbox_manufacturer.intel.id
  model           = "NUC7CJYH"
  slug            = "nuc7cjyh"
  u_height        = 0
}

# Temporarily re-declared. #2044 renamed this resource address from
# intel_nuc to nuc7cjyh (device_type resources are destroy+create on
# rename, no moved block) in the same apply as switching dcknuc's
# device_type_id to point at the new one - that apply raced: the destroy
# of this resource ran before dcknuc's update landed, so NetBox's own
# referential-integrity check blocked the delete (dcknuc (35) still
# pointed here). Live state right now: this device_type (id=34) still
# exists with dcknuc as its sole dependent; nuc7cjyh (id=35, above)
# already exists live with zero dependents. Re-declaring this exactly as
# it lives today lets the next apply do only the dcknuc update, with no
# destroy in the same run to race against. Remove this block in a
# follow-up commit/apply, once confirmed dcknuc no longer references it -
# only then will its destroy have zero dependents and be safe.
resource "netbox_device_type" "intel_nuc" {
  manufacturer_id = netbox_manufacturer.intel.id
  model           = "NUC"
  slug            = "intel-nuc"
  u_height        = 0
}
