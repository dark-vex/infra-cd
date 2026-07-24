#!/usr/bin/env python3
"""
Proxmox Terraform Generator

Converts the output of proxmox-discover.py into Terraform module blocks and import statements.

Usage:
    python proxmox-generate-tf.py --input discovered.json --output terraform/proxmox/
    python proxmox-generate-tf.py --input discovered.json --host rabbit-01-psp --provider-alias rabbit

Example workflow:
    1. python proxmox-discover.py --host https://pve:8006 --token-id ... > discovered.json
    2. python proxmox-generate-tf.py --input discovered.json --output terraform/proxmox/
"""

import argparse
import json
import os
import re
import sys
from typing import Any


def sanitize_name(name: str) -> str:
    """Convert a name to a valid Terraform identifier."""
    # Replace dots and hyphens with underscores
    sanitized = re.sub(r'[.\-]', '_', name)
    # Remove any other invalid characters
    sanitized = re.sub(r'[^a-zA-Z0-9_]', '', sanitized)
    # Ensure it starts with a letter
    if sanitized and sanitized[0].isdigit():
        sanitized = 'r_' + sanitized
    return sanitized.lower()


def parse_lxc_network(config: str) -> dict:
    """Parse LXC network configuration string."""
    result = {
        'bridge': 'vmbr0',
        'name': 'eth0',
        'ip': 'dhcp',
        'gw': None,
        'hwaddr': None,
    }

    if not config:
        return result

    for part in config.split(','):
        if '=' in part:
            key, value = part.split('=', 1)
            if key == 'bridge':
                result['bridge'] = value
            elif key == 'name':
                result['name'] = value
            elif key == 'ip':
                result['ip'] = value
            elif key == 'gw':
                result['gw'] = value
            elif key == 'hwaddr':
                result['hwaddr'] = value

    return result


def parse_lxc_rootfs(config: str) -> dict:
    """Parse LXC rootfs configuration string."""
    result = {
        'datastore': 'local-lvm',
        'size': 8,
    }

    if not config:
        return result

    parts = config.split(',')
    if parts:
        # First part is volume, e.g., "local-lvm:vm-100-disk-0"
        if ':' in parts[0]:
            result['datastore'] = parts[0].split(':')[0]

    for part in parts[1:]:
        if '=' in part:
            key, value = part.split('=', 1)
            if key == 'size':
                # Convert size like "8G" to integer
                size_str = value.rstrip('GgMmTt')
                try:
                    result['size'] = int(size_str)
                except ValueError:
                    pass

    return result


def generate_lxc_module(node: str, container: dict, provider_alias: str) -> str:
    """Generate Terraform module block for an LXC container."""
    name = container.get('name', f"ct-{container['vmid']}")
    hostname = container.get('hostname', name)
    # Add _lxc suffix to avoid conflicts with VMs that have the same name
    module_name = f"{provider_alias}_{sanitize_name(name)}_lxc"

    # Parse network config
    networks = container.get('networks', [])
    net_config = parse_lxc_network(networks[0]['config'] if networks else '')

    # Parse rootfs config
    rootfs = parse_lxc_rootfs(container.get('rootfs', ''))

    # Build IP config
    ip_config = '{\n    ipv4_address = "dhcp"\n  }'
    if net_config['ip'] and net_config['ip'] != 'dhcp':
        if net_config['gw']:
            ip_config = f'{{\n    ipv4_address = "{net_config["ip"]}"\n    ipv4_gateway = "{net_config["gw"]}"\n  }}'
        else:
            ip_config = f'{{\n    ipv4_address = "{net_config["ip"]}"\n  }}'

    # Build mac address line
    mac_line = ""
    if net_config['hwaddr']:
        mac_line = f'\n  network_mac_address    = "{net_config["hwaddr"]}"'

    # Build tags
    tags = container.get('tags', [])
    if not tags:
        tags = ['automation', 'lxc']
    tags_str = ', '.join(f'"{t}"' for t in tags)

    return f'''module "{module_name}" {{
  source = "../modules/proxmox-lxc"
  providers = {{
    proxmox = proxmox.{provider_alias}
  }}

  hostname        = "{hostname}"
  vmid            = {container['vmid']}
  node_name       = "{node}"
  description     = "{name}"

  cpu_cores       = {container.get('cores', 1)}
  memory          = {container.get('memory', 512)}
  swap            = {container.get('swap', 0)}
  disk_size       = {rootfs['size']}
  disk_datastore  = "{rootfs['datastore']}"

  template_file_id = proxmox_virtual_environment_download_file.{provider_alias}_ubuntu_24_04_lxc.id
  os_type          = "{container.get('ostype', 'ubuntu')}"

  network_bridge         = "{net_config['bridge']}"{mac_line}
  network_interface_name = "{net_config['name']}"
  ip_config = {ip_config}

  ssh_keys     = [
    data.onepassword_item.ssh_key.public_key,
    data.onepassword_item.ssh_key_new.public_key
  ]
  password     = onepassword_item.lxc_access.password
  unprivileged = {str(container.get('unprivileged', True)).lower()}

  started       = {str(container.get('status') == 'running').lower()}
  start_on_boot = {str(container.get('onboot', False)).lower()}

  tags = [{tags_str}]
}}
'''


