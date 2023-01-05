#resource "libvirt_network" "awx-manage" {
# (resource arguments)
#  name = "awx-manage"
#  domain = "awx-manage"
#  mode = "bridge"
#  bridge = "virbr3"
#  autostart = true
#  addresses = [ "0.0.0.0/0" ]
#}

#resource "libvirt_network" "default" {
# # (resource arguments)
# name = "default"
# mode = "nat"
#}

resource "libvirt_network" "terraform-test" {
  # (resource arguments)
  name = "terraform-test"
  mode = "bridge"
  bridge = "terraformbr"
}
