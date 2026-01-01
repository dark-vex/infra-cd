# Cloudflare Tunnel Terraform Module

This module manages the Cloudflare tunnel configuration for the kubenuc cluster.

## Features

- Manages Cloudflare tunnel resource
- Configures tunnel ingress rules to route traffic to HAProxy ingress controller
- Creates DNS CNAME records for tunnel endpoints
- Supports importing existing tunnels

## Usage

### Initial Import

If you have an existing Cloudflare tunnel, import it first:

```bash
# Get your tunnel ID from Cloudflare dashboard or CLI
# cloudflared tunnel list

terraform import cloudflare_tunnel.kubenuc <account_id>/<tunnel_id>
```

### Apply Configuration

```bash
terraform init
terraform plan
terraform apply
```

## Variables

- `cloudflare_account_id`: Your Cloudflare account ID
- `cloudflare_api_token`: API token with Tunnel and DNS edit permissions
- `ddlns_net_zone_id`: Zone ID for the ddlns.net domain
- `tunnel_secret`: Base64-encoded tunnel secret (from credentials.json)
- `tunnel_hostnames`: List of hostnames to route through the tunnel (default: harbor, jenkins, tv, portainer, sso, unifi)

## Outputs

- `tunnel_id`: The Cloudflare tunnel ID
- `tunnel_cname`: The CNAME target for DNS records
- `tunnel_endpoints`: Map of configured endpoint hostnames

## Notes

- The tunnel routes all `*.ddlns.net` traffic to the HAProxy ingress controller
- The HAProxy ingress controller should be deployed in the `haproxy-ingress` namespace
- Ensure the service name matches your HAProxy ingress service: `haproxy-ingress-kubernetes-ingress`
