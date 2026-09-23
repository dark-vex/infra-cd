import {
  id = "385e8f86-6cc8-4f88-8d1e-a8fece0f6b32"
  to = virtfusion_server.rmon_vpn
}

resource "virtfusion_server" "rmon_vpn" {
  lifecycle {
    prevent_destroy = true
  }
}
