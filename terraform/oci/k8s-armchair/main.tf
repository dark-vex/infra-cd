import {
  id = "ocid1.instance.oc1.eu-zurich-1.an5heljrxdml2yacbfz7fk43a5r5qztl6zgs2r2tbxuweqvfuv6i7gfguoza"
  to = module.k8s_arm.oci_core_instance.this
}

module "k8s_arm" {
  source = "../../modules/oci-instance"

  display_name            = "kubearm"
  compartment_id          = "ocid1.tenancy.oc1..aaaaaaaasrglptvtkvxq73or3lg5oiupdcnuqtc3ewrwly6s4lfreeiolu4q"
  availability_domain     = "lxSl:EU-ZURICH-1-AD-1"
  shape                   = "VM.Standard.A1.Flex"
  ocpus                   = 4
  memory_in_gbs           = 24
  image_id                = "ocid1.image.oc1.eu-zurich-1.aaaaaaaaf5crw5yxscwdgxkb6qhnyaumknz6q5fcptu5yac57gtiwqjlkxpq"
  boot_volume_size_in_gbs = 50
  subnet_id               = "ocid1.subnet.oc1.eu-zurich-1.aaaaaaaahr2pbvptcqofsx6gq3qyq5mdmtmn74lt67ymkis73xxhuopg7kqa"
  assign_public_ip        = true
  ssh_authorized_keys     = data.onepassword_item.oci_credentials.note_value
}
