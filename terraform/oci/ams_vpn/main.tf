import {
  id = "ocid1.instance.oc1.eu-amsterdam-1.anqw2ljr2l2v7tac43tgjxw76nw2pyxg3762w53ivj4cntkha63rdt3u7iqa"
  to = module.ams_vpn.oci_core_instance.this
}

module "ams_vpn" {
  source = "../../modules/oci-instance"

  display_name            = local.ams_vpn_secrets.instance.display_name
  compartment_id          = "ocid1.tenancy.oc1..aaaaaaaabbv4xzqavnyftknwz5pkjzhkgcpwxlcc64oadqe33a6a6kqwj36q"
  availability_domain     = "nXZM:eu-amsterdam-1-AD-1"
  shape                   = "VM.Standard.E2.1.Micro"
  ocpus                   = 1
  memory_in_gbs           = 1
  image_id                = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaa6zlknqbu3a2c53zcobpm4laxxxn5toy5dc3fltmvbmpfjwlw4k5a"
  boot_volume_size_in_gbs = 50
  subnet_id               = "ocid1.subnet.oc1.eu-amsterdam-1.aaaaaaaazm5f7ghsrlxjrgrw27v6hzbr4gzt2yw26oi24yc2vov4evulymyq"
  assign_public_ip        = true
  freeform_tags           = {}
  ssh_authorized_keys     = data.onepassword_item.oci_ams_credentials.note_value
}
