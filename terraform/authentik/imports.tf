# Provider IDs are integer PKs, application IDs are slugs (verified against the
# live API). Remove these blocks in a follow-up once state holds the resources.
import {
  to = authentik_provider_oauth2.harbor
  id = "35"
}

import {
  to = authentik_provider_oauth2.netbird
  id = "34"
}

import {
  to = authentik_provider_oauth2.pangolin
  id = "38"
}

import {
  to = authentik_provider_saml.wiz
  id = "36"
}

import {
  to = authentik_application.harbor
  id = "harbor"
}

import {
  to = authentik_application.netbird
  id = "netbird"
}

import {
  to = authentik_application.pangolin
  id = "pangolin"
}

import {
  to = authentik_application.wiz
  id = "wiz"
}
