data "onepassword_item" "rabbit_01_psp_token" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "h7fhsftvpum7r4b3rnqznz4lym"
}

data "external" "rabbit_01_psp_token" {
  program = ["${path.module}/setup.sh"]
}

data "onepassword_item" "ssh_key" {
    uuid     = "fg6utxhi7yzuxmheo3a4dpqcaq"
    vault    = "66qfxcmgwlhutunx6slav6fyve"
}

data "onepassword_item" "ssh_key_new" {
    uuid     = "duivcbljdj4nufcxr6wgwcnsrq"
    vault    = "66qfxcmgwlhutunx6slav6fyve"
}
