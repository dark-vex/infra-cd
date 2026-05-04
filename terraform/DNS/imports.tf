# Terraform import blocks for all Cloudflare DNS records.
# Generated from live Cloudflare API data.
#
# Records handled by `moved` blocks in main.tf (harbor, jenkins, notary_harbor in ddlns_net)
# are NOT listed here — their state is migrated from flat resources, not imported fresh.
#
# Before applying, if stale state entries exist for arl_fail/arlo_fail zones, remove them:
#   terraform state rm cloudflare_record.arl_fail cloudflare_record.arl_fail_www
#   terraform state rm cloudflare_record.arlo_fail cloudflare_record.arlo_fail_www

# ---------------------------------------------------------------------------
# bioadventures.eu
# ---------------------------------------------------------------------------

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["root_a"]
  id = "9a4766fdf5669fc93c9650978865467d/fb69e513244dd07af2dd9859a64cda10"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["cloud_a"]
  id = "9a4766fdf5669fc93c9650978865467d/aa1d7f1a40eed200b5bd0473636cc16f"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["crm_a"]
  id = "9a4766fdf5669fc93c9650978865467d/9dcb443bb5403ed8c9621a7855847055"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["docker_a"]
  id = "9a4766fdf5669fc93c9650978865467d/28856455ef713bec907862ebc38f843c"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["dolibarr_a"]
  id = "9a4766fdf5669fc93c9650978865467d/af5f0ce3b9878c63bbfc8e07ad9bd039"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["mail2_a"]
  id = "9a4766fdf5669fc93c9650978865467d/beb42708706580c95a0fa53b77c987f4"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["mail3_a"]
  id = "9a4766fdf5669fc93c9650978865467d/d4b729be765c443d751c912b66136ccb"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["vpn_a"]
  id = "9a4766fdf5669fc93c9650978865467d/7346fcbef342bc58fa15741a2dd14d47"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["em2903_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/0ea78b06b9f64b3fe3b2fdd6eee15957"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["em5704_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/69eaba8332a636658a5eeb9030e1b40f"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["imap_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/d15575bc596eeeff104b4ff96a909d29"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["mail1_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/16ca75e066b411a13d6bf552b424e439"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["mail_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/b0785260af804ce023cada230a8c88ce"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["s1_domainkey_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/dd91ba52339a60c8cfe538e2b088ff7a"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["s2_domainkey_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/e4e62602c65da03456e7b41c8024ccb4"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["smtp_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/e103b8d3ef1ba15c7a8376839e15e237"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["www_cname"]
  id = "9a4766fdf5669fc93c9650978865467d/7ffc2e0504865ea702429d9ae4cad46b"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["root_mx"]
  id = "9a4766fdf5669fc93c9650978865467d/1ac76300902a61741939b737e10e5dbf"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["root_mx_2"]
  id = "9a4766fdf5669fc93c9650978865467d/7f9a6cbd2321883bb9ff8dd8960ec868"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["root_mx_3"]
  id = "9a4766fdf5669fc93c9650978865467d/52248db37214e7dbbcaa73df017a5eb9"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["root_txt_spf"]
  id = "9a4766fdf5669fc93c9650978865467d/08ba5069e8248c3afbc3777d72651783"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["root_txt_google"]
  id = "9a4766fdf5669fc93c9650978865467d/7411cd0023d444b7984e8625858c7389"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["default_domainkey_txt"]
  id = "9a4766fdf5669fc93c9650978865467d/f1cd127c23b655f05348265a5052cfa6"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["dkim_domainkey_txt"]
  id = "9a4766fdf5669fc93c9650978865467d/70436ec30145bf04d36b632fd1684b36"
}

import {
  to = module.bioadventures_eu.cloudflare_dns_record.this["dmarc_txt"]
  id = "9a4766fdf5669fc93c9650978865467d/d9059be80ea5dae67669917cae3ada18"
}

# ---------------------------------------------------------------------------
# birrificiosottobisio.ch
# ---------------------------------------------------------------------------

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["root_a"]
  id = "0c29d1cb773230525bb0d094f10a1280/ec3134cd95b92650e2f98c3b321180a2"
}

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["mail_cname"]
  id = "0c29d1cb773230525bb0d094f10a1280/004c1745c72722e2b8e6592509aa065d"
}

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["www_cname"]
  id = "0c29d1cb773230525bb0d094f10a1280/b54925d0c4a6ebd26ce6c1dc50082e7f"
}

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["root_mx"]
  id = "0c29d1cb773230525bb0d094f10a1280/d88ebd24fd194982cbdfc19e45a4022b"
}

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["root_txt_spf"]
  id = "0c29d1cb773230525bb0d094f10a1280/3287794060f6ebbe28eb831957db9473"
}

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["default_domainkey_txt"]
  id = "0c29d1cb773230525bb0d094f10a1280/49bfd8478b7fc204bc2e9225ec3bdf2f"
}

import {
  to = module.birrificiosottobisio_ch.cloudflare_dns_record.this["dmarc_txt"]
  id = "0c29d1cb773230525bb0d094f10a1280/378ac1e41cbd118557356f8ba434d84b"
}

# ---------------------------------------------------------------------------
# ddlns.net  (harbor, jenkins, notary_harbor handled by moved blocks in main.tf)
# ---------------------------------------------------------------------------

import {
  to = module.ddlns_net.cloudflare_dns_record.this["api_int_ocp4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/0e9ed8b71d31d568046e3fda5e11e6c9"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["api_int_okd4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/9aacf86f452662629af8f20e39d289e4"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["api_ocp4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/24c99c5bad1cf29023f0a6e1ea991d1b"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["api_okd4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/9c1b7e80947735eeb6bdfa2ce1bc8d60"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wildcard_apps_ocp4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/0a0d632ae455427baace741e2aefccd6"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wildcard_apps_okd4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/7c7545aa2fd2d3517cb0689b149f21ac"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["argocd_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/8ee75fef9311e96288d4b6b5b276d85c"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["console_openshift_console_apps_ocp4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/ea1e23924681834b4b984a12002b401c"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["console_openshift_console_apps_okd4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/9d87bc1005cc135d0f84079088b15da4"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["dimensione_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/a943135bda1081211c357f4ebbda4ca1"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["fastweb_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/16665fc9bb70ca419884c4d7a4f3ba69"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["gatherer_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/a5240201cd105765cb881846fea69d5a"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["gatherer_a_2"]
  id = "dafa0a53a384eb00fda6edada1f25db3/cd4512f291c53f6ade48e757d4d2fbea"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["gatherer_a_3"]
  id = "dafa0a53a384eb00fda6edada1f25db3/371643d6d083f3f07fb98f455e49a2c2"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["graylog_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c45eee13ced78aa09aae7c6481ad9424"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["keep_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/e4135a71452f266a0fdeb7c9086fd89e"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["mediaserver_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/dd5a40b3dd489ed5085acea4c9ed29f7"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["nas_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/0ccac6d530450cc67c0e477d727a72a1"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["oauth_openshift_apps_ocp4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/11388746a67e9b57c2e7c42d210df7a6"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["oauth_openshift_apps_okd4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/dfd6252bef62978bcea4f275ef4de8eb"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["ocp4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/d4e288631fbdf914c359bdc5b3189c09"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["okd4sno_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/99fbc2deadefdac8ee9c8343243ca1ed"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["rabbit_01_psp_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/d3acc968bb847f650ec676ac53826224"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["rmon_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/f433604801c4d938b343de9846cafdb1"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["squid_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/b7d06cbaa30a5347bba40d4f13816cf1"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wildcard_teleport_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/56503dd4c0063008c2dbc4133e813585"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["teleport_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/77f789eef05dc083b364190e06fe84d6"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["test_vpn_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/39a027bdca4768e9faac7fdbf8963641"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["traefik_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/d0b0501ba5db067db1fcc1580b0f90c5"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["traefik_home_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/4b0c5f828bb24f40d2f707a58d323bcb"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["tv_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/4f9a2ed56f29d84ff8e620c037fd3253"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["unifi_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/ea0bdc359c7a01c58e7cebf202c47dda"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["vpn_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/1317b7a0efda899b2d4ec5bcdd973063"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["web1_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/9f036d65fe9e8800d801e50614818d9e"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["webhook_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/ba8af196a0fe8371b62a28634d68720f"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wg_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/de40c9242301ad9570a10e4644f2c798"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wgf1_ams_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/bc111fbfcc3005b66331ed32ebda1bba"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wgf1_ch_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/8c4f9e77df818012bc6d3c9c559ccf0d"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["zabbix_a"]
  id = "dafa0a53a384eb00fda6edada1f25db3/6742a4b8cb10b55f10560b0414bda82e"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["rmon_aaaa"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c5078c527ddec0d218365b125a6dc460"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["vpn_aaaa"]
  id = "dafa0a53a384eb00fda6edada1f25db3/9e7ec3d3f48f774e1f370f59184245a6"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["harbor"]
  id = "dafa0a53a384eb00fda6edada1f25db3/d2937072bbeaa2cf7062ee7e7bee2476"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["notary_harbor"]
  id = "dafa0a53a384eb00fda6edada1f25db3/a06dc1154648ee32ac68ea1aa59110ca"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["jenkins"]
  id = "dafa0a53a384eb00fda6edada1f25db3/9f3b48a396da255c7dbea16ffb34bb7c"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["amp_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/a46f6e5454f149497a9d47c0691a8ec2"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["artifactory_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/2c0d9e20ce11713cc4ec9e2ae13311c3"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["cloud_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/becb7bc51d9d432858bf1bb622edb345"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["root_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/6ba3803b7c0afaacfa0085136b9c7029"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["kubenuc_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/5c8bec66a18eee62f53a8350e6744d33"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["node1_pterodactyl_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/d4864d6c2743358ccd66006b937e9531"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["node_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c73c9ffe6de0fcf888d7f083bad95b52"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["nx_s3_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/3f6f6316b08ec7df6fdebde43b76ea5a"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["pelican_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/2f25acd232a0e49990f08b70fb2c7ec5"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["photos_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/6725ff91ab05bad5b86c74dcc23b774a"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["portainer_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/b61f3a83a7e27f99900949152ef0c719"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["pterodactyl_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/06b266d858acbc66c12cc018651a4fc7"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["puffer_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/61b72581a282b773d0abb84bf7fe7b35"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["s3_api_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/ecaac9c4faa9855085b8f56ecf8a7bf7"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["s3_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/4e96dcd47287e5b3466a66726d55c29c"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["sig1_domainkey_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/99ddb93884a82c1d01bae70182903930"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["sso_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/567851c316bdcf5f07313ef5f92f0eb2"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["test_sso_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/2cf6b7bb1ad58801187755e829a0f696"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["www_cname"]
  id = "dafa0a53a384eb00fda6edada1f25db3/ef91e04d909cd65f3c22169be28832c9"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["root_mx"]
  id = "dafa0a53a384eb00fda6edada1f25db3/053273447c46df29e65a1f00e3fd4031"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["root_mx_2"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c00ec4923dddffc2436cc8902fca9f0e"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["watest_ns"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c7670fdc536c502cd46dc153aeb559c0"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["watest_ns_2"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c38d77cda1855be438ac249711c9b946"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["watest_ns_3"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c80af550a454554f533766096a03a1ff"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["watest_ns_4"]
  id = "dafa0a53a384eb00fda6edada1f25db3/f466553e83d18ab595759f0f44418896"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wtest_ns"]
  id = "dafa0a53a384eb00fda6edada1f25db3/6eeb26a4fa7511f9701d619bb791c6a7"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wtest_ns_2"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c66ebbaadc3d550bcb0dd6017bf36f68"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wtest_ns_3"]
  id = "dafa0a53a384eb00fda6edada1f25db3/4eacf3d07c7545dadaac274776d21b2c"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["wtest_ns_4"]
  id = "dafa0a53a384eb00fda6edada1f25db3/6f6c735559e7826f4efac3c89ba836d8"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_gatherer_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/7dd341e7dbcbd70ff549bc921a3c9185"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_jenkins_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/2e324e5d34414ffc5c15383eb0c839f6"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_lhui_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/41761bb8feb4b91d1401d43571cb3678"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_nx_minio_console_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/6c8b4dadafacdb1d984dcf67b1c363f2"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_nx_minio_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/c293dd7e00f4b386fa67a5b9c5e37c8b"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_portainer_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/a1427690be5ba6bd2d4ac12a7ffcab32"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_sso_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/58b17a134cea83a31a9fbd83d75f8da7"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_test_sso_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/61cd61c8b6725f3187b7681834601706"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["acme_challenge_unifi_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/8c0f3ef865ed5a0cd67dbd257e05de43"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["cf2024_1_domainkey_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/87d5fd578cbb17ea67037c3c06d16d77"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["root_txt_apple"]
  id = "dafa0a53a384eb00fda6edada1f25db3/76596cbec09fe862c42284cea08d230e"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["root_txt_ms"]
  id = "dafa0a53a384eb00fda6edada1f25db3/b99741118e4bd3279f401b2f36ec3cc0"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["root_txt_spf"]
  id = "dafa0a53a384eb00fda6edada1f25db3/06b2b2ec0d0079752bfc7103e1af8fcd"
}

import {
  to = module.ddlns_net.cloudflare_dns_record.this["dmarc_txt"]
  id = "dafa0a53a384eb00fda6edada1f25db3/d26c5bb565d56c0e4dd5f27ba5617b33"
}

# ---------------------------------------------------------------------------
# fastnetserv.com
# ---------------------------------------------------------------------------

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["easyiva_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/a0d59964aa220b8c6ea47532cc410bca"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["root_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/7b3cdfc812700475fa8993fde00501fd"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mail2_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/96b7fc33078fc422031e8cf7c59476cc"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mail3_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/7aea519efef1f8aa596a4b43144ffd9f"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mail4_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/7619ad2252b057cc2ab4963aea171eb1"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mta_sts_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/81e04a579caa5c48cb5e1271086dcebb"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s4_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/f0d0fce5c00070e5457c4481f371b972"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s4_a_2"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/d2a3461b9c17942aae3c8852ed64e120"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s4_a_3"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/69f8df6491ae4cf2f9e6151ff5ff37a1"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s5_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/88d8e6ff0a676c3e3a2581b2a8d66559"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s5_a_2"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/6e3fdc7ffaf3b919848ce348fb7ca1ba"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s5_a_3"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/fa16b04a6d13b51f66606a0e33012ce8"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s_a"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/7d6ebe96fdc6e30e6220219fea3d3996"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s_a_2"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/76174b468e76e2d9a0f0b15e9e5d3d38"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["sysdig_k8s_a_3"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/2cf2b8105799ed0126ebdc1d8aeb5e69"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mail2_aaaa"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/21d9abf17d0a8e49356b1702f12f7bcc"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["autoconfig_cname"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/10bca2c1353247c343d5b0da8317ff7b"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["autodiscover_cname"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/451e60dca4d26bbab2c5ac85d2bc0976"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["email_mailgun_cname"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/ffe3441a4456fec610c9e4bae31fba11"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mail_cname"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/8339a3fb092e6423914b64dc18465323"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["www_cname"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/5252b786c54e643d2c4958fb2f497246"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["root_mx"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/baf77b9830521865a33737a7a9ef2458"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["root_mx_2"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/5aab033f1afcb9b064163b80ddd6372f"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["root_mx_3"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/dd23ed6cd8fa42aad5e55269b0cf3d92"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mailgun_mx"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/792b83b2d50244b13625f5bab389720e"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mailgun_mx_2"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/0cc90721b55e52181746a4aef7d803a3"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["tlsa_587_tcp_mail2"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/322baa458397d6c9abb0dc3c9f8e7341"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["tlsa_587_tcp_mail"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/40d9b5bebbd2b4baa27bc01fe6d86fda"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["ad_txt"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/6447e0426c41df6937ce7ee261c26980"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["dkim_domainkey_txt"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/add86016d11b682f9377bca11a8ca4b5"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["dmarc_txt"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/7ac6a588a838911e744bf9b5cfd2f07b"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["root_txt_spf"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/c5c42a782f6d6f897b26e0273b0a5ffb"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mailgun_txt_spf"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/40dec06f3749407c6dadeb8145b6ee76"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["mta_sts_txt"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/9046918216e2463f3d71d3a71e418762"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["smtp_domainkey_mailgun_txt"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/0dfbe34a5d0c9242185ec17ae51d6a06"
}

import {
  to = module.fastnetserv_com.cloudflare_dns_record.this["smtp_tls_txt"]
  id = "6aaeaed2af008fa6f73b5a8c50080179/9545a64aaa6768f1fcce55fd6a45eb1d"
}

# ---------------------------------------------------------------------------
# fastnetserv.net
# ---------------------------------------------------------------------------

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mail2_a"]
  id = "a4f2134f0c687ca12b39557fd87a710e/957235b601dd9e129246f45a94de27f9"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mail3_a"]
  id = "a4f2134f0c687ca12b39557fd87a710e/cd1adb6a25d5f35e91a3d468fda5b1f4"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mail3_a_2"]
  id = "a4f2134f0c687ca12b39557fd87a710e/483e0ecc1f3b812f10b83f3819d610de"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mail4_a"]
  id = "a4f2134f0c687ca12b39557fd87a710e/f3c49a9c604ac9f8f8e861bc4cd89c73"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mta_sts_a"]
  id = "a4f2134f0c687ca12b39557fd87a710e/969f49cfa588338ae2b0b0c43c3d262e"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["ansible_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/e9675211d89f3b7c4b0d308c0f5e7615"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["autoconfig_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/b5fa73a0e834241898d2c3913b06e560"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["autodiscover_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/cc9f6967cfab50029b61f9944ac394ad"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["em9662_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/db908e1130e8a80b60cc3fdd2b85a35b"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["root_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/11f92acf84c0bebb803a504879ae6dcf"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mail_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/d902a735392e3ef4c78ed1f648a8e8a3"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["s1_domainkey_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/09a017dbe8aad1389b4fd13a344f1860"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["s2_domainkey_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/ed15ce75617275786f55a6343c98bcc6"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["www_cname"]
  id = "a4f2134f0c687ca12b39557fd87a710e/de5cf77a177b17d4d6ccdb35f8432a03"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["root_mx"]
  id = "a4f2134f0c687ca12b39557fd87a710e/40ea2a70bd970131a966c0a2eec3508e"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["root_mx_2"]
  id = "a4f2134f0c687ca12b39557fd87a710e/f6a4d1a4e88f945d096bf12edf71ae9b"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["root_mx_3"]
  id = "a4f2134f0c687ca12b39557fd87a710e/ce2694efe3670ddbd4b6954fb0d13868"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["root_mx_4"]
  id = "a4f2134f0c687ca12b39557fd87a710e/4b6772188e29a90b5017c182d82e0083"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["dkim_domainkey_txt"]
  id = "a4f2134f0c687ca12b39557fd87a710e/535ef52d3264e87b3b5ee36c83d5ffbf"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["dmarc_txt"]
  id = "a4f2134f0c687ca12b39557fd87a710e/c5d3751ae6fb28890464e9953381c840"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["root_txt_spf"]
  id = "a4f2134f0c687ca12b39557fd87a710e/f466089e038d66136e054234097a116b"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["mta_sts_txt"]
  id = "a4f2134f0c687ca12b39557fd87a710e/c847a5133c8dc3066efeada23048faf2"
}

import {
  to = module.fastnetserv_net.cloudflare_dns_record.this["smtp_tls_txt"]
  id = "a4f2134f0c687ca12b39557fd87a710e/987bcf8eba92ab3a026a3c0c8618eabd"
}

# ---------------------------------------------------------------------------
# oasirho.com
# ---------------------------------------------------------------------------

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_a"]
  id = "18e44758c502ea426ddaeac62ac9a723/83007bcf8916edf8d02c4cf26c1e45da"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["imap_cname"]
  id = "18e44758c502ea426ddaeac62ac9a723/ff82ca321099e0176af0482fe8f01257"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["mail_cname"]
  id = "18e44758c502ea426ddaeac62ac9a723/91216848570cb2e80223bd1d1a17d2b3"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["pop_cname"]
  id = "18e44758c502ea426ddaeac62ac9a723/8a31b6c9d74644131eb24f944445acfc"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["smtp_cname"]
  id = "18e44758c502ea426ddaeac62ac9a723/00ee3f815827aa1a121cd0046e0c8ab0"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["webmail_cname"]
  id = "18e44758c502ea426ddaeac62ac9a723/a7534d552fda70590306d14f67b76cae"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["www_cname"]
  id = "18e44758c502ea426ddaeac62ac9a723/09afcd5cb781da5079a2a3b22ee078bf"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx"]
  id = "18e44758c502ea426ddaeac62ac9a723/cc78c2c5a8e6d6d1c8c09b62da000229"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx_2"]
  id = "18e44758c502ea426ddaeac62ac9a723/90e6372b60fbc3811123947d565eb4ed"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx_3"]
  id = "18e44758c502ea426ddaeac62ac9a723/a97b1b18fcd4604df6330cec0c7e3664"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx_4"]
  id = "18e44758c502ea426ddaeac62ac9a723/413b686c61661765ed59865c7748c10d"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx_5"]
  id = "18e44758c502ea426ddaeac62ac9a723/7a19d6592ed57592f354804fd1c895e2"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx_6"]
  id = "18e44758c502ea426ddaeac62ac9a723/b5e0099f534fd5646bf3151ca469df51"
}

import {
  to = module.oasirho_com.cloudflare_dns_record.this["root_mx_7"]
  id = "18e44758c502ea426ddaeac62ac9a723/b17fb2a539d07d3d9a272b56992f7c07"
}

# ---------------------------------------------------------------------------
# oasirho.it
# ---------------------------------------------------------------------------

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_a"]
  id = "55b034b4a8ecae699f882e320d3ad55e/1c87397d8ff4258cfbd352c5226f0270"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["imap_cname"]
  id = "55b034b4a8ecae699f882e320d3ad55e/3498eb40274c8917d7cbbadfa2340c9e"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["mail_cname"]
  id = "55b034b4a8ecae699f882e320d3ad55e/f04eef9d9aa54d8ed4fda2b6defe10c5"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["pop_cname"]
  id = "55b034b4a8ecae699f882e320d3ad55e/31f8c27845dd51af62d38893edecdb37"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["smtp_cname"]
  id = "55b034b4a8ecae699f882e320d3ad55e/f116cac31f3bc463fac633ddf0ca9df0"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["webmail_cname"]
  id = "55b034b4a8ecae699f882e320d3ad55e/4ffe4fc62e5191c5e3bdb979dbcd738e"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["www_cname"]
  id = "55b034b4a8ecae699f882e320d3ad55e/7c20a0244649056a7657a504bb50c362"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_mx"]
  id = "55b034b4a8ecae699f882e320d3ad55e/fa35be1df15339f055a8585ef9a245f7"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_mx_2"]
  id = "55b034b4a8ecae699f882e320d3ad55e/081d56ebe88eab0ae54d1b890d8ebd37"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_mx_3"]
  id = "55b034b4a8ecae699f882e320d3ad55e/d0f1e439f4ddcf04d559b0cd32ac980b"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_mx_4"]
  id = "55b034b4a8ecae699f882e320d3ad55e/86cb183eadc2deab113ef60d6bc15c8c"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_mx_5"]
  id = "55b034b4a8ecae699f882e320d3ad55e/3e26a653a9cddb4d89bc9e2bacf18c0d"
}

import {
  to = module.oasirho_it.cloudflare_dns_record.this["root_txt_spf"]
  id = "55b034b4a8ecae699f882e320d3ad55e/025afac2e43cfd26f32d68f0e1de283d"
}
