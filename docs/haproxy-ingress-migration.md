# HAProxy Ingress Migration Guide

This document outlines the migration from nginx-ingress to haproxy-ingress for the kubenuc Kubernetes cluster.

## Overview

The migration involves:
1. Deploying HAProxy ingress controller alongside nginx-ingress
2. Updating Cloudflare tunnel to route traffic to HAProxy ingress
3. Migrating all application ingress resources to use HAProxy
4. Testing all ingresses with RobotFramework
5. Decommissioning nginx-ingress controller

## Prerequisites

- FluxCD installed and configured
- Cloudflare tunnel credentials (for tunnel configuration)
- Better Uptime API token (for maintenance mode management)
- kubectl access to kubenuc cluster

## Migration Steps

### Step 1: Enable Better Uptime Maintenance Mode

Before starting the migration, enable maintenance mode to prevent false alerts:

```bash
export BETTERUPTIME_API_TOKEN="your_token_here"
./scripts/betteruptime-maintenance.sh enable
```

### Step 2: Deploy HAProxy Ingress Controller

The HAProxy ingress controller is deployed via FluxCD:

```bash
# Verify the deployment
kubectl get kustomization -n flux-system haproxy-ingress

# Check HAProxy ingress controller pods
kubectl get pods -n haproxy-ingress

# Verify the service is created
kubectl get svc -n haproxy-ingress
```

Expected service name: `haproxy-ingress-kubernetes-ingress`

### Step 3: Update Cloudflare Tunnel Configuration

The Cloudflare tunnel configuration has been updated to route traffic to HAProxy ingress:

**File**: `clusters/kubenuc/apps/cloudflare/manifests/cloudflared.yml`

The tunnel now routes `*.ddlns.net` traffic to:
```
https://haproxy-ingress-kubernetes-ingress.haproxy-ingress.svc.cluster.local:443
```

Wait for the cloudflared pods to restart and pick up the new configuration:

```bash
kubectl rollout status daemonset/cloudflared -n cloudflare
```

### Step 4: Verify Application Ingresses

All application ingress resources have been updated to use `ingressClassName: haproxy`:

- **harbor**: Container registry
- **jenkins**: CI/CD server
- **jellyfin**: Media server (tv.ddlns.net)
- **portainer**: Container management
- **sso**: Authentication (Authentik)
- **unifi**: Network controller (commented out)

Check that ingresses are created with the correct class:

```bash
kubectl get ingress -A | grep haproxy
```

### Step 5: Test All Ingresses

Run the RobotFramework test suite to verify all ingresses are working:

```bash
cd tests/robot
robot ingress_tests.robot
```

The tests will:
- Discover all ingresses in the cluster
- Send HTTP requests to each ingress endpoint
- Verify HTTP status codes (200-399)
- Take screenshots of each successfully loaded page
- Save screenshots to `tests/robot/screenshots/`

### Step 6: Monitor and Verify

Monitor the HAProxy ingress controller:

```bash
# Check controller logs
kubectl logs -n haproxy-ingress -l app.kubernetes.io/name=kubernetes-ingress --tail=100

# Check metrics (if enabled)
kubectl port-forward -n haproxy-ingress svc/haproxy-ingress-kubernetes-ingress 1024:1024
# Access stats at http://localhost:1024/stats
```

### Step 7: Disable Better Uptime Maintenance Mode

Once verified, disable maintenance mode:

```bash
./scripts/betteruptime-maintenance.sh disable
```

### Step 8: Remove nginx-ingress (Optional)

After confirming HAProxy ingress is working correctly for at least 24-48 hours:

```bash
# Suspend the nginx-ingress Kustomization
flux suspend kustomization nginx-ingress -n flux-system

# Delete the nginx-ingress resources
kubectl delete kustomization nginx-ingress -n flux-system

# Remove the nginx-ingress app directory
rm -rf clusters/kubenuc/apps/nginx-ingress/
```

