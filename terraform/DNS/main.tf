module "ddlns_net" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.ddlns_net_zone_id
  records = {
    harbor = {
      name    = "harbor"
      type    = "A"
      value   = local.hm_ip
      proxied = true
    }
    jenkins = {
      name  = "jenkins"
      type  = "A"
      value = local.khnuc_ip
    }
    notary_harbor = {
      name  = "notary.harbor"
      type  = "A"
      value = local.khnuc_ip
    }
  }
}

module "arl_fail" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.arl_fail_zone_id
  records = {
    root = {
      name    = "arl.fail"
      type    = "A"
      value   = local.eu_aws_free_ip
      proxied = true
    }
    www = {
      name    = "www"
      type    = "CNAME"
      value   = "arl.fail"
      proxied = true
    }
  }
}

module "arlo_fail" {
  source  = "../modules/cloudflare-dns"
  zone_id = local.arlo_fail_zone_id
  records = {
    root = {
      name    = "arlo.fail"
      type    = "A"
      value   = local.eu_aws_free_ip
      proxied = true
    }
    www = {
      name    = "www"
      type    = "CNAME"
      value   = "arlo.fail"
      proxied = true
    }
  }
}

moved {
  from = cloudflare_record.harbor
  to   = module.ddlns_net.cloudflare_record.this["harbor"]
}

moved {
  from = cloudflare_record.jenkins
  to   = module.ddlns_net.cloudflare_record.this["jenkins"]
}

moved {
  from = cloudflare_record.notary_harbor
  to   = module.ddlns_net.cloudflare_record.this["notary_harbor"]
}

moved {
  from = cloudflare_record.arl_fail
  to   = module.arl_fail.cloudflare_record.this["root"]
}

moved {
  from = cloudflare_record.arl_fail_www
  to   = module.arl_fail.cloudflare_record.this["www"]
}

moved {
  from = cloudflare_record.arlo_fail
  to   = module.arlo_fail.cloudflare_record.this["root"]
}

moved {
  from = cloudflare_record.arlo_fail_www
  to   = module.arlo_fail.cloudflare_record.this["www"]
}
