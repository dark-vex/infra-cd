#!/usr/bin/env python3
"""
Proxmox Discovery Script

Queries Proxmox API to discover all VMs and LXC containers on specified nodes.
Outputs JSON that can be used to generate Terraform configurations.

Usage:
    python proxmox-discover.py --host <proxmox_host> --token-id <token_id> --token-secret <token_secret>
    python proxmox-discover.py --host <proxmox_host> --user <user> --password <password>

Environment variables:
    PROXMOX_HOST: Proxmox host URL (e.g., https://pve.example.com:8006)
    PROXMOX_TOKEN_ID: API token ID (e.g., root@pam!terraform)
    PROXMOX_TOKEN_SECRET: API token secret
    PROXMOX_USER: Username for password auth
    PROXMOX_PASSWORD: Password for password auth

Example output:
{
    "node_name": "rabbit-01-psp",
    "vms": [...],
    "lxc": [...]
}
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error
import ssl
from typing import Any


def create_ssl_context(verify: bool = False) -> ssl.SSLContext:
    """Create SSL context, optionally skipping verification."""
    if verify:
        return ssl.create_default_context()
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def api_request(
    host: str,
    path: str,
    token_id: str = None,
    token_secret: str = None,
    ticket: str = None,
    csrf_token: str = None,
    verify_ssl: bool = False,
) -> dict:
    """Make an API request to Proxmox."""
    url = f"{host.rstrip('/')}/api2/json{path}"

    headers = {"Accept": "application/json"}

    if token_id and token_secret:
        headers["Authorization"] = f"PVEAPIToken={token_id}={token_secret}"
    elif ticket:
        headers["Cookie"] = f"PVEAuthCookie={ticket}"
        if csrf_token:
            headers["CSRFPreventionToken"] = csrf_token

    req = urllib.request.Request(url, headers=headers)
    ctx = create_ssl_context(verify_ssl)

    try:
        with urllib.request.urlopen(req, context=ctx, timeout=30) as response:
            data = json.loads(response.read().decode("utf-8"))
            return data.get("data", {})
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.reason}", file=sys.stderr)
        print(f"URL: {url}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"URL Error: {e.reason}", file=sys.stderr)
        sys.exit(1)


def login(host: str, user: str, password: str, verify_ssl: bool = False) -> tuple[str, str]:
    """Login with username/password and get ticket."""
    url = f"{host.rstrip('/')}/api2/json/access/ticket"

    data = f"username={user}&password={password}".encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")

    ctx = create_ssl_context(verify_ssl)

    try:
        with urllib.request.urlopen(req, context=ctx, timeout=30) as response:
            result = json.loads(response.read().decode("utf-8"))
            data = result.get("data", {})
            return data.get("ticket"), data.get("CSRFPreventionToken")
    except urllib.error.HTTPError as e:
        print(f"Login failed: {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)


def get_nodes(host: str, **auth) -> list[str]:
    """Get list of node names."""
    nodes = api_request(host, "/nodes", **auth)
    return [n["node"] for n in nodes]


def get_vms(host: str, node: str, **auth) -> list[dict]:
    """Get all VMs on a node with their configurations."""
    vms = api_request(host, f"/nodes/{node}/qemu", **auth)
    result = []

    for vm in vms:
        vmid = vm["vmid"]
        # Get detailed config
        config = api_request(host, f"/nodes/{node}/qemu/{vmid}/config", **auth)

        result.append({
            "vmid": vmid,
            "name": vm.get("name", f"vm-{vmid}"),
            "status": vm.get("status"),
            "cores": config.get("cores", 1),
            "memory": config.get("memory", 512),
            "sockets": config.get("sockets", 1),
            "cpu": config.get("cpu", "host"),
            "ostype": config.get("ostype"),
            "boot": config.get("boot"),
            "agent": config.get("agent"),
            "tags": vm.get("tags", "").split(";") if vm.get("tags") else [],
            "disks": extract_disks(config, "scsi", "virtio", "sata", "ide"),
            "networks": extract_networks(config),
            "template": vm.get("template", 0) == 1,
        })

    return result


def get_lxc(host: str, node: str, **auth) -> list[dict]:
    """Get all LXC containers on a node with their configurations."""
    containers = api_request(host, f"/nodes/{node}/lxc", **auth)
    result = []

    for ct in containers:
        vmid = ct["vmid"]
        # Get detailed config
        config = api_request(host, f"/nodes/{node}/lxc/{vmid}/config", **auth)

        result.append({
            "vmid": vmid,
            "name": ct.get("name", f"ct-{vmid}"),
            "hostname": config.get("hostname", ct.get("name")),
            "status": ct.get("status"),
            "cores": config.get("cores", 1),
            "memory": config.get("memory", 512),
            "swap": config.get("swap", 0),
            "unprivileged": config.get("unprivileged", 1) == 1,
            "ostype": config.get("ostype"),
            "arch": config.get("arch", "amd64"),
            "tags": ct.get("tags", "").split(";") if ct.get("tags") else [],
            "rootfs": config.get("rootfs"),
            "networks": extract_lxc_networks(config),
            "features": config.get("features"),
            "onboot": config.get("onboot", 0) == 1,
            "startup": config.get("startup"),
            "template": ct.get("template", 0) == 1,
        })

    return result


def extract_disks(config: dict, *prefixes: str) -> list[dict]:
    """Extract disk configurations from VM config."""
    disks = []
    for key, value in config.items():
        for prefix in prefixes:
            if key.startswith(prefix) and key[len(prefix):].isdigit():
                disks.append({
                    "interface": key,
                    "config": value,
                })
    return disks


def extract_networks(config: dict) -> list[dict]:
    """Extract network configurations from VM config."""
    networks = []
    for key, value in config.items():
        if key.startswith("net") and key[3:].isdigit():
            networks.append({
                "interface": key,
                "config": value,
            })
    return networks


def extract_lxc_networks(config: dict) -> list[dict]:
    """Extract network configurations from LXC config."""
    networks = []
    for key, value in config.items():
        if key.startswith("net") and key[3:].isdigit():
            networks.append({
                "interface": key,
                "config": value,
            })
    return networks


def generate_terraform_import(node: str, vms: list, lxc: list) -> dict:
    """Generate Terraform import block suggestions."""
    imports = {
        "vms": [],
        "lxc": [],
    }

    for vm in vms:
        if not vm.get("template"):
            imports["vms"].append({
                "name": vm["name"].replace(".", "_").replace("-", "_"),
                "id": f"{node}/qemu/{vm['vmid']}",
                "vmid": vm["vmid"],
            })

    for ct in lxc:
        if not ct.get("template"):
            imports["lxc"].append({
                "name": ct["name"].replace(".", "_").replace("-", "_"),
                "id": f"{node}/lxc/{ct['vmid']}",
                "vmid": ct["vmid"],
            })

    return imports


def main():
    parser = argparse.ArgumentParser(
        description="Discover VMs and LXC containers on Proxmox nodes"
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("PROXMOX_HOST"),
        help="Proxmox host URL (e.g., https://pve.example.com:8006)",
    )
    parser.add_argument(
        "--token-id",
        default=os.environ.get("PROXMOX_TOKEN_ID"),
        help="API token ID (e.g., root@pam!terraform)",
    )
    parser.add_argument(
        "--token-secret",
        default=os.environ.get("PROXMOX_TOKEN_SECRET"),
        help="API token secret",
    )
    parser.add_argument(
        "--user",
        default=os.environ.get("PROXMOX_USER"),
        help="Username for password auth",
    )
    parser.add_argument(
        "--password",
        default=os.environ.get("PROXMOX_PASSWORD"),
        help="Password for password auth",
    )
    parser.add_argument(
        "--node",
        help="Specific node to query (default: all nodes)",
    )
    parser.add_argument(
        "--output",
        choices=["json", "terraform"],
        default="json",
        help="Output format",
    )
    parser.add_argument(
        "--verify-ssl",
        action="store_true",
        help="Verify SSL certificates",
    )

    args = parser.parse_args()

    if not args.host:
        print("Error: --host or PROXMOX_HOST is required", file=sys.stderr)
        sys.exit(1)

    # Determine auth method
    auth = {"verify_ssl": args.verify_ssl}

    if args.token_id and args.token_secret:
        auth["token_id"] = args.token_id
        auth["token_secret"] = args.token_secret
    elif args.user and args.password:
        ticket, csrf = login(args.host, args.user, args.password, args.verify_ssl)
        auth["ticket"] = ticket
        auth["csrf_token"] = csrf
    else:
        print("Error: Either --token-id/--token-secret or --user/--password is required", file=sys.stderr)
        sys.exit(1)

    # Get nodes
    if args.node:
        nodes = [args.node]
    else:
        nodes = get_nodes(args.host, **auth)

    # Collect data
    result = {}
    for node in nodes:
        vms = get_vms(args.host, node, **auth)
        lxc = get_lxc(args.host, node, **auth)

        result[node] = {
            "vms": vms,
            "lxc": lxc,
        }

        if args.output == "terraform":
            result[node]["imports"] = generate_terraform_import(node, vms, lxc)

    # Output
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
