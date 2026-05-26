output "instance_id" {
  value = module.k8s_arm.id
  sensitive = true
}

output "public_ip" {
  value = module.k8s_arm.public_ip
  sensitive = true
}

output "private_ip" {
  value = module.k8s_arm.private_ip
  sensitive = true
}

output "display_name" {
  value = module.k8s_arm.display_name
  sensitive = true
}
