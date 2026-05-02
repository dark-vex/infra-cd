locals {
  onepassword_vault = "66qfxcmgwlhutunx6slav6fyve"
}

data "onepassword_item" "netbox" {
  vault = local.onepassword_vault
  # Create a Login item in 1Password:
  #   - Website/URL field : https://<your-netbox-fqdn>  (drives server_url)
  #   - Password field    : your NetBox API token        (drives api_token)
  # Then replace this placeholder with the item UUID from the vault.
  uuid = "TODO_REPLACE_WITH_1PASSWORD_ITEM_UUID"
}
