# NetBird routing peer for the BGY networks (CODE-123 follow-up).
#
# Zabbix reaches its monitored guests over NetBird, and there is no peer at BGY yet, so
# the LAN and DMZ guests are unreachable from it. This container has one leg on each
# network (eth0 on the LAN bridge, eth1 on the DMZ bridge), both static (DHCP guests
# drifted addresses once already), and routes the two subnets into the overlay. The
# NetBird side (group, setup key, network, router, policy) lives in infra-vpn; the client
# itself is installed by ansible/netbird-peer.
#
# Hostname and both addresses are in secrets.sops.yaml (lxc.netbird_bgy and
# lxc_net.netbird_bgy_lan / netbird_bgy_dmz, CIDR form); the gateway is the first address
# of the LAN subnet. Only eth0 has a gateway: a container has one default route.
#
# MANUAL, ONCE, on the Proxmox host (the module cannot express it, and a device set by
# the API would show as drift): the NetBird client needs the TUN device. Add to
# /etc/pve/lxc/808.conf and restart the container:
#   lxc.cgroup2.devices.allow: c 10:200 rwm
#   lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
# These raw lxc.* keys are not read back by the provider, so they cause no plan drift.
#
# RECREATING this container (a template bump, a new disk datastore, anything that forces
# replacement) loses those two lines AND the NetBird identity, and BGY routing is down
# until both are restored: re-add the lines, then run ansible/netbird-peer with a NEW
# setup key (the one-off key was consumed and is no longer kept in infra-vpn).
# ansible/netbird-peer also installs the zone isolation (no forwarding between eth0 and
# eth1), so a rebuilt container is not left routing between the LAN and the DMZ.
module "rabbit_netbird_bgy_lxc" {
  source = "github.com/dark-vex/terraform-proxmox-lxc?ref=49277d5e2d4eb8a5f3173e02965170aecde6711a" # v2.0.0
  providers = {
    proxmox = proxmox.rabbit
  }

  hostname    = local.rabbit_secrets.lxc.netbird_bgy
  vmid        = 808
  node_name   = "rabbit-01-psp"
  description = "NetBird routing peer for the BGY LAN and DMZ (Zabbix reachability)"

  cpu_cores      = 1
  memory         = 512
  swap           = 0
  disk_size      = 8
  disk_datastore = "data-ssd2"

  template_file_id = proxmox_download_file.rabbit_debian_12_lxc.id
  os_type          = "debian"

  network_interfaces = {
    eth0 = {
      bridge       = "vmbr1"
      ipv4_address = local.rabbit_secrets.lxc_net.netbird_bgy_lan
      ipv4_gateway = cidrhost(local.rabbit_secrets.lxc_net.netbird_bgy_lan, 1)
    }
    eth1 = {
      bridge       = "vmbr2"
      ipv4_address = local.rabbit_secrets.lxc_net.netbird_bgy_dmz
    }
  }

  console = {}

  ssh_keys = [
    local.ssh_public_key,
    local.ssh_public_key_new
  ]
  password     = data.onepassword_item.lxc_access.password
  unprivileged = true

  started       = true
  start_on_boot = true

  manage_user_account = true

  tags = ["automation", "lxc", "netbird", "vpn"]
}
