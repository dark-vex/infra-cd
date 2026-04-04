data "onepassword_item" "gozzi_01_bio_token" {
  vault = "66qfxcmgwlhutunx6slav6fyve"
  uuid  = "mfukjucb7uuljtldpncj3erlz4"
}

data "external" "gozzi_01_bio_token" {
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
