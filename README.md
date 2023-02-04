# infra-cd

This project is an personal exercise of style on how-to handle infra-as-code.

My infrastructure is composed by several legacy services that from time-to-time I'm converting into IaC

Automations technology used:
- Ansible
- [FluxCD](https://fluxcd.io/)
- [Packer](https://www.packer.io/)
- [Terraform](https://www.terraform.io/)

Token/Secret managers:
- [1Password Secrets Automation workflow](https://developer.1password.com/docs/connect/get-started/)

## FluxCD k8s Apps/Plugins
- Intel GPU
- Jellyfin
- Nextcloud
- Sysdig Agent
- Sysdig Admission controller
- Zabbix Proxy

## Hardware
<N/A>

## TODO
- Terraform Hetzner
Print Instance IP and update ansible inventory file and cloudflare DNS records
https://github.com/fluxcd/flux2/discussions/1076
