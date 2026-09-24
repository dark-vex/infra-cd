removed {
  from = module.hpelvisor_virtfusion_vm.proxmox_virtual_environment_vm.this

  lifecycle {
    destroy = true
  }
}
