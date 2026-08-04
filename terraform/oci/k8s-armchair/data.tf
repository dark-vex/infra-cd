data "onepassword_item" "oci_credentials" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "OCI API Key"
}

locals {
  # Purpose-based accessors (.username/.password/.hostname) return "" for
  # fields in sections without a purpose set; iterate section fields by label.
  _oci_fields     = { for f in tolist(flatten([for s in data.onepassword_item.oci_credentials.section : tolist(s.field)])) : f.label => f.value }
  oci_tenancy_id  = local._oci_fields["username"]
  oci_user_id     = local._oci_fields["password"]
  oci_fingerprint = local._oci_fields["hostname"]
  oci_private_key = local._oci_fields["api_key_pem"]
}
