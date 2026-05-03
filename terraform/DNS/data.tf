data "sops_file" "dns" {
  source_file = "secrets.sops.yaml"
}

locals {
  dns = yamldecode(data.sops_file.dns.raw)
}
