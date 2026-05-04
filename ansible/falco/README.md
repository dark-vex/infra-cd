# Falco Host-Level Playbook

Install and manage [Falco](https://falco.org/) on Debian 12 (bookworm) and 13 (trixie) hosts using the `modern_ebpf` driver.

## Prerequisites

- Debian 12 or 13
- Kernel >= 5.8 (required by the modern_ebpf driver; the playbook asserts this)
- SSH access with sudo privileges

## Usage

```bash
ansible-playbook -i ../inventory -l falco ansible/falco/falco.yml
```

Or with a specific host:

```bash
ansible-playbook -i ../inventory -l some-host ansible/falco/falco.yml
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `falco_json_output` | `true` | Enable JSON-formatted output |
| `falco_json_include_output` | `true` | Include the output field in JSON |
| `falco_json_include_tags` | `true` | Include tags in JSON output |
| `falco_log_level` | `info` | Log level (`emergency`, `alert`, `critical`, `error`, `warning`, `notice`, `info`, `debug`) |
| `falco_priority` | `debug` | Minimum rule priority to load |

## Service

The playbook manages the `falco-modern-bpf` systemd service. This is the service unit installed by the Falco package when using the modern eBPF driver (no kernel module or separate probe required).

## Custom Rules

Place host-specific rule overrides in `files/falco_rules.local.yaml`. The file is deployed to `/etc/falco/falco_rules.local.yaml` on target hosts.
