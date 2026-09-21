# data "external" "login_in_one_password" {
#   program = ["${path.cwd}/setup.sh"]
#   program = ["./setup.sh"]
# }

data "onepassword_item" "hcloud_token" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "fog2zbfwo4r7ag5mgu5jftz7j4"
}

data "onepassword_item" "hcloud_hostname" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "m4dsdf2ndph7m67czape24qscy"
}

module "mail" {
  source = "github.com/dark-vex/terraform-hetzner-server?ref=6969586f42fe72d118d1299b9f62883b7ac8e86c" # v1.0.0

  name        = data.onepassword_item.hcloud_hostname.username
  server_type = "cx23"
  # CODE-28: this is the server's creation-time image only - hcloud_server's
  # `image` is ForceNew in the provider schema and is never diffed against
  # the live OS, so an in-place OS upgrade (apt dist-upgrade across major
  # releases) produces zero Terraform drift and this value silently goes
  # stale. Confirmed live 2026-09-21: the real running OS is Debian 12
  # (bookworm), not debian-10 (buster, EOL). Do NOT "fix" this by changing
  # it to "debian-12" - that would plan a full destroy-and-recreate of this
  # live production mailserver, not an in-place update (delete_protection
  # would likely fail the apply partway through rather than silently
  # succeed, but it's not a safe edit either way). Update this comment
  # (not the value) whenever the live OS is next checked.
  image    = "debian-10"
  location = "nbg1"
  backups  = true

  delete_protection  = true
  rebuild_protection = true
}

moved {
  from = hcloud_server.mail
  to   = module.mail.hcloud_server.this
}

# Create a new SSH key
resource "hcloud_ssh_key" "default" {
  name       = "daniele"
  public_key = file("~/.ssh/id_rsa.pub")
}
