provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}

provider "semaphoreui" {
  # NOT .url/.hostname (top-level 1Password attributes) — those map to a
  # native "Website" field, which is Login-category-specific and never
  # surfaces via the Connect API on this API_CREDENTIAL item, confirmed by
  # waiting on a live Connect read. hostname lives in a named "Config"
  # section field instead, read via section_map.
  #
  # NOT .password either — that's this item's admin *login* password,
  # confirmed live to 401 against the real Semaphore API. The working
  # credential is a real Semaphore API token (minted via Admin -> API
  # Tokens in the Semaphore UI, not a static generatable secret), stored
  # in this item's `credential` field.
  # No "https://" prefix here — the stored "hostname" field value already
  # includes the scheme (confirmed live: prepending a second "https://"
  # produced "https://https://<host>/api", which the CI apply hit for
  # real — "dial tcp: lookup https ... server misbehaving" — since nothing
  # in this session's testing had exercised this exact interpolation
  # against a live HTTP call end-to-end before the real apply did).
  api_base_url = "${trimsuffix(data.onepassword_item.semaphore.section_map["Config"].field_map["hostname"].value, "/")}/api"
  api_token    = data.onepassword_item.semaphore.credential
}
