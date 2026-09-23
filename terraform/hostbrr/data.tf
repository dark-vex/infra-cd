data "onepassword_item" "hostbrr_api" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  title = "Hostbrr API - Terraform"
}

locals {
  # "url" sits in an unlabeled section ({"id": "add more"}, no label set) —
  # iterate section fields by label rather than section_map, which needs a
  # real section label. Same pattern as terraform/oci/test_vpn/data.tf.
  _hostbrr_fields  = { for f in tolist(flatten([for s in data.onepassword_item.hostbrr_api.section : tolist(s.field)])) : f.label => f.value }
  hostbrr_endpoint = local._hostbrr_fields["url"]
}
