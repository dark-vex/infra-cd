output "record_ids" {
  description = "Map of record keys to their Cloudflare record IDs"
  value       = { for k, v in cloudflare_record.this : k => v.id }
}

output "record_hostnames" {
  description = "Map of record keys to their hostnames"
  value       = { for k, v in cloudflare_record.this : k => v.hostname }
}
