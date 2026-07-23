module "kubenuc" {
  source     = "github.com/dark-vex/terraform-cloudflare-tunnel?ref=44c00e84189e0f7da477cf0c16baff04da73f2b5" # v1.0.0
  account_id = local.cf.account_id
  tunnel_id  = local.cf.kubenuc.tunnel_id
  ingress_rules = [
    {
      hostname = local.cf.kubenuc.kubenuc_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.kubenuc_host
      }
    },
    {
      hostname = local.cf.kubenuc.photos_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.photos_host
      }
    },
    {
      hostname = local.cf.kubenuc.nextcloud_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.nextcloud_host
      }
    },
    {
      hostname = local.cf.kubenuc.harbor_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.harbor_host
      }
    },
    {
      hostname = local.cf.kubenuc.portainer_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.portainer_host
      }
    },
    {
      hostname = local.cf.kubenuc.jenkins_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.jenkins_host
      }
    },
    {
      hostname = local.cf.kubenuc.sso_authentik_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.sso_authentik_host
      }
    },
    {
      hostname = local.cf.kubenuc.sso_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.sso_host
      }
    },
    {
      hostname = local.cf.kubenuc.s3_api_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.s3_api_host
      }
    },
    {
      hostname = local.cf.kubenuc.s3_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.s3_host
      }
    },
    {
      hostname = local.cf.kubenuc.artifactory_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.artifactory_host
      }
    },
    {
      hostname = local.cf.kubenuc.flux_webhook_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.flux_webhook_host
      }
    },
    {
      hostname = local.cf.kubenuc.distr_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.distr_host
      }
    },
    {
      hostname = local.cf.kubenuc.distr_registry_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.distr_registry_host
      }
    },
    {
      hostname = local.cf.kubenuc.gitea_host
      service  = "http://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.kubenuc.gitea_host
      }
    },
    { service = "http_status:404" }, # catch-all, must stay last
  ]
}

module "prod_k3s" {
  source     = "github.com/dark-vex/terraform-cloudflare-tunnel?ref=44c00e84189e0f7da477cf0c16baff04da73f2b5" # v1.0.0
  account_id = local.cf.account_id
  tunnel_id  = local.cf.prod_k3s.tunnel_id
  ingress_rules = [
    {
      hostname = local.cf.prod_k3s.semaphore_host
      service  = "http://traefik.kube-system.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.prod_k3s.semaphore_host
      }
    },
    {
      hostname = local.cf.prod_k3s.awx_host
      service  = "http://traefik.kube-system.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.prod_k3s.awx_host
      }
    },
    {
      hostname = local.cf.prod_k3s.flux_webhook_host
      service  = "http://traefik.kube-system.svc.cluster.local"
      origin_request = {
        origin_server_name = local.cf.prod_k3s.flux_webhook_host
      }
    },
    { service = "http_status:404" }, # catch-all, must stay last
  ]
}
