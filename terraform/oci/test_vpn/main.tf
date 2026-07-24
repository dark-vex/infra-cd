import {
  id = "ocid1.instance.oc1.eu-zurich-1.an5heljrxdml2yach7ezdszns3toa7tm7asoo7ta7askp2lm553hbtvxsdpa"
  to = module.test_vpn.oci_core_instance.this
}

module "test_vpn" {
  source = "../../modules/oci-instance"

  display_name            = "test.vpn.ddlns.net"
  compartment_id          = "ocid1.tenancy.oc1..aaaaaaaasrglptvtkvxq73or3lg5oiupdcnuqtc3ewrwly6s4lfreeiolu4q"
  availability_domain     = "lxSl:EU-ZURICH-1-AD-1"
  shape                   = "VM.Standard.E2.1.Micro"
  ocpus                   = 1
  memory_in_gbs           = 1
  image_id                = "ocid1.image.oc1.eu-zurich-1.aaaaaaaa4j6jzppcn6xdszgucsnexzkj6hfpgswgcen7m5y7ozf4y2cwecoq"
  boot_volume_size_in_gbs = 47
  subnet_id               = "ocid1.subnet.oc1.eu-zurich-1.aaaaaaaahr2pbvptcqofsx6gq3qyq5mdmtmn74lt67ymkis73xxhuopg7kqa"
  assign_public_ip        = true
  ssh_authorized_keys     = data.onepassword_item.oci_credentials.note_value
}
