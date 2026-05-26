# OCI API credentials stored in 1Password
# Required fields in the 1Password item:
#   username    — tenancy OCID (custom field, no purpose set)
#   password    — user OCID (custom field, no purpose set)
#   hostname    — API key fingerprint (custom field, no purpose set)
#   api_key_pem — RSA PKCS#1 PEM private key (custom text field; SSH_KEY native field returns OpenSSH format which OCI rejects)
data "onepassword_item" "oci_credentials" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "OCI API Key"
}

# The item is category SSH_KEY; custom fields have no purpose set, so .username/.password/.hostname
# return empty strings. Extract them by label from the synthetic unsectioned fields map instead.
locals {
  _oci_fields     = { for f in flatten([for s in data.onepassword_item.oci_credentials.section : s.field]) : f.label => f.value }
  oci_tenancy_id  = local._oci_fields["username"]
  oci_user_id     = local._oci_fields["password"]
  oci_fingerprint = local._oci_fields["hostname"]
  # OCI requires RSA PKCS#1 PEM format; the SSH_KEY native private_key field returns OpenSSH format
  # which OCI cannot verify. Store the converted RSA PEM key in a separate custom field.
  oci_private_key = local._oci_fields["api_key_pem"]
}
