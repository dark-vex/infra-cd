# OCI API credentials stored in 1Password
# Fields in the "OCI API Key" item (vault 66qfxcmgwlhutunx6slav6fyve):
#   username    — tenancy OCID
#   password    — user OCID
#   hostname    — API key fingerprint
#   private_key — RSA PKCS#1 PEM private key
data "onepassword_item" "oci_credentials" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "OCI API Key"
}
