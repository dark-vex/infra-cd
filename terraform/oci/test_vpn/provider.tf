provider "oci" {
  tenancy_ocid     = data.onepassword_item.oci_credentials.username
  user_ocid        = data.onepassword_item.oci_credentials.password
  fingerprint      = data.onepassword_item.oci_credentials.hostname
  private_key      = data.onepassword_item.oci_credentials.private_key
  region           = var.region
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
