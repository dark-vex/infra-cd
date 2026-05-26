# OCI k8s-armchair — ARM/Ampere compute instances
#
# To import existing instances, use declarative import blocks (Terraform 1.5+):
#
# import {
#   id = "ocid1.instance.oc1.<region>.<instance-ocid>"
#   to = module.k8s_arm.oci_core_instance.this
# }
#
# Run 'terraform plan' after adding the import block to preview the import,
# then 'terraform apply' to record the state.
#
# Fill in instance details once OCID values are available.

import {
  id = "ocid1.instance.oc1.eu-zurich-1.an5heljrxdml2yach7ezdszns3toa7tm7asoo7ta7askp2lm553hbtvxsdpa"
  to = module.test_vpn.oci_core_instance.this
}
