output "instance_id" {
  value = module.k8s_arm.id
}

output "public_ip" {
  value = module.k8s_arm.public_ip
}

output "private_ip" {
  value = module.k8s_arm.private_ip
}

output "display_name" {
  value = module.k8s_arm.display_name
}
