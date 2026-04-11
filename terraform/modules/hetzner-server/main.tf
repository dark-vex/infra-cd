resource "hcloud_server" "this" {
  name        = var.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  backups     = var.backups

  delete_protection  = var.delete_protection
  rebuild_protection = var.rebuild_protection

  ssh_keys = var.ssh_key_ids

  labels = var.labels

  lifecycle {
    prevent_destroy = true
  }
}
