# OCI API credentials stored in 1Password
# Required fields in the 1Password item:
#   username    — tenancy OCID
#   password    — user OCID
#   hostname    — API key fingerprint
#   private_key — PEM-encoded API private key (section field)
data "onepassword_item" "oci_credentials" {
  vault = "infra"
  title = "OCI k8s-armchair API Key"
}
