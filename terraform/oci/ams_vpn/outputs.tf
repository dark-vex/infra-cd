output "instance_id" {
  value     = module.ams_vpn.id
  sensitive = true
}

output "public_ip" {
  value     = module.ams_vpn.public_ip
  sensitive = true
}

output "private_ip" {
  value     = module.ams_vpn.private_ip
  sensitive = true
}

output "display_name" {
  value     = module.ams_vpn.display_name
  sensitive = true
}
