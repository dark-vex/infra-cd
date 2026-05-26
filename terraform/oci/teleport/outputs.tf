output "instance_id" {
  value = module.teleport.id
  sensitive = true
}

output "public_ip" {
  value = module.teleport.public_ip
  sensitive = true
}

output "private_ip" {
  value = module.teleport.private_ip
  sensitive = true
}

output "display_name" {
  value = module.teleport.display_name
  sensitive = true
}
