#!/usr/bin/env python3
"""
NetBox Proxmox IP Discovery Script

Discovers live IP addresses for DHCP-assigned rabbit-01-psp guests and
outputs the sops --set commands needed to populate terraform/netbox/secrets.sops.yaml.

Usage:
    export PROXMOX_HOST=https://rabbit-01-psp.example.com:8006
    export PROXMOX_TOKEN_ID=root@pam!netbox-discover
    export PROXMOX_TOKEN_SECRET=<secret>
    python scripts/netbox-proxmox-ip-discover.py [--dry-run] [--sops-file terraform/netbox/secrets.sops.yaml]

Requires: sops binary on PATH, SOPS_AGE_KEY env (for decrypting/re-encrypting)
"""

import json
import os
import subprocess
import sys
import ssl
import urllib.request
import urllib.error
import argparse
from typing import Optional


# VMIDs and types for DHCP rabbit guests that need IP discovery
# Format: (vmid, type, sops_key, node, preferred_interface)
# type: "qemu" or "lxc"
# preferred_interface: regex prefix to prefer (e.g. "eth", "ens", "enp")
DHCP_GUESTS = [
    # VMs (QEMU)
    (501, "qemu", "vms.web1_vm", "rabbit-01-psp", "eth"),
    (601, "qemu", "vms.rtmp1_vm", "rabbit-01-psp", "eth"),
    (101, "qemu", "vms.debian_desktop", "rabbit-01-psp", "eth"),
    (105, "qemu", "vms.3cx", "rabbit-01-psp", "eth"),
    (104, "qemu", "vms.squid_vm", "rabbit-01-psp", "eth"),
    (1001, "qemu", "vms.mail2_bioadventures", "rabbit-01-psp", "eth"),
    (100, "qemu", "vms.sophosxg_vm", "rabbit-01-psp", "Port"),
    (103, "qemu", "vms.docker_vm", "rabbit-01-psp", "eth"),
    (102, "qemu", "vms.k3s_vm", "rabbit-01-psp", "eth"),
    # LXCs
    (806, "lxc", "vms.satisfactory_shared_lxc", "rabbit-01-psp", "eth"),
    (805, "lxc", "vms.satisfactory_lxc", "rabbit-01-psp", "eth"),
    (803, "lxc", "vms.rtmp1_lxc", "rabbit-01-psp", "eth"),
    (808, "lxc", "vms.mon_bgy_lxc", "rabbit-01-psp", "eth"),
    (809, "lxc", "vms.seaweedfs_rabbit_lxc", "rabbit-01-psp", "eth"),
]


def create_ssl_context() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def proxmox_get(host: str, token_id: str, token_secret: str, path: str) -> Optional[dict]:
    url = f"{host}/api2/json/{path.lstrip('/')}"
    headers = {"Authorization": f"PVEAPIToken={token_id}={token_secret}"}
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, context=create_ssl_context(), timeout=10) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 500:
            # Agent not running or guest is stopped
            return None
        print(f"  HTTP {e.code} for {path}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  Error querying {path}: {e}", file=sys.stderr)
        return None


def pick_ipv4(ifaces: list, pref: str) -> Optional[str]:
    """Pick the first non-loopback IPv4 from an interface list, preferring pref prefix."""
    candidates = []
    for iface in ifaces:
        name = iface.get("name", "")
        if name == "lo" or name.startswith("lo"):
            continue
        for addr in iface.get("ip-addresses", []):
            if addr.get("ip-address-type") == "ipv4":
                ip = addr["ip-address"]
                prefix = addr.get("prefix", 24)
                cidr = f"{ip}/{prefix}"
                if ip.startswith("127.") or ip.startswith("169.254."):
                    continue
                candidates.append((name, cidr))
    # Prefer the interface whose name starts with pref
    for name, cidr in candidates:
        if name.lower().startswith(pref.lower()):
            return cidr
    # Fall back to first candidate
    return candidates[0][1] if candidates else None


def discover_qemu_ip(host, token_id, token_secret, node, vmid, pref) -> Optional[str]:
    """Query QEMU guest agent for IPs."""
    data = proxmox_get(host, token_id, token_secret,
                       f"nodes/{node}/qemu/{vmid}/agent/network-get-interfaces")
    if not data:
        return None
    ifaces = data.get("data", {}).get("result", [])
    if not ifaces:
        return None
    return pick_ipv4(ifaces, pref)


def discover_lxc_ip(host, token_id, token_secret, node, vmid, pref) -> Optional[str]:
    """Query LXC interfaces endpoint."""
    data = proxmox_get(host, token_id, token_secret,
                       f"nodes/{node}/lxc/{vmid}/interfaces")
    if not data:
        return None
    ifaces = data.get("data", [])
    candidates = []
    for iface in ifaces:
        name = iface.get("name", "")
        if name == "lo":
            continue
        inet = iface.get("inet", "")
        if inet and not inet.startswith("127.") and not inet.startswith("169.254."):
            candidates.append((name, inet))
    for name, cidr in candidates:
        if name.lower().startswith(pref.lower()):
            return cidr
    return candidates[0][1] if candidates else None


def sops_set(sops_file: str, key_path: str, value: str, dry_run: bool) -> bool:
    """Write a value into the SOPS-encrypted file via sops --set."""
    # key_path like "vms.runner" → ["vms"]["runner"]
    parts = key_path.split(".")
    jq_key = "".join(f'["{p}"]' for p in parts)
    cmd = ["sops", "--set", f'{jq_key} "{value}"', sops_file]
    if dry_run:
        print(f"  [dry-run] {' '.join(cmd)}")
        return True
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"  sops --set failed: {e.stderr}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Discover Proxmox guest IPs for NetBox SOPS")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print sops commands instead of executing them")
    parser.add_argument("--sops-file", default="terraform/netbox/secrets.sops.yaml",
                        help="Path to the SOPS secrets file")
    args = parser.parse_args()

    host = os.environ.get("PROXMOX_HOST", "").rstrip("/")
    token_id = os.environ.get("PROXMOX_TOKEN_ID", "")
    token_secret = os.environ.get("PROXMOX_TOKEN_SECRET", "")

    if not (host and token_id and token_secret):
        print("Error: set PROXMOX_HOST, PROXMOX_TOKEN_ID, PROXMOX_TOKEN_SECRET", file=sys.stderr)
        sys.exit(1)

    if not args.dry_run and not os.environ.get("SOPS_AGE_KEY"):
        print("Error: SOPS_AGE_KEY is required to write to the encrypted file", file=sys.stderr)
        sys.exit(1)

    print(f"Discovering IPs for {len(DHCP_GUESTS)} DHCP guests on rabbit-01-psp...")
    found = 0
    skipped = 0

    for vmid, gtype, sops_key, node, pref in DHCP_GUESTS:
        print(f"  [{gtype} {vmid}] {sops_key} ...", end=" ", flush=True)
        if gtype == "qemu":
            ip = discover_qemu_ip(host, token_id, token_secret, node, vmid, pref)
        else:
            ip = discover_lxc_ip(host, token_id, token_secret, node, vmid, pref)

        if ip:
            print(f"→ {ip if args.dry_run else '(sensitive)'}")
            sops_set(args.sops_file, sops_key, ip, args.dry_run)
            found += 1
        else:
            print("→ unreachable / stopped (skipped)")
            skipped += 1

    print(f"\nDone: {found} IPs written, {skipped} guests unreachable.")
    if skipped:
        print("Unreachable guests remain tagged ip-discovery-pending in NetBox.")


if __name__ == "__main__":
    main()
