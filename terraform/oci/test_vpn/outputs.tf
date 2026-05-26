output "instance_id" {
  value = module.test_vpn.id
}

output "public_ip" {
  value = module.test_vpn.public_ip
}

output "private_ip" {
  value = module.test_vpn.private_ip
}

output "display_name" {
  value = module.test_vpn.display_name
}
