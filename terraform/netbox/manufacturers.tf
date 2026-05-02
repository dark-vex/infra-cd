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
  description = "Hewlett Packard Enterprise"
}

resource "netbox_manufacturer" "intel" {
  name = "Intel"
  slug = "intel"
  description = "Intel Corporation"
}

resource "netbox_manufacturer" "unifi" {
  name = "Unifi"
  slug = "unifi"
  description = "Ubiquiti Networks Unifi"
}

resource "netbox_manufacturer" "aruba-hpe" {
  name = "Aruba HPE"
  slug = "aruba-hpe"
  description = "Aruba Networks, a Hewlett Packard Enterprise company"
}

resource "netbox_manufacturer" "minisforum" {
  name = "Minisforum"
  slug = "minisforum"
  description = "Minisforum Technology Co., Ltd."
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
