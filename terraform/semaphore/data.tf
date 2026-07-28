data "onepassword_item" "semaphore" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "43o3n6g5kkgxtgiof3xbeo4lgu"
}

# Dedicated webhook front-door secret (Design §3's HMAC gate on
# semaphoreui_project_integration) — deliberately a separate item from
# `semaphore` above, never the Semaphore admin API token. Same vault.
data "onepassword_item" "selfreg_webhook_secret" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "gdbvp6yfyzouv5hmf7mbamvrky"
}
