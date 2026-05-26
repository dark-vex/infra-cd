output "instance_id" {
  value = module.test_vpn.id
  sensitive = true
}

output "public_ip" {
  value = module.test_vpn.public_ip
  sensitive = true
}

output "private_ip" {
  value = module.test_vpn.private_ip
  sensitive = true
}

output "display_name" {
  value = module.test_vpn.display_name
  sensitive = true
}
