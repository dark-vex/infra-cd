# Terraform — Conventions & Recipes

## Conventions

- **State backend:** Terraform Cloud (organization: `Fastnetserv`)
- **Required providers:** Hetzner Cloud, OCI, Proxmox (`~> 0.100`), 1Password (`~> 3`)
- **Format:** Always run `terraform fmt` before committing — CI rejects unformatted files
- Each `terraform/{environment}/` (or `terraform/proxmox/{host}/`) is independent with its own backend config
- Reusable modules published as standalone repos: `dark-vex/terraform-proxmox-vm`, `dark-vex/terraform-proxmox-lxc`, `dark-vex/terraform-hetzner-server`, `dark-vex/terraform-cloudflare-dns` — referenced via `github.com/dark-vex/<name>?ref=vX.Y.Z`
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
| `terraform-grafana.yml` | PR/push to `terraform/grafana/` | Grafana dashboards |
| `terraform-netbox.yml` | PR/push to `terraform/netbox/` | NetBox infrastructure |

---

## Add a New Terraform Environment

1. Create `terraform/{environment}/` with `provider.tf`, `main.tf`, `variables.tf`
2. Configure a Terraform Cloud workspace for the new environment
3. Add a corresponding GitHub Actions workflow in `.github/workflows/`
