#resource "tls_private_key" "deploy_key" {
#  algorithm = "RSA"
#  rsa_bits  = 2048
#}
#
#output "deploy_private_key" {
#  value     = tls_private_key.deploy_key.private_key_pem
#  sensitive = true
#}
#
#output "deploy_public_key" {
#  value = tls_private_key.deploy_key.public_key_openssh
#}
