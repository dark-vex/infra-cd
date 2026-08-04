# ── gozzi-01-lug interfaces ───────────────────────────────────────────────────

resource "netbox_device_interface" "gozzi_01_lug_eno1" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "eno1"
  type      = "1000base-t"
}

resource "netbox_device_interface" "gozzi_01_lug_eno2" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "eno2"
  type      = "1000base-t"
}

resource "netbox_device_interface" "gozzi_01_lug_vmbr0" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "vmbr0"
  type      = "bridge"
}

resource "netbox_device_interface" "gozzi_01_lug_vmbr1" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "vmbr1"
  type      = "bridge"
}

resource "netbox_device_interface" "gozzi_01_lug_vmbr2" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "vmbr2"
  type      = "bridge"
}

resource "netbox_device_interface" "gozzi_01_lug_vmbr3" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "vmbr3"
  type      = "bridge"
}

resource "netbox_device_interface" "gozzi_01_lug_vmbr4" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "vmbr4"
  type      = "bridge"
}

resource "netbox_device_interface" "gozzi_01_lug_vmbr5" {
  device_id = netbox_device.gozzi_01_lug.id
  name      = "vmbr5"
  type      = "bridge"
}

# ── hpelvisor interfaces ───────────────────────────────────────────────────────

resource "netbox_device_interface" "hpelvisor_vmbr0" {
  device_id = netbox_device.hpelvisor.id
  name      = "vmbr0"
  type      = "bridge"
}

resource "netbox_device_interface" "hpelvisor_vmbr3" {
  device_id = netbox_device.hpelvisor.id
  name      = "vmbr3"
  type      = "bridge"
}

resource "netbox_device_interface" "hpelvisor_vmbr5" {
  device_id = netbox_device.hpelvisor.id
  name      = "vmbr5"
  type      = "bridge"
}

# ── rabbit-01-psp interfaces ──────────────────────────────────────────────────

resource "netbox_device_interface" "rabbit_01_psp_eno1" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "eno1"
  type      = "1000base-t"
}

resource "netbox_device_interface" "rabbit_01_psp_eno2" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "eno2"
  type      = "1000base-t"
}

resource "netbox_device_interface" "rabbit_01_psp_vmbr0" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "vmbr0"
  type      = "bridge"
}

resource "netbox_device_interface" "rabbit_01_psp_vmbr1" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "vmbr1"
  type      = "bridge"
}

resource "netbox_device_interface" "rabbit_01_psp_vmbr2" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "vmbr2"
  type      = "bridge"
}

resource "netbox_device_interface" "rabbit_01_psp_vmbr3" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "vmbr3"
  type      = "bridge"
}

resource "netbox_device_interface" "rabbit_01_psp_vmbr4" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "vmbr4"
  type      = "bridge"
}

resource "netbox_device_interface" "rabbit_01_psp_vmbr5" {
  device_id = netbox_device.rabbit_01_psp.id
  name      = "vmbr5"
  type      = "bridge"
}

# ── sophos-xg-lug interfaces ──────────────────────────────────────────────────

resource "netbox_device_interface" "sophos_xg_lug_port_1" {
  device_id = netbox_device.sophos_xg_lug.id
  name      = "port_1"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_lug_port_2" {
  device_id = netbox_device.sophos_xg_lug.id
  name      = "port_2"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_lug_port_3" {
  device_id = netbox_device.sophos_xg_lug.id
  name      = "port_3"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_lug_port_4" {
  device_id = netbox_device.sophos_xg_lug.id
  name      = "port_4"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_lug_port_5" {
  device_id = netbox_device.sophos_xg_lug.id
  name      = "port_5"
  type      = "1000base-t"
}

# ── sophos-xg-bgy interfaces ──────────────────────────────────────────────────

resource "netbox_device_interface" "sophos_xg_bgy_port_a" {
  device_id = netbox_device.sophos_xg_bgy.id
  name      = "port_a"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_bgy_port_b" {
  device_id = netbox_device.sophos_xg_bgy.id
  name      = "port_b"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_bgy_port_c" {
  device_id = netbox_device.sophos_xg_bgy.id
  name      = "port_c"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_bgy_port_d" {
  device_id = netbox_device.sophos_xg_bgy.id
  name      = "port_d"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_bgy_port_e" {
  device_id = netbox_device.sophos_xg_bgy.id
  name      = "port_e"
  type      = "1000base-t"
}

resource "netbox_device_interface" "sophos_xg_bgy_port_f" {
  device_id = netbox_device.sophos_xg_bgy.id
  name      = "port_f"
  type      = "1000base-t"
}
