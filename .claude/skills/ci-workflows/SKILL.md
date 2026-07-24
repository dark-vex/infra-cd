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
