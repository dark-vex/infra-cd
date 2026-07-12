data "sops_file" "cloudflare_tunnel" {
  source_file = "secrets.sops.yaml"
}

locals {
  cf = yamldecode(data.sops_file.cloudflare_tunnel.raw)
}