## HAProxy vs Nginx Annotation Mapping

| Nginx Annotation | HAProxy Annotation | Notes |
|-----------------|-------------------|-------|
| `nginx.ingress.kubernetes.io/ssl-redirect` | `haproxy.org/ssl-redirect` | Force HTTPS redirect |
| `nginx.ingress.kubernetes.io/client-max-body-size` | `haproxy.org/request-body-size` | Max request body size |
| `nginx.ingress.kubernetes.io/proxy-body-size` | `haproxy.org/request-body-size` | Same as above |
| `nginx.ingress.kubernetes.io/backend-protocol` | `haproxy.org/backend-protocol` | Backend protocol (http/https) |
| `nginx.ingress.kubernetes.io/proxy-read-timeout` | `haproxy.org/timeout-server` | Server timeout (add 's' suffix) |
| `nginx.ingress.kubernetes.io/whitelist-source-range` | `haproxy.org/whitelist` | IP whitelist |

## Terraform Module for Cloudflare Tunnel

A Terraform module has been created to manage the Cloudflare tunnel configuration:

**Location**: `terraform/cloudflare-tunnel/`

### Usage

1. Set required variables in `terraform.tfvars`:
```hcl
cloudflare_account_id = "your_account_id"
cloudflare_api_token  = "your_api_token"
ddlns_net_zone_id     = "your_zone_id"
tunnel_secret         = "base64_encoded_secret"
```

2. Import existing tunnel:
```bash
cd terraform/cloudflare-tunnel
terraform init
terraform import cloudflare_tunnel.kubenuc <account_id>/<tunnel_id>
```

3. Apply configuration:
```bash
terraform plan
terraform apply
```

## Rollback Procedure

If issues occur, rollback to nginx-ingress:

1. Revert Cloudflare tunnel configuration:
```bash
git revert <commit-hash>
kubectl apply -f clusters/kubenuc/apps/cloudflare/manifests/cloudflared.yml
```

2. Revert application ingress resources:
```bash
git revert <commit-hash>
flux reconcile kustomization --with-source flux-system
```

3. Suspend HAProxy ingress:
```bash
flux suspend kustomization haproxy-ingress -n flux-system
```

## Troubleshooting

### Ingress not accessible

1. Check HAProxy ingress controller logs:
```bash
kubectl logs -n haproxy-ingress -l app.kubernetes.io/name=kubernetes-ingress
```

2. Verify ingress resource:
```bash
kubectl describe ingress <ingress-name> -n <namespace>
```

3. Check Cloudflare tunnel status:
```bash
kubectl logs -n cloudflare -l app=cloudflared
```

### Certificate issues

Ensure cert-manager is running and issuing certificates:
```bash
kubectl get certificates -A
kubectl describe certificate <cert-name> -n <namespace>
```

### TCP/UDP services not working

HAProxy ingress controller is configured to expose:
- TCP port 50000 → jenkins/jenkins-agent:50000 (Jenkins agents)
- UDP port 3478 → unifi/unifi:3478 (UniFi STUN)

Verify the configuration in `clusters/kubenuc/apps/haproxy-ingress/manifests/release.yml`

## References

- [HAProxy Ingress Documentation](https://haproxy-ingress.github.io/)
- [HAProxy Kubernetes Ingress Controller](https://github.com/haproxytech/kubernetes-ingress)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Better Uptime API](https://betterstack.com/docs/uptime/api/)

## Post-Migration Checklist

- [ ] All ingresses accessible via browser
- [ ] HTTPS certificates valid
- [ ] Jenkins agents can connect (TCP 50000)
- [ ] UniFi STUN working (UDP 3478)
- [ ] RobotFramework tests passing
- [ ] Screenshots generated successfully
- [ ] Better Uptime monitors active (maintenance mode disabled)
- [ ] Prometheus metrics accessible (if enabled)
- [ ] No errors in HAProxy ingress controller logs
- [ ] Cloudflare tunnel healthy
