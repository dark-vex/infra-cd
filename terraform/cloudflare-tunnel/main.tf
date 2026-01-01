terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Import existing Cloudflare tunnel
# To import: terraform import cloudflare_tunnel.kubenuc <account_id>/<tunnel_id>
resource "cloudflare_tunnel" "kubenuc" {
  account_id = var.cloudflare_account_id
  name       = "kubenuc"
  secret     = var.tunnel_secret
}

# Tunnel configuration
resource "cloudflare_tunnel_config" "kubenuc" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.kubenuc.id

  config {
    ingress_rule {
      hostname = "*.ddlns.net"
      service  = "https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443"

      origin_request {
        origin_server_name = "ddlns.net"
      }
    }

    # Catch-all rule (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# DNS records for tunnel endpoints
resource "cloudflare_record" "tunnel_endpoints" {
  for_each = toset(var.tunnel_hostnames)

  zone_id = var.ddlns_net_zone_id
  name    = each.value
  value   = "${cloudflare_tunnel.kubenuc.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