def generate_lxc_import(node: str, container: dict, provider_alias: str) -> str:
    """Generate Terraform import block for an LXC container."""
    name = container.get('name', f"ct-{container['vmid']}")
    module_name = f"{provider_alias}_{sanitize_name(name)}_lxc"

    return f'''import {{
  to = module.{module_name}.proxmox_virtual_environment_container.this
  id = "{node}/lxc/{container['vmid']}"
}}
'''


def generate_vm_module(node: str, vm: dict, provider_alias: str) -> str:
    """Generate Terraform module block for a VM."""
    name = vm.get('name', f"vm-{vm['vmid']}")
    module_name = f"{provider_alias}_{sanitize_name(name)}_vm"

    # Parse network config
    networks = vm.get('networks', [])
    net_bridge = 'vmbr0'
    if networks and 'config' in networks[0]:
        for part in networks[0]['config'].split(','):
            if part.startswith('bridge='):
                net_bridge = part.split('=')[1]
                break

    # Parse CPU type (handle "cputype=host" format)
    cpu_type = vm.get('cpu', 'host')
    if '=' in cpu_type:
        # Extract value from "cputype=host" format
        cpu_type = cpu_type.split('=')[-1]

    # Build tags
    tags = vm.get('tags', [])
    if not tags:
        tags = ['automation', 'vm']
    tags_str = ', '.join(f'"{t}"' for t in tags)

    # Build disks configuration
    disks = vm.get('disks', [])
    disks_config = "[]"
    if disks:
        disk_items = []
        for i, disk in enumerate(disks):
            disk_items.append(f'''    {{
      datastore_id = "local-lvm"
      size         = 32
      interface    = "{disk.get('interface', f'virtio{i}')}"
    }}''')
        disks_config = "[\n" + ",\n".join(disk_items) + "\n  ]"

    return f'''module "{module_name}" {{
  source = "../modules/proxmox-vm"
  providers = {{
    proxmox = proxmox.{provider_alias}
  }}

  name        = "{name}"
  vmid        = {vm['vmid']}
  node_name   = "{node}"
  description = "{name}"

  cpu_cores = {vm.get('cores', 1) * vm.get('sockets', 1)}
  cpu_type  = "{cpu_type}"
  memory    = {vm.get('memory', 2048)}

  disks = {disks_config}

  network_bridge = "{net_bridge}"
  ip_config = {{
    ipv4_address = "dhcp"
  }}

  ssh_keys = [
    data.onepassword_item.ssh_key.public_key,
    data.onepassword_item.ssh_key_new.public_key
  ]

  started       = {str(vm.get('status') == 'running').lower()}
  start_on_boot = true

  tags = [{tags_str}]
}}
'''


