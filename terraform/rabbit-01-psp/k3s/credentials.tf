resource "random_password" "k3s_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "k3s_password" {
  value     = random_password.k3s_password.result
  sensitive = true
}

output "k3s_private_key" {
  value     = tls_private_key.k3s_key.private_key_pem
  sensitive = true
}

output "k3s_public_key" {
  value = tls_private_key.k3s_key.public_key_openssh
}
