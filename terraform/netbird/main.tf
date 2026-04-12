# Netbird VPN configuration — networks, groups, policies, routes, DNS
#
# Start by importing existing configuration:
#
# import {
#   id = "<group-id>"
#   to = netbird_group.example
# }
#
# Useful Netbird Terraform resources:
#   netbird_group       — peer groups for policy targeting
#   netbird_policy      — access control policies between groups
#   netbird_route       — network routes distributed to peers
#   netbird_dns         — DNS nameserver configurations
#   netbird_setup_key   — setup keys for enrolling new peers
#
# Reference: https://registry.terraform.io/providers/netbirdio/netbird/latest/docs
