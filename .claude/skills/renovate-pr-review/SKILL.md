---
name: renovate-pr-review
description: Review a Renovate PR before merging — read the changelog, diff values against this repo's overrides, check e2e status, flag major bumps, and produce a merge checklist. Triggers on "review this renovate PR", "should I merge this chart bump", "is this renovate PR safe".
---

# Renovate PR Review Skill

Use this skill when asked to review a Renovate-authored PR (Helm chart bump, Terraform provider/module bump, GitHub Action digest bump) before merging.

## Review steps

1. **Read the changelog.** Renovate PR bodies link the upstream release notes/changelog for the version range being bumped — follow that link (or `mcp__github__get_release_by_tag` / `search_commits` on the upstream repo if the PR body doesn't include one) and read what actually changed, not just the version numbers.
2. **Diff values against this repo's overrides.** For a HelmRelease bump, check whether any values key this repo explicitly sets (`.spec.values` in the `release.yml`) was renamed, deprecated, or had its default/schema changed in the new chart version — a values key silently becoming a no-op is a real, historically-seen failure mode in this repo (see the `secrets-management` skill's example, and the A9 securityContext work, where wrong/renamed keys silently dropped intended config). For a Terraform provider bump, check the provider's changelog for breaking schema changes to resources/data sources this repo actually uses.
3. **Check e2e status.** For anything touching `clusters/**`, confirm `validate-kubenuc.yml` / `validate-k8s-vms.yml` ran and passed — a green Renovate PR without e2e having run at all is not evidence of safety.
4. **Flag majors.** A major version bump (chart `vX.0.0`, provider major) needs more scrutiny than a patch/minor — call this out explicitly in the review rather than treating all Renovate PRs the same.
5. **Merge checklist.** Summarize as a short checklist: changelog reviewed (yes/no + any breaking changes found), values/schema compatibility checked, e2e status, major-bump flag, recommendation (merge / merge with a follow-up values fix / hold for manual testing).

## Scope notes

- Don't manually edit chart versions Renovate owns (see root `CLAUDE.md` rule 6) — this skill is for *reviewing* Renovate's own PRs, not hand-bumping versions.
- If review turns up a required values change (e.g. a renamed key), make that fix as a **follow-up commit on the Renovate PR's branch** (or a separate PR if Renovate doesn't allow pushes to its branch) rather than blocking the bump indefinitely — see the `flux-operations` and chart-specific patterns in `terraform-operations`/`op-terraform` for the values conventions to preserve.
