# infra-cd

This project is a personal exercise in infrastructure-as-code. My infrastructure spans several legacy services that I'm progressively migrating to IaC on spare time — far from perfect, always evolving.

## CI/CD & Tooling

- [Ansible](https://www.ansible.com/) — OS-level configuration and patching
- [FluxCD](https://fluxcd.io/) — GitOps continuous delivery for Kubernetes
- [Packer](https://www.packer.io/) — Machine image builds
- [Terraform](https://www.terraform.io/) — Infrastructure provisioning
- [Renovate](https://github.com/renovatebot/renovate) — Automated dependency updates
- [Robot Framework](https://robotframework.org/) — E2E cluster validation tests
- [pre-commit](https://pre-commit.com/) — YAML linting and whitespace enforcement
- [Claude Code](https://claude.ai/code) — AI-assisted development

## Secret & Identity Management

- [1Password Secrets Automation](https://developer.1password.com/docs/connect/get-started/) — Secret injection for Terraform and Kubernetes via Operator
- [SOPS + age](https://github.com/mozilla/sops) — Encrypted cluster variable substitution for FluxCD

## Hardware

| Hostname | Type | Model | CPU | Memory | Storage | IPv6 | Location | Bandwidth | Active? |
|---|---|---|---|---|---|---|---|---|---|
| astronomical-01-prg | Server | HP Proliant DL360 Gen9 | 2x Xeon E5-2680 v4 | 256 GB | 2x500GB SSD + 3x1920GB SSD Kingston DC600M | N/A | PRG 🇨🇿 | 1 Gbit down/up | ❌ |
| rabbit-01-psp | Server | HP Proliant DL360 Gen9 | 2x Xeon E5-2680 v4 | 128 GB | 2x500GB SSD + 6x960GB SSD Kingston DC500M | No | BGY 🇮🇹 | 1 Gbit down/up | ✅ |
| gozzi-01-lug | Server | HP Proliant DL360 Gen9 | 2x Xeon E5-2680 v4 | 128 GB | 2x500GB SSD + 3x960GB SSD | Yes | LUG 🇨🇭 | 10 Gbit down/up | ✅ |
| gozzi-02-lug | Server | HP Proliant DL380e Gen8 | 2x Xeon E5-2420 v2 | 64 GB | 2x72GB SAS 15K rpm + 16x600GB SAS 10K rpm | Yes | LUG 🇨🇭 | 10 Gbit down/up | ✅ |
| ms01-mxp | MicroServer | Miniserver MS-01 | 1x i9-13900H | 64 GB | 1x2TB M.2 SSD + 1x1920GB U.2 SSD | Yes | MXP 🇮🇹 | 2x2.5 Gbit down/1 Gbit up | ✅ |
| mail2 | VPS | N/A | 2 Cores | 4 GB | 1x40 GB | Yes | NBG 🇩🇪 | 5 Gbit down/up | ✅ |
| reverse01 | VPS | N/A | 1 Core | 1 GB | — | No | ZRH 🇨🇭 | 500 Mbit down/up | ✅ |
| reverse02 | VPS | N/A | 1 Core | 1 GB | — | No | ZRH 🇨🇭 | 500 Mbit down/up | ✅ |
| k8s-arm | VPS | N/A | 4 Cores | 12 GB | — | No | ZRH 🇨🇭 | 1 Gbit down/up | ✅ |
| vpn-01 | VPS | N/A | 1 Core | 1 GB | — | No | NL 🇳🇱 | 500 Mbit down/up | ✅ |
| vpn-02 | VPS | N/A | 1 Core | 1 GB | — | No | NL 🇳🇱 | 500 Mbit down/up | ✅ |

## Kubernetes Clusters ☸️

| Name | Type | CP Nodes | Worker Nodes | Region |
|---|---|---|---|---|
| kubenuc | Bare metal (HP ProLiant) | 3x 2 Cores / 6 GB | 3x 8 Cores / 16 GB | MXP, BGY, LUG |
| kubenuc-test | Bare metal (HP ProLiant) | Shared with kubenuc | Shared with kubenuc | MXP, BGY, LUG |
| k3s-prod-test | k3s | 1x 4 Cores / 4 GB | 1x 8 Cores / 16 GB | LUG |
| k3s-rabbit | k3s | 1x node | — | BGY |
| k8s-vms-daniele | VMs | 1x node | — | LUG |
| oc-ampere | OpenShift (OCI) | ARM compute | — | ZRH (OCI) |

## Terraform Environments

| Directory | Purpose | CI Runner |
|---|---|---|
| `terraform/DNS/` | Cloudflare DNS records | — |
| `terraform/hetzner/` | Hetzner Cloud VPS | self-hosted |
| `terraform/oci/` | Oracle Cloud Infrastructure | — |
| `terraform/proxmox/ec200/` | OVH EC200 Proxmox host (MXP) | mxp |
| `terraform/proxmox/gozzi-hpelvisor/` | Gozzi-01 + hpelvisor Proxmox hosts (LUG) | LGU |
| `terraform/proxmox/rabbit/` | Rabbit-01 Proxmox host (BGY) | self-hosted |

## TODO

- Implement ExternalDNS
- Teleport IaC config
- NetBox asset inventory deployment
