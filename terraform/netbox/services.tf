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
# listeners, and cluster-level services (AWX, CODE-111, is modelled below as an
# ingress service on each node that answers for it).
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

resource "netbox_service" "rabbit_seaweedfs_lxc_master" {
  name               = "seaweedfs-master"
  protocol           = "tcp"
  ports              = [9333]
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
  description        = "CODE-109: repo (ansible/seaweedfs)"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "rabbit_seaweedfs_lxc_volume" {
  name               = "seaweedfs-volume"
  protocol           = "tcp"
  ports              = [8080]
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
  description        = "CODE-109: repo (ansible/seaweedfs)"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "rabbit_seaweedfs_lxc_filer" {
  name               = "seaweedfs-filer"
  protocol           = "tcp"
  ports              = [8888]
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
  description        = "CODE-109: repo (ansible/seaweedfs)"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "rabbit_seaweedfs_lxc_admin" {
  name               = "seaweedfs-admin"
  protocol           = "tcp"
  ports              = [23646]
  virtual_machine_id = netbox_virtual_machine.rabbit_seaweedfs_lxc.id
  description        = "CODE-109: repo (ansible/seaweedfs)"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "hpelvisor_seaweedfs_lxc_volume" {
  name               = "seaweedfs-volume"
  protocol           = "tcp"
  ports              = [8080]
  virtual_machine_id = netbox_virtual_machine.hpelvisor_seaweedfs_lxc.id
  description        = "CODE-109: repo (ansible/seaweedfs), no master/admin on non-first hosts"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "hpelvisor_seaweedfs_lxc_filer" {
  name               = "seaweedfs-filer"
  protocol           = "tcp"
  ports              = [8888]
  virtual_machine_id = netbox_virtual_machine.hpelvisor_seaweedfs_lxc.id
  description        = "CODE-109: repo (ansible/seaweedfs), no master/admin on non-first hosts"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "rabbit_graylog_lxc_syslog" {
  name               = "syslog"
  protocol           = "tcp"
  ports              = [514]
  virtual_machine_id = netbox_virtual_machine.rabbit_graylog_lxc.id
  description        = "CODE-109: live Graylog input"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "rabbit_graylog_lxc_otlp_grpc" {
  name               = "otlp-grpc"
  protocol           = "tcp"
  ports              = [4317]
  virtual_machine_id = netbox_virtual_machine.rabbit_graylog_lxc.id
  description        = "CODE-109: live Graylog input, repo (otlp shipping)"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_web1_ftp" {
  name               = "ftp"
  protocol           = "tcp"
  ports              = [21]
  virtual_machine_id = netbox_virtual_machine.gozzi_web1.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_web1_http" {
  name               = "http"
  protocol           = "tcp"
  ports              = [80]
  virtual_machine_id = netbox_virtual_machine.gozzi_web1.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_mail1_smtp" {
  name               = "smtp"
  protocol           = "tcp"
  ports              = [25]
  virtual_machine_id = netbox_virtual_machine.gozzi_mail1.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_mail1_imap" {
  name               = "imap"
  protocol           = "tcp"
  ports              = [143]
  virtual_machine_id = netbox_virtual_machine.gozzi_mail1.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_mail1_pop3" {
  name               = "pop3"
  protocol           = "tcp"
  ports              = [110]
  virtual_machine_id = netbox_virtual_machine.gozzi_mail1.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_mail1_http" {
  name               = "http"
  protocol           = "tcp"
  ports              = [80]
  virtual_machine_id = netbox_virtual_machine.gozzi_mail1.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "gozzi_dolibarr_http" {
  name               = "http"
  protocol           = "tcp"
  ports              = [80]
  virtual_machine_id = netbox_virtual_machine.gozzi_dolibarr.id
  description        = "CODE-109: Zabbix net.tcp.service check"
  tags               = [netbox_tag.tf_managed.slug]
}

# AWX (CODE-111): the live awx Ingress (Traefik class, port 80) lists the two
# cluster node addresses, which are the prod-k3s master and worker1 VMs.
# Flux calls this cluster k8s-vms-daniele.
resource "netbox_service" "hpelvisor_prod_k3s_master_awx_http" {
  name               = "awx-http"
  protocol           = "tcp"
  ports              = [80]
  virtual_machine_id = netbox_virtual_machine.hpelvisor_prod_k3s_master.id
  description        = "CODE-111: AWX ingress (Traefik), live Ingress"
  tags               = [netbox_tag.tf_managed.slug]
}

resource "netbox_service" "hpelvisor_prod_k3s_worker1_awx_http" {
  name               = "awx-http"
  protocol           = "tcp"
  ports              = [80]
  virtual_machine_id = netbox_virtual_machine.hpelvisor_prod_k3s_worker1.id
  description        = "CODE-111: AWX ingress (Traefik), live Ingress"
  tags               = [netbox_tag.tf_managed.slug]
}
