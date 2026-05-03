# Import blocks for Cloudflare records that exist in Cloudflare but not yet in Terraform state.
#
# The 7 records that were previously in state (harbor, jenkins, notary_harbor, arl_fail,
# arl_fail_www, arlo_fail, arlo_fail_www) are handled by the `moved` blocks in main.tf
# and do NOT need import blocks here.
#
# For every additional record in Cloudflare, add an import block below.
# Record ID format: "{zone_id}/{record_id}"
#
# To list all record IDs for a zone:
#   curl -s "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records?per_page=100" \
#        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
#        | jq -r '.result[] | "\(.name) \(.type) \(.id)"'
#
# Example import block (uncomment and fill in real record IDs):
#
# import {
#   to = module.ddlns_net.cloudflare_record.this["my_record_key"]
#   id = "${local.dns.zones.ddlns_net.id}/CLOUDFLARE_RECORD_ID"
# }
#
# The key ("my_record_key") must match the corresponding key in secrets.sops.yaml under
# zones.ddlns_net.records.
#
# Repeat for each zone and each record not yet in state.
