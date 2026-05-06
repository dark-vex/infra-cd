resource "cloudflare_dns_record" "this" {
  for_each = nonsensitive(var.records)

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.data == null ? each.value.content : null
  proxied  = each.value.proxied
  priority = each.value.priority
  ttl      = each.value.ttl
  comment  = each.value.comment
  data     = each.value.data

  lifecycle {
    ignore_changes = [ zone_id ]
  }
}
