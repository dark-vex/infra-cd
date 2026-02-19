output "id" {
  description = "Container ID"
  value       = proxmox_virtual_environment_container.this.id
}

output "vmid" {
  description = "Container numeric ID"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "hostname" {
  description = "Container hostname"
  value       = proxmox_virtual_environment_container.this.initialization[0].hostname
}

output "ipv4_addresses" {
  description = "IPv4 addresses assigned to the container"
  value       = proxmox_virtual_environment_container.this.ipv4
}

output "ipv6_addresses" {
  description = "IPv6 addresses assigned to the container"
  value       = proxmox_virtual_environment_container.this.ipv6
}
