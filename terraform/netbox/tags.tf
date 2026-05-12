resource "netbox_tag" "ip_discovery_pending" {
  name  = "ip-discovery-pending"
  slug  = "ip-discovery-pending"
  color = "9e9e9e"
}

resource "netbox_tag" "tf_managed" {
  name  = "tf-managed"
  slug  = "tf-managed"
  color = "3f51b5"
}

resource "netbox_tag" "dhcp" {
  name  = "dhcp"
  slug  = "dhcp"
  color = "00bcd4"
}
