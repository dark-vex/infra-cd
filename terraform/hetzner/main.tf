# data "external" "login_in_one_password" {
#   program = ["${path.cwd}/setup.sh"]
#   program = ["./setup.sh"]
# }

data "onepassword_item" "hcloud_token" {
  vault  = "66qfxcmgwlhutunx6slav6fyve"
  uuid   = "fog2zbfwo4r7ag5mgu5jftz7j4"
}

data "onepassword_item" "hcloud_hostname" {
  vault  = "66qfxcmgwlhutunx6slav6fyve"
  uuid   = "m4dsdf2ndph7m67czape24qscy"
}

# Create a server
resource "hcloud_server" "mail" {

  name        = data.onepassword_item.hcloud_hostname.username

  server_type = "cx21"
  image       = "debian-10"

  location    = "nbg1"
  datacenter  = "nbg1-dc3"

  backups     = true

  delete_protection = true
  rebuild_protection = true

}

# Create a new SSH key
resource "hcloud_ssh_key" "default" {
  name       = "daniele"
  public_key = file("~/.ssh/id_rsa.pub")
}