# Physical servers
#
# All bare-metal hosts run Proxmox VE as the hypervisor. Kubernetes nodes are
# VMs/LXCs provisioned on top of Proxmox — they are not modeled here.

resource "netbox_device" "astronomical_01_prg" {
  name           = "astronomical-01-prg"
  device_type_id = netbox_device_type.dl360_gen9.id
  role_id        = netbox_device_role.hypervisor.id
  site_id        = netbox_site.prg.id
  location_id    = netbox_location.prague.id
  platform_id    = netbox_platform.proxmox.id
  status         = "decommissioning"
}

resource "netbox_device" "rabbit_01_psp" {
  name           = "rabbit-01-psp"
  device_type_id = netbox_device_type.dl360_gen9.id
  role_id        = netbox_device_role.hypervisor.id
  site_id        = netbox_site.bgy.id
  location_id    = netbox_location.bergamo.id
  rack_id        = netbox_rack.bergamo.id
  platform_id    = netbox_platform.proxmox.id
  status         = "active"
}

resource "netbox_device" "gozzi_01_lug" {
  name           = "gozzi-01-lug"
  device_type_id = netbox_device_type.dl360_gen9.id
  role_id        = netbox_device_role.hypervisor.id
  site_id        = netbox_site.lgu.id
  location_id    = netbox_location.balerna.id
  rack_id        = netbox_rack.bio.id
  platform_id    = netbox_platform.proxmox.id
  status         = "active"
}

resource "netbox_device" "gozzi_02_lug" {
  name           = "gozzi-02-lug"
  device_type_id = netbox_device_type.dl380e_gen8.id
  role_id        = netbox_device_role.hypervisor.id
  site_id        = netbox_site.lgu.id
  location_id    = netbox_location.balerna.id
  rack_id        = netbox_rack.bio.id
  platform_id    = netbox_platform.proxmox.id
  status         = "active"
}

resource "netbox_device" "ms01_mxp" {
  name           = "ms01-mxp"
  device_type_id = netbox_device_type.ms01.id
  role_id        = netbox_device_role.hypervisor.id
  site_id        = netbox_site.mxp.id
  location_id    = netbox_location.milan.id
  platform_id    = netbox_platform.proxmox.id
  status         = "active"
}
