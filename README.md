# infra-cd

This project is an personal exercise of style on how-to handle infra-as-code.

My infrastructure is composed by several legacy services that from time-to-time I'm converting into IaC. I work on it on spare time and this repo it's far from being perfect :)


CI/CD technology used:

- Ansible
- [FluxCD](https://fluxcd.io/)
- [Packer](https://www.packer.io/)
- [Terraform](https://www.terraform.io/)

Token/Secret managers:
- [1Password Secrets Automation workflow](https://developer.1password.com/docs/connect/get-started/)

## Hardware ⚙️

| Hostname            | Type        | Model                   | CPU                   | Memory | Storage                                          | IPv6 | Location | Bandwidth                | Active? |
| --------------------| ----------- | ----------------------- | --------------------- | ------ | ------------------------------------------------ | ---- | -------- | ------------------------ | ------- |
| astronomical-01-prg | Server      | HP Proliant DL360 Gen9  | 2x Xeon E5-2680 v4    | 256 Gb | 2x500GB SSD<br><br>3x1920GB SSD Kingston DC600M  | N/A  | PRG 🇨🇿   |           N/A            |    ❌   |
| rabbit-01-psp       | Server      | HP Proliant DL360 Gen9  | 2x Xeon E5-2680 v4    | 128 Gb | 2x500GB SSD<br><br>6x960GB SSD Kingston DC500M   | No   | BGY 🇮🇹   | 1 Gbit down/1 Gbit up    |    ✅   |
| gozzi-01-lug        | Server      | HP Proliant DL360 Gen9  | 2x Xeon E5-2680 v4    | 128 Gb | 2x500GB SSD<br><br>3x960GB SSD                   | Yes  | LUG 🇨🇭   | 10 Gbit down/up          |    ✅   |
| gozzi-02-lug        | Server      | HP Proliant DL380e Gen8 | 2x Xeon E5-2420 v2    | 64 Gb  | 2x72GB SAS 15K rpm<br><br>16x600GB SAS 10K rpm   | Yes  | LUG 🇨🇭   | 10 Gbit down/up          |    ✅   |
| ms01-mxp            | MicroServer | Miniserver MS-01        | 1x i9-13900H Gen 13th | 64 Gb  | 1x2TB M2 SSD<br><br>1x1920GB U2 SSD              | Yes  | MXP 🇮🇹   | 2x2.5Gbit down/1 Gbit up |    ✅   |
| mail2               | VPS         | N/A                     | 2 Cores               | 4Gb    | 1x40Gb                                           | Yes  | NBG 🇩🇪   | 5 Gbit down/up           |    ✅   |
| reverse01           | VPS         | N/A                     | 1 Core                | 1Gb    |                                                  | No   | ZRH 🇨🇭   | 500 Mbit down/up         |    ✅   |
| reverse02           | VPS         | N/A                     | 1 Core                | 1Gb    |                                                  | No   | ZRH 🇨🇭   | 500 Mbit down/up         |    ✅   |
| k8s-arm             | VPS         | N/A                     | 4 Cores               | 12Gb   |                                                  | No   | ZRH 🇨🇭   | 1 Gbit down/up           |    ✅   |
| vpn-01              | VPS         | N/A                     | 1 Core                | 1Gb    |                                                  | No   | NL 🇳🇱    | 500 Mbit down/up         |    ✅   |
| vpn-02              | VPS         | N/A                     | 1 Core                | 1Gb    |                                                  | No   | NL 🇳🇱    | 500 Mbit down/up         |    ✅   |

## Kubernetes clusters ☸️

| Name        | CP Nodes      | Worker Nodes  | Region        |
| ----------- | ------------- | ------------- | ------------- |
| kubenuc     | 3x 2Cores/6GB | 3x 8Core/16GB | MXP, BGY, LUG |
| k3s-preprod | 1x 4Cores/4GB | 1x 8Core/16Gb | LUG           |
| kubearm     |               |               | ZRH           |


## TODO

- Terraform Hetzner
- Version promotion [git issue](https://github.com/dark-vex/infra-cd/issues/427) and/or [Renovate](https://github.com/renovatebot/renovate)
- Implement ExternalDNS
- SOPS
- Teleport IaC config

Print Instance IP and update ansible inventory file and cloudflare DNS records

https://github.com/fluxcd/flux2/discussions/1076
