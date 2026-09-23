# CODE-29: dark-vex/terraform-proxmox-vm hardcodes prevent_destroy = true
# unconditionally, so a plain block deletion would fail. destroy = false
# tells Terraform to forget the resource without attempting to destroy it -
# the actual VM is deleted separately, out of band.
removed {
  from = module.hpelvisor_virtfusion_vm.proxmox_virtual_environment_vm.this

  lifecycle {
    destroy = false
  }
}
