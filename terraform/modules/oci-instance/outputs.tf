output "id" {
  description = "OCID of the instance"
  value       = oci_core_instance.this.id
}

output "public_ip" {
  description = "Public IP address of the instance (if assigned)"
  value       = oci_core_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.this.private_ip
}

output "display_name" {
  description = "Display name of the instance"
  value       = oci_core_instance.this.display_name
}
