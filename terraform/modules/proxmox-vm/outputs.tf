output "id" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.this.id
}

output "vmid" {
  description = "VM numeric ID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4_addresses" {
  description = "IPv4 addresses assigned to the VM"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "ipv6_addresses" {
  description = "IPv6 addresses assigned to the VM"
  value       = proxmox_virtual_environment_vm.this.ipv6_addresses
}

output "mac_addresses" {
  description = "MAC addresses of network interfaces"
  value       = proxmox_virtual_environment_vm.this.mac_addresses
}

output "network_interface_names" {
  description = "Network interface names"
  value       = proxmox_virtual_environment_vm.this.network_interface_names
}
