---
name: ci-workflows
description: GitHub Actions workflow patterns for infra-cd — Terraform CI (fmt/init/validate/plan/apply), cluster validation (k3s + FluxCD + Robot Framework), Flux cron updates, and runner selection.
---

# CI Workflows Skill

Use this skill when creating or modifying GitHub Actions workflows. Complex CI decisions (e.g. matrix strategy, environment promotion gates) use Claude Code directly; boilerplate uses the Terraform/Kubernetes agents.

## Terraform CI workflow pattern

All Terraform workflows follow the same pattern. Copy from `.github/workflows/terraform.yml` and adjust the paths and runner.

### Key parameters to change

| Parameter | Location | Example |
|---|---|---|
| `on.push.paths` | trigger | `terraform/netbird/**` |
| `on.pull_request.paths` | trigger | `terraform/netbird/**` |
| `env.TF_WORKING_DIR` | env | `terraform/netbird` |
| `runs-on` | jobs | see runner table below |
| Workflow filename | file name | `terraform-netbird.yml` |

### Runner selection

| Runner | Used for |
|---|---|
| `self-hosted` | Generic / Hetzner VPS / PSP (BGY) |
| `LGU` | Gozzi-01 + hpelvisor (Lugano, Switzerland) |
| `mxp` | OVH EC200 (Milan, Italy) |

Choose based on network proximity to the managed infrastructure, or `self-hosted` for cloud providers with no locality requirement.

### Workflow stages

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: hashicorp/setup-terraform@v4
    with:
      cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

  - name: Terraform Format Check
    run: terraform fmt -check
    working-directory: ${{ env.TF_WORKING_DIR }}

  - name: Terraform Init
    run: terraform init
    working-directory: ${{ env.TF_WORKING_DIR }}
    env:
      OP_TOKEN: ${{ secrets.OP_TOKEN }}
      OP_ENDPOINT: ${{ secrets.OP_ENDPOINT }}

  - name: Terraform Validate
    run: terraform validate
    working-directory: ${{ env.TF_WORKING_DIR }}

  - name: Terraform Plan
    id: plan
    run: terraform plan -no-color
    working-directory: ${{ env.TF_WORKING_DIR }}
    env:
      TF_VAR_onepassword_token: ${{ secrets.OP_TOKEN }}
      TF_VAR_onepassword_endpoint: ${{ secrets.OP_ENDPOINT }}

  # Post plan as PR comment (copy the comment block from terraform.yml)

  - name: Terraform Apply
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    run: terraform apply -auto-approve
    working-directory: ${{ env.TF_WORKING_DIR }}
    env:
      TF_VAR_onepassword_token: ${{ secrets.OP_TOKEN }}
      TF_VAR_onepassword_endpoint: ${{ secrets.OP_ENDPOINT }}
```

## Cluster validation workflow pattern

Reference: `.github/workflows/validate-kubenuc.yml`

Key components:
- Spins up a k3s cluster (v1.33.3+k3s1)
- Installs FluxCD (v2.7.5) via `flux install`
- Applies cluster manifests
- Runs Robot Framework E2E tests via `tests/robot/robot-test-job.yaml`
- 2-hour timeout
- Triggers on PRs touching `clusters/{cluster}/**`

## Self-hosted Renovate workflow

Reference: `.github/workflows/renovate.yml`

Runs Renovate via GitHub Actions instead of relying solely on the hosted Renovate GitHub App (modeled on `onedr0p/home-ops`'s `renovate.yaml`, see [[reference_homeops_repo_comparison]]):

- Both the hourly cron (`20 * * * *`) **and** the push trigger (on `renovate.json`/`.renovate/**.json5`) ship commented out — **do not re-enable either until the hosted Renovate GitHub App is uninstalled from this repo** (check `https://github.com/settings/installations`), or both integrations run and either open duplicate PRs or fight over identical `renovate/*` branch names under different bot identities. Only `workflow_dispatch` is live pre-cutover, and its `dryRun` input defaults to `true` for exactly this reason — the first validation run must not touch anything for real while the hosted app is still installed. Uncomment push and cron together only after a dry-run dispatch has gone green and the hosted app is removed.
- Mints a short-lived GitHub App installation token via `actions/create-github-app-token`, scoped to just this repo (`owner` + `repositories` inputs)
- Runs `renovatebot/github-action` with `RENOVATE_AUTODISCOVER: false` and `RENOVATE_REPOSITORIES` locked to `github.repository` — never autodiscover-all
- The GitHub App needs: Checks (write), Contents (write), Issues (write), Pull requests (write), Commit statuses (write), Workflows (write — required because `renovate.json` extends `helpers:pinGitHubActionDigests`, which edits `.github/workflows/*.yml`), Vulnerability alerts (read)
- `RENOVATE_DRY_RUN`/`RENOVATE_PLATFORM_COMMIT` use the current string spellings (`full`/`enabled`) rather than boolean `true` — Renovate accepts booleans via a deprecated legacy coercion, but it logs a warning on every run
- App ID and private key are stored as plain GitHub Actions repo secrets (`RENOVATE_APP_ID`, `RENOVATE_APP_PRIVATE_KEY`) — consistent with how `TF_API_TOKEN`/`OP_TOKEN` are already handled in this repo, rather than pulled live from 1Password in-workflow (see `secrets-management` skill for why: no 1Password Service Account exists yet for Actions-time secret loading, only the Connect token used by Terraform)

## FluxCD cron update workflow

Reference: `.github/workflows/flux-cron.yml`

- Runs Mondays at 3 AM
- Also manually triggerable
- Updates FluxCD components in `clusters/*/flux-system/`
- Opens a PR with the update

## Required GitHub Actions secrets

| Secret | Purpose | Used by |
|---|---|---|
| `TF_API_TOKEN` | Terraform Cloud authentication | All Terraform workflows |
| `OP_TOKEN` | 1Password Connect token | All Terraform workflows |
| `OP_ENDPOINT` | 1Password Connect endpoint | All Terraform workflows |
| `RENOVATE_APP_ID` | Renovate GitHub App ID | `renovate.yml` |
| `RENOVATE_APP_PRIVATE_KEY` | Renovate GitHub App private key (PEM) | `renovate.yml` |
| `GITHUB_TOKEN` | Built-in, no configuration needed | All workflows |

## Adding a new Terraform workflow

1. Copy `.github/workflows/terraform.yml` to `.github/workflows/terraform-{name}.yml`
2. Update `on.push.paths`, `on.pull_request.paths`, `env.TF_WORKING_DIR`, `runs-on`
3. If multiple working directories in one workflow, use a matrix or separate jobs (see `terraform-mxp.yml` for the two-job pattern)
4. Confirm the Terraform Cloud workspace exists and the runner is available

## Verification checklist

- [ ] Workflow triggers on the correct file paths
- [ ] Runner is available and has network access to managed infrastructure
- [ ] `terraform fmt -check` is the first step (CI enforces formatting)
- [ ] Plan output is posted as a PR comment
- [ ] Apply only runs on `main` branch push
- [ ] Required secrets are present in the repository settings
- [ ] Workflow file passes YAML validation (`pre-commit run --all-files`)
