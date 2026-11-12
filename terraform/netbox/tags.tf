resource "netbox_tag" "ip_discovery_pending" {
  name      = "ip-discovery-pending"
  slug      = "ip-discovery-pending"
  color_hex = "9e9e9e"
}

resource "netbox_tag" "tf_managed" {
  name      = "tf-managed"
  slug      = "tf-managed"
  color_hex = "3f51b5"
}

# Kubernetes cluster nodes with a primary IP (kubenuc, prod-k3s, k3s-rabbit). The
# Zabbix host role (ansible/zabbix-hosts, CODE-121) monitors every VM except
# these, which the cluster monitoring covers instead. The OCI node (oc-ampere)
# has no primary IP in NetBox, so the role skips it already.
resource "netbox_tag" "kubernetes_node" {
  name      = "kubernetes-node"
  slug      = "kubernetes-node"
  color_hex = "326ce5"
}

resource "netbox_tag" "dhcp" {
  name      = "dhcp"
  slug      = "dhcp"
  color_hex = "00bcd4"
}

# The guest still asks for DHCP, but its lease is pinned by a static DHCP
# reservation on the Sophos firewall (tracked in CODE-93), so the address is
# stable. Guests with only `dhcp` have no reservation yet.
resource "netbox_tag" "dhcp_reserved" {
  name      = "dhcp-reserved"
  slug      = "dhcp-reserved"
  color_hex = "009688"
}
