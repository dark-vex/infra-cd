# Tailscale VPN configuration — ACLs, DNS nameservers, auth keys
#
# To import existing ACL configuration:
#
# import {
#   id = "<tailnet>"
#   to = tailscale_acl.main
# }
#
# Useful Tailscale Terraform resources:
#   tailscale_acl        — ACL policy (HuJSON format)
#   tailscale_dns_nameservers    — Global DNS nameservers
#   tailscale_dns_split_nameservers — Split DNS per domain
#   tailscale_dns_preferences    — MagicDNS enable/disable
#   tailscale_tailnet_key        — Auth keys for device enrollment
#
# Reference: https://registry.terraform.io/providers/tailscale/tailscale/latest/docs
#
# Note: The Portainer Tailscale sidecar (clusters/kubenuc/apps/portainer/)
# uses a separate auth key managed via a 1Password-backed Kubernetes secret
# (clusters/kubenuc/apps/portainer/secrets/tailscale-auth.yml).
# That key can be managed here and synced back to 1Password.