def generate_vm_import(node: str, vm: dict, provider_alias: str) -> str:
    """Generate Terraform import block for a VM."""
    name = vm.get('name', f"vm-{vm['vmid']}")
    module_name = f"{provider_alias}_{sanitize_name(name)}_vm"

    return f'''import {{
  to = module.{module_name}.proxmox_virtual_environment_vm.this
  id = "{node}/qemu/{vm['vmid']}"
}}
'''


def get_provider_alias(node: str) -> str:
    """Get provider alias from node name."""
    aliases = {
        'rabbit-01-psp': 'rabbit',
        'gozzi-01-bio': 'gozzi',
        'pve-ec200': 'ec200',
        'ec200': 'ec200',
    }
    return aliases.get(node, sanitize_name(node))


def main():
    parser = argparse.ArgumentParser(
        description="Generate Terraform code from Proxmox discovery output"
    )
    parser.add_argument(
        "--input", "-i",
        required=True,
        help="Path to discovery JSON file (use - for stdin)",
    )
    parser.add_argument(
        "--output", "-o",
        help="Output directory for Terraform files",
    )
    parser.add_argument(
        "--host",
        help="Only generate for specific host/node",
    )
    parser.add_argument(
        "--provider-alias",
        help="Override provider alias (default: derived from node name)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print output instead of writing files",
    )
    parser.add_argument(
        "--skip-templates",
        action="store_true",
        help="Skip template VMs/containers",
    )

    args = parser.parse_args()

    # Read input
    if args.input == '-':
        data = json.load(sys.stdin)
    else:
        # Handle various encodings (UTF-8, UTF-16 LE from PowerShell, etc.)
        content = None
        for encoding in ['utf-8-sig', 'utf-16', 'utf-16-le', 'utf-8']:
            try:
                with open(args.input, 'r', encoding=encoding) as f:
                    content = f.read().strip()
                break
            except UnicodeDecodeError:
                continue

        if content is None:
            print(f"Error: Could not decode '{args.input}' with any known encoding", file=sys.stderr)
            sys.exit(1)

        if not content:
            print(f"Error: Input file '{args.input}' is empty", file=sys.stderr)
            sys.exit(1)

        try:
            data = json.loads(content)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in '{args.input}': {e}", file=sys.stderr)
            print(f"First 200 chars: {content[:200]}", file=sys.stderr)
            sys.exit(1)

    # Process each node
    for node, resources in data.items():
        if args.host and node != args.host:
            continue

        provider_alias = args.provider_alias or get_provider_alias(node)

        modules = []
        imports = []

        # Process LXC containers
        for container in resources.get('lxc', []):
            if args.skip_templates and container.get('template'):
                continue
            modules.append(generate_lxc_module(node, container, provider_alias))
            imports.append(generate_lxc_import(node, container, provider_alias))

        # Process VMs
        for vm in resources.get('vms', []):
            if args.skip_templates and vm.get('template'):
                continue
            modules.append(generate_vm_module(node, vm, provider_alias))
            imports.append(generate_vm_import(node, vm, provider_alias))

        # Generate output
        modules_content = f'''# Auto-generated resources for {node}
# Generated by proxmox-generate-tf.py
# Review and adjust as needed before applying

''' + '\n'.join(modules)

        imports_content = f'''# Auto-generated imports for {node}
# Generated by proxmox-generate-tf.py

''' + '\n'.join(imports)

        if args.dry_run or not args.output:
            print(f"# ===== {node}.tf =====")
            print(modules_content)
            print(f"\n# ===== {node}-imports.tf =====")
            print(imports_content)
        else:
            # Write to files
            os.makedirs(args.output, exist_ok=True)

            modules_file = os.path.join(args.output, f"{sanitize_name(node)}-generated.tf")
            imports_file = os.path.join(args.output, f"{sanitize_name(node)}-imports.tf")

            with open(modules_file, 'w') as f:
                f.write(modules_content)
            print(f"Written: {modules_file}")

            with open(imports_file, 'w') as f:
                f.write(imports_content)
            print(f"Written: {imports_file}")


if __name__ == "__main__":
    main()
