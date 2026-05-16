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
