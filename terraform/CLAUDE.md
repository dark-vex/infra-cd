# Terraform — Conventions & Recipes

## Conventions

- **State backend:** Terraform Cloud (`Fastnetserv` org) for all stacks **except** `terraform/netbox/`, which uses S3 (Cloudflare R2 — `terraform-state` bucket, `auto` region). Migrated in PR #1404.
- **Required providers:** Hetzner Cloud, OCI, Proxmox (`~> 0.100`), 1Password (`~> 3`)
- **Format:** Always run `terraform fmt` before committing — CI rejects unformatted files
- Each `terraform/{environment}/` (or `terraform/proxmox/{host}/`) is independent with its own backend config
- Reusable modules published as standalone repos: `dark-vex/terraform-proxmox-vm`, `dark-vex/terraform-proxmox-lxc`, `dark-vex/terraform-hetzner-server`, `dark-vex/terraform-cloudflare-dns`, `dark-vex/terraform-cloudflare-tunnel` — referenced via `github.com/dark-vex/<name>?ref=<commit-sha>  # vX.Y.Z` (SHA-pinned for supply-chain safety; the trailing comment records the tag the SHA corresponds to)
- Sensitive values are sourced from 1Password provider — never hardcoded
- Do not hand-pin provider versions managed by Renovate

**CI workflow per Terraform directory:**
1. `terraform fmt -check` (PR)
2. `terraform init` (PR)
3. `terraform validate` (PR)
4. `terraform plan` (PR — result posted as PR comment)
5. `terraform apply` (main branch only)

---

## CI Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `terraform.yml` | PR/push to `terraform/hetzner/` | Hetzner infrastructure |
| `terraform-bio.yml` | PR/push to `terraform/proxmox/gozzi-hpelvisor/` | Gozzi-01 BIO + hpelvisor Proxmox hosts |
| `terraform-mxp.yml` | PR/push to `terraform/proxmox/ec200/` | OVH EC200 (MXP) Proxmox host |
| `terraform-psp.yml` | PR/push to `terraform/proxmox/rabbit/` | Rabbit-01 PSP Proxmox host |
| `terraform-dns.yml` | PR/push to `terraform/DNS/` | DNS records (Cloudflare) |
| `terraform-cloudflare-tunnel.yml` | PR/push to `terraform/cloudflare-tunnel/` | Cloudflare Tunnel remote ingress config (kubenuc, prod-k3s) |
| `terraform-grafana.yml` | PR/push to `terraform/grafana/` | Grafana dashboards |
| `terraform-netbox.yml` | PR/push to `terraform/netbox/` | NetBox infrastructure |
| `terraform-oci.yml` | PR/push to `terraform/oci/` | OCI compute instances (k8s-armchair, teleport, test-vpn) |
| `terraform-semaphore.yml` | PR/push to `terraform/semaphore/` | SemaphoreUI provider config (plumbing only — no resources yet) |

---

## Add a New Terraform Environment

1. Create `terraform/{environment}/` with `provider.tf`, `main.tf`, `variables.tf`
2. Configure a Terraform Cloud workspace for the new environment
3. Add a corresponding GitHub Actions workflow in `.github/workflows/`
