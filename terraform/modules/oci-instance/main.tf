resource "oci_core_instance" "this" {
  display_name        = var.display_name
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = var.assign_public_ip
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  freeform_tags = var.freeform_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [metadata, source_details[0].source_id]
  }
}
