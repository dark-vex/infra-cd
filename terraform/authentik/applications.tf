resource "authentik_application" "harbor" {
  name               = "Harbor"
  slug               = "harbor"
  protocol_provider  = authentik_provider_oauth2.harbor.id
  policy_engine_mode = "any"

  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_application" "netbird" {
  name               = "Netbird"
  slug               = "netbird"
  protocol_provider  = authentik_provider_oauth2.netbird.id
  policy_engine_mode = "any"

  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_application" "pangolin" {
  name               = "Pangolin"
  slug               = "pangolin"
  protocol_provider  = authentik_provider_oauth2.pangolin.id
  policy_engine_mode = "any"

  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_application" "wiz" {
  name               = "Wiz"
  slug               = "wiz"
  protocol_provider  = authentik_provider_saml.wiz.id
  policy_engine_mode = "any"

  lifecycle {
    prevent_destroy = true
  }
}
