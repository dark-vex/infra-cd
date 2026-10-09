# Foundation only: a read-only data source proves provider connectivity and
# token permissions without managing anything. Resources arrive via the staged
# import PRs (see terraform/CLAUDE.md). No outputs - group names and URLs must
# not reach public CI logs.
data "authentik_groups" "all" {}
