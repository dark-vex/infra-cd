# Sophos SSL VPN site-to-site tunnels (vpn.tunnel), CODE-110.
#
# Evidence rule: a tunnel is modelled only when a read-only live source proves
# the interface and the owner states what it connects. The Bio-side firewall's
# SNMP interfaces (Zabbix) show tun22, tun1 and tun0, all up. Per the repo
# owner, tun22 is the site-to-site link to the PSP site, tun1 the one to the
# MXP site, and tun0 is the remote-access SSL VPN (not a site-to-site tunnel,
# so not modelled). tun1 follows in a second PR once this one reads back
# cleanly on NetBox 4.7.4 (canary first).
#
# Only the Bio-side termination is modelled: the peer firewalls' tun interface
# names are not proven (the PSP-side Zabbix host is disabled and its tun items
# are stale). Add the peer terminations once their interfaces are known.
# Sophos SSL VPN is OpenVPN-based, hence the encapsulation. Overlay networks
# (Tailscale, NetBird) are separate and not modelled here.

resource "netbox_vpn_tunnel_group" "sophos_ssl_vpn" {
  name        = "sophos-ssl-vpn"
  slug        = "sophos-ssl-vpn"
  description = "CODE-110: Sophos SSL VPN site-to-site tunnels"
  tags        = [netbox_tag.tf_managed.slug]
}

resource "netbox_device_interface" "sophos_xg_lug_tun22" {
  device_id   = netbox_device.sophos_xg_lug.id
  name        = "tun22"
  type        = "virtual"
  description = "CODE-110: SSL VPN site-to-site tunnel (Zabbix SNMP, owner-stated)"
  tags        = [netbox_tag.tf_managed.slug]
}

resource "netbox_vpn_tunnel" "bio_psp_ssl_vpn" {
  name                = "bio-psp-ssl-vpn"
  encapsulation       = "openvpn"
  status              = "active"
  vpn_tunnel_group_id = netbox_vpn_tunnel_group.sophos_ssl_vpn.id
  description         = "CODE-110: Bio to PSP, owner-stated, interface up per Zabbix"
  tags                = [netbox_tag.tf_managed.slug]
}

resource "netbox_vpn_tunnel_termination" "bio_psp_ssl_vpn_bio" {
  vpn_tunnel_id       = netbox_vpn_tunnel.bio_psp_ssl_vpn.id
  role                = "peer"
  device_interface_id = netbox_device_interface.sophos_xg_lug_tun22.id
  tags                = [netbox_tag.tf_managed.slug]
}
