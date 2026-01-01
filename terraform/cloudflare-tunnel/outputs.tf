output "tunnel_id" {
  description = "Cloudflare tunnel ID"
  value       = cloudflare_tunnel.kubenuc.id
}

output "tunnel_cname" {
  description = "Cloudflare tunnel CNAME target"
  value       = "${cloudflare_tunnel.kubenuc.id}.cfargotunnel.com"
}

output "tunnel_endpoints" {
  description = "Map of tunnel endpoint hostnames"
  value       = { for record in cloudflare_record.tunnel_endpoints : record.name => record.value }
}
