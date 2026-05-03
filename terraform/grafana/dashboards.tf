# Auto-generated — do not edit by hand.
# Add apps in generate_dashboards.py, re-run it, then add the resource block here.

# kubenuc
resource "grafana_dashboard" "kubenuc_1password" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/1password.json")
}

resource "grafana_dashboard" "kubenuc_bareos" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/bareos.json")
}

resource "grafana_dashboard" "kubenuc_cert_manager" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/cert-manager.json")
}

resource "grafana_dashboard" "kubenuc_cloudflare" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/cloudflare.json")
}

resource "grafana_dashboard" "kubenuc_falco" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/falco.json")
}

resource "grafana_dashboard" "kubenuc_film_tv_exporter" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/film-tv-exporter.json")
}

resource "grafana_dashboard" "kubenuc_grafana_alloy" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/grafana-alloy.json")
}

resource "grafana_dashboard" "kubenuc_haproxy_ingress" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/haproxy-ingress.json")
}

resource "grafana_dashboard" "kubenuc_harbor" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/harbor.json")
}

resource "grafana_dashboard" "kubenuc_jellyfin" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/jellyfin.json")
}

resource "grafana_dashboard" "kubenuc_jenkins" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/jenkins.json")
}

resource "grafana_dashboard" "kubenuc_jfrog_acr" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/jfrog-acr.json")
}

resource "grafana_dashboard" "kubenuc_net_mon" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/net-mon.json")
}

resource "grafana_dashboard" "kubenuc_nextcloud" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/nextcloud.json")
}

resource "grafana_dashboard" "kubenuc_nut" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/nut.json")
}

resource "grafana_dashboard" "kubenuc_openebs" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/openebs.json")
}

resource "grafana_dashboard" "kubenuc_portainer" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/portainer.json")
}

resource "grafana_dashboard" "kubenuc_postgresql" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/postgresql.json")
}

resource "grafana_dashboard" "kubenuc_s3" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/s3.json")
}

resource "grafana_dashboard" "kubenuc_sso" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/sso.json")
}

resource "grafana_dashboard" "kubenuc_system_upgrade_controller" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/system-upgrade-controller.json")
}

resource "grafana_dashboard" "kubenuc_unifi" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/unifi.json")
}

resource "grafana_dashboard" "kubenuc_zabbix" {
  folder      = grafana_folder.kubenuc.uid
  config_json = file("${path.module}/dashboards/kubenuc/zabbix.json")
}

# k8s-vms-daniele
resource "grafana_dashboard" "k8s_vms_daniele_1password" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/1password.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_awx" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/awx.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_blackbox" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/blackbox.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_cert_manager" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/cert-manager.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_cloudflare" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/cloudflare.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_falco" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/falco.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_grafana_alloy" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/grafana-alloy.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_node_exporter" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/node-exporter.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_semaphore" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/semaphore.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_system_upgrade_controller" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/system-upgrade-controller.json")
}

resource "grafana_dashboard" "k8s_vms_daniele_teleport_agent" {
  folder      = grafana_folder.k8s_vms_daniele.uid
  config_json = file("${path.module}/dashboards/k8s-vms-daniele/teleport-agent.json")
}

