data "onepassword_item" "rabbit_01_psp_token" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "h7fhsftvpum7r4b3rnqznz4lym"
}

data "external" "rabbit_01_psp_token_otp" {
  program = [ "${path.module}/setup.sh" ]
}
