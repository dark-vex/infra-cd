# Services offered by hosts (ipam.service), CODE-109.
#
# Evidence rule: a service is modelled only when this repo or a read-only live
# source proves it (Ansible group_vars/templates, Zabbix net.tcp.service checks,
# Graylog inputs). The Zabbix and Graylog evidence was mapped to VMs out of
# band. Nothing is guessed from a host's role.
#
# Conventions:
#   - one service per listener, parent by resource id (virtual_machine_id),
#     never parent_object_*; no FQDNs or addresses in HCL
#   - resource name is <parent VM resource>_<service>
#   - ip_address_ids is left unset, so the service is not bound to a specific
#     address; NetBox then treats it as reachable on any address of the parent
#
# Excluded on purpose: ssh (host management, not an application service),
# haproxy1 mail listeners (ports are SOPS-only, the repo is public), loopback
# listeners, and cluster-level services (CODE-111).
#
# NetBox 4.7 deprecated protocol/ports in favour of port_mappings. A second
# protocol added by hand in the UI makes NetBox return null for both, which
# shows up here as drift until the out-of-band mapping is removed.

resource "netbox_service" "rabbit_haproxy1_lxc_http" {
  name               = "http"
  protocol           = "tcp"
  ports              = [80]
  virtual_machine_id = netbox_virtual_machine.rabbit_haproxy1_lxc.id
  description        = "CODE-109: repo (ansible/haproxy)"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "rabbit_haproxy1_lxc_https" {
  name               = "https"
  protocol           = "tcp"
  ports              = [443]
  virtual_machine_id = netbox_virtual_machine.rabbit_haproxy1_lxc.id
  description        = "CODE-109: repo (ansible/haproxy)"
  tags               = [netbox_tag.tf_managed.slug]
}
