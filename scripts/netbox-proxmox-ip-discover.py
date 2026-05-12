#!/usr/bin/env python3
"""
NetBox Proxmox IP Discovery Script

Discovers live IP addresses for DHCP-assigned guests across rabbit-01-psp,
gozzi-pve and hpelvisor, then writes the results into secrets.sops.yaml.

Usage:
    # Discover rabbit-01-psp guests (default):
    export PROXMOX_HOST=https://rabbit-01-psp.example.com:8006
    export PROXMOX_TOKEN_ID=root@pam!netbox-discover
    export PROXMOX_TOKEN_SECRET=<secret>
    python scripts/netbox-proxmox-ip-discover.py [--dry-run]

    # Discover Bio Rack (gozzi-pve + hpelvisor):
    export PROXMOX_HOST_BIO=https://gozzi-01-lug.example.com:8006
    export PROXMOX_TOKEN_ID_BIO=root@pam!netbox-discover
    export PROXMOX_TOKEN_SECRET_BIO=<secret>
    python scripts/netbox-proxmox-ip-discover.py --bio [--dry-run]

    # Discover all hosts:
    python scripts/netbox-proxmox-ip-discover.py --all [--dry-run]

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


# Format: (vmid, type, sops_key, node, preferred_interface)
# type: "qemu" or "lxc"
# preferred_interface: prefix to prefer (e.g. "eth", "ens", "Port")

DHCP_GUESTS_RABBIT = [
    # VMs (QEMU) on rabbit-01-psp
    (501, "qemu", "vms.web1_vm", "rabbit-01-psp", "eth"),
    (601, "qemu", "vms.rtmp1_vm", "rabbit-01-psp", "eth"),
    (101, "qemu", "vms.debian_desktop", "rabbit-01-psp", "eth"),
    (105, "qemu", "vms.3cx", "rabbit-01-psp", "eth"),
    (104, "qemu", "vms.squid_vm", "rabbit-01-psp", "eth"),
    (1001, "qemu", "vms.mail2_bioadventures", "rabbit-01-psp", "eth"),
    (100, "qemu", "vms.sophosxg_vm", "rabbit-01-psp", "Port"),
    (103, "qemu", "vms.docker_vm", "rabbit-01-psp", "eth"),
    (102, "qemu", "vms.k3s_vm", "rabbit-01-psp", "eth"),
    # LXCs on rabbit-01-psp
    (806, "lxc", "vms.satisfactory_shared_lxc", "rabbit-01-psp", "eth"),
    (805, "lxc", "vms.satisfactory_lxc", "rabbit-01-psp", "eth"),
    (803, "lxc", "vms.rtmp1_lxc", "rabbit-01-psp", "eth"),
    (808, "lxc", "vms.mon_bgy_lxc", "rabbit-01-psp", "eth"),
    (809, "lxc", "vms.seaweedfs_rabbit_lxc", "rabbit-01-psp", "eth"),
]

DHCP_GUESTS_BIO = [
    # VMs on gozzi-pve (static: kubenuc-m2=102 is already in SOPS)
    (800, "qemu", "vms.okd_singlenode", "gozzi-pve", "eth"),
    (204, "qemu", "vms.3cx_bioadventures", "gozzi-pve", "eth"),
    (1000, "qemu", "vms.pve_backup", "gozzi-pve", "eth"),
    # LXC on gozzi-pve
    (801, "lxc", "vms.mon_lug_lxc", "gozzi-pve", "eth"),
    # VMs on hpelvisor (static: gitlab=700 is already in SOPS)
    (3000, "qemu", "vms.gen8_runner", "hpelvisor", "eth"),
    (703, "qemu", "vms.sensor_debian12", "hpelvisor", "eth"),
    (7003, "qemu", "vms.pelican_game", "hpelvisor", "eth"),
    (601, "qemu", "vms.prod_k3s_worker1", "hpelvisor", "eth"),
    (702, "qemu", "vms.sensor_ubuntu24", "hpelvisor", "eth"),
    (600, "qemu", "vms.prod_k3s_master", "hpelvisor", "eth"),
    (7000, "qemu", "vms.amp_game", "hpelvisor", "eth"),
    # LXCs on hpelvisor
    (701, "lxc", "vms.dolibarr_test", "hpelvisor", "eth"),
    (704, "lxc", "vms.seaweedfs_hpelvisor", "hpelvisor", "eth"),
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


def run_discovery(guests, host, token_id, token_secret, sops_file, dry_run):
    found = 0
    skipped = 0
    for vmid, gtype, sops_key, node, pref in guests:
        print(f"  [{gtype} {vmid}] {sops_key} ...", end=" ", flush=True)
        if gtype == "qemu":
            ip = discover_qemu_ip(host, token_id, token_secret, node, vmid, pref)
        else:
            ip = discover_lxc_ip(host, token_id, token_secret, node, vmid, pref)

        if ip:
            print(f"→ {ip if dry_run else '(sensitive)'}")
            sops_set(sops_file, sops_key, ip, dry_run)
            found += 1
        else:
            print("→ unreachable / stopped (skipped)")
            skipped += 1
    return found, skipped


def main():
    parser = argparse.ArgumentParser(description="Discover Proxmox guest IPs for NetBox SOPS")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print sops commands instead of executing them")
    parser.add_argument("--sops-file", default="terraform/netbox/secrets.sops.yaml",
                        help="Path to the SOPS secrets file")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--bio", action="store_true",
                       help="Discover Bio Rack guests (gozzi-pve + hpelvisor)")
    group.add_argument("--all", action="store_true",
                       help="Discover all hosts (rabbit + Bio Rack)")
    args = parser.parse_args()

    do_rabbit = not args.bio
    do_bio = args.bio or args.all

    if not args.dry_run and not os.environ.get("SOPS_AGE_KEY"):
        print("Error: SOPS_AGE_KEY is required to write to the encrypted file", file=sys.stderr)
        sys.exit(1)

    total_found = 0
    total_skipped = 0

    if do_rabbit:
        host = os.environ.get("PROXMOX_HOST", "").rstrip("/")
        token_id = os.environ.get("PROXMOX_TOKEN_ID", "")
        token_secret = os.environ.get("PROXMOX_TOKEN_SECRET", "")
        if not (host and token_id and token_secret):
            print("Error: set PROXMOX_HOST, PROXMOX_TOKEN_ID, PROXMOX_TOKEN_SECRET", file=sys.stderr)
            sys.exit(1)
        print(f"Discovering {len(DHCP_GUESTS_RABBIT)} DHCP guests on rabbit-01-psp...")
        f, s = run_discovery(DHCP_GUESTS_RABBIT, host, token_id, token_secret,
                             args.sops_file, args.dry_run)
        total_found += f
        total_skipped += s

    if do_bio:
        host = os.environ.get("PROXMOX_HOST_BIO", "").rstrip("/")
        token_id = os.environ.get("PROXMOX_TOKEN_ID_BIO", "")
        token_secret = os.environ.get("PROXMOX_TOKEN_SECRET_BIO", "")
        if not (host and token_id and token_secret):
            print("Error: set PROXMOX_HOST_BIO, PROXMOX_TOKEN_ID_BIO, PROXMOX_TOKEN_SECRET_BIO",
                  file=sys.stderr)
            sys.exit(1)
        print(f"Discovering {len(DHCP_GUESTS_BIO)} DHCP guests on Bio Rack (gozzi-pve + hpelvisor)...")
        f, s = run_discovery(DHCP_GUESTS_BIO, host, token_id, token_secret,
                             args.sops_file, args.dry_run)
        total_found += f
        total_skipped += s

    print(f"\nDone: {total_found} IPs written, {total_skipped} guests unreachable.")
    if total_skipped:
        print("Unreachable guests remain tagged ip-discovery-pending in NetBox.")


if __name__ == "__main__":
    main()
