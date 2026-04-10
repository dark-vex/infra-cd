output "id" {
  description = "ID of the Hetzner Cloud server"
  value       = hcloud_server.this.id
}

output "name" {
  description = "Name of the Hetzner Cloud server"
  value       = hcloud_server.this.name
}

output "ipv4_address" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.this.ipv4_address
}

output "ipv6_address" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.this.ipv6_address
}

output "status" {
  description = "Status of the server (e.g. running)"
  value       = hcloud_server.this.status
}
