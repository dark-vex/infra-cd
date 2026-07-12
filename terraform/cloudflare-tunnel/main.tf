# WARNING: this list is derived from the local cloudflared ConfigMap, NOT
# from the tunnels' live remote config (config_src: "cloudflare" for both
# tunnels — see terraform/cloudflare-tunnel/secrets.sops.yaml prerequisites).
# The first `apply` against each module below fully replaces that tunnel's
# remote ingress config in one call. Before applying, diff this list against:
#   curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
#     "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations"
# Any hostname live today but missing here will be silently dropped.

module "kubenuc" {
  source     = "github.com/dark-vex/terraform-cloudflare-tunnel?ref=4ae3b1d6f6983acd739148a77255a4c7e756bbd1" # v1.0.0 (untagged)
  account_id = local.cf.account_id
  tunnel_id  = local.cf.kubenuc.tunnel_id
  ingress_rules = [
    {
      hostname = local.cf.kubenuc.nextcloud_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.nextcloud_host
      }
    },
    {
      hostname = local.cf.kubenuc.harbor_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.harbor_host
      }
    },
    {
      hostname = local.cf.kubenuc.jellyfin_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.jellyfin_host
      }
    },
    {
      hostname = local.cf.kubenuc.portainer_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.portainer_host
      }
    },
    {
      hostname = local.cf.kubenuc.jenkins_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.jenkins_host
      }
    },
    {
      hostname = local.cf.kubenuc.sso_authentik_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.sso_authentik_host
      }
    },
    {
      hostname = local.cf.kubenuc.sso_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.sso_host
      }
    },
    {
      hostname = local.cf.kubenuc.s3_api_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.s3_api_host
      }
    },
    {
      hostname = local.cf.kubenuc.artifactory_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.artifactory_host
      }
    },
    {
      hostname = local.cf.kubenuc.flux_webhook_host
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.kubenuc.flux_webhook_host
      }
    },
    { service = "http_status:404" }, # catch-all, must stay last
  ]
}

module "prod_k3s" {
  source     = "github.com/dark-vex/terraform-cloudflare-tunnel?ref=4ae3b1d6f6983acd739148a77255a4c7e756bbd1" # v1.0.0 (untagged)
  account_id = local.cf.account_id
  tunnel_id  = local.cf.prod_k3s.tunnel_id
  ingress_rules = [
    {
      hostname = local.cf.prod_k3s.semaphore_host
      service  = "https://traefik.kube-system.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.prod_k3s.semaphore_host
      }
    },
    {
      hostname = local.cf.prod_k3s.awx_host
      service  = "https://traefik.kube-system.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.prod_k3s.awx_host
      }
    },
    {
      hostname = local.cf.prod_k3s.teleport_host
      service  = "https://traefik.kube-system.svc.cluster.local:443"
      origin_request = {
        origin_server_name = local.cf.prod_k3s.teleport_host
      }
    },
    { service = "http_status:404" }, # catch-all, must stay last
  ]
}
