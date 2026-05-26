provider "oci" {
  tenancy_ocid = local.oci_tenancy_id
  user_ocid    = local.oci_user_id
  fingerprint  = local.oci_fingerprint
  private_key  = data.onepassword_item.oci_credentials.private_key
  region       = var.region
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
