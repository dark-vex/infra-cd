#!/usr/bin/env python3
"""
Proxmox self-registration handler — invoked by a Semaphore Job Template
when a guest's cloud-init callback (docs/proxmox-modules-cloud-init-handoff-
plan.md's `additional_runcmd`) POSTs {token, ip} to the Semaphore webhook.

Trust boundary (read before changing anything below): the ONLY two fields
ever read from the incoming webhook payload are the token and the guest's
self-reported ip. Every other value used — NetBox resource addresses, the
sops key, node/vmid — comes from `registration_manifest`, a Terraform
output fetched server-side from the matching `terraform/proxmox/*` tree.
The manifest stores a hash of each guest's token, never the raw token, so a
match here only ever proves "this caller holds a value whose hash we
already had on file" — the request body's own claims about who it is are
never trusted for anything past that. See the self-registration plan's
Design §1 for the injection-vector rationale this enforces.

Not yet wired up (do not treat as done):
- terraform/semaphore/main.tf has no real Integration resources yet, so the
  exact env var names a Semaphore webhook run exposes are unconfirmed —
  SELFREG_TOKEN/SELFREG_IP below are placeholders. Confirm the real mapping
  against semaphoreui_project_integration's variable-extraction config once
  that resource is authored, and update the two lookups in main() below.
- A dedicated "Semaphore" GitHub App has been created (a separate
  installation from the existing Renovate App — not reused, to keep its
  permission scope purpose-built rather than inheriting Renovate's broader
  one) and needs `contents:write` + `pull_requests:write` on this repo.
  Its App ID, installation ID, and private key still need to land in
  1Password and get wired into the Semaphore runner's manifest
  (`clusters/k8s-vms-daniele/apps/semaphore/manifests/runner.yml`) via the
  same 1Password Connect path already used there — GitHub Actions secrets
  aren't reachable from that runner, so this is a distinct provisioning
  step from how RENOVATE_APP_ID/RENOVATE_APP_PRIVATE_KEY are wired today.
- The GitHub App installation-token path (mint_installation_token) has not
  had its own live signed-commit test yet (Design §4/Verification step 2)
  — the earlier GITHUB_TOKEN-based test in this repo's history answered a
  different question (a live Actions run's own token verifies; this script
  never runs inside an Actions job, so that path is unusable here). Do not
  rely on the resulting commit showing `verification.verified: true` until
  that test has actually been run once, now against this new App's
  installation token specifically.
- **Auto-merge cannot fire as shipped.** The narrow gate's subnet/VLAN
  check (Design §5 step 6) needs an `expected_cidr` per manifest entry, and
  Design §1's manifest shape doesn't define that field yet. `main()` below
  fails safe — it leaves every PR for manual review rather than skipping
  the check — but that means the plan's headline "guest boots, PR
  auto-merges" outcome does not happen yet. Add the field to the manifest
  (or a live NetBox prefix lookup keyed off `node`) before expecting
  end-to-end auto-merge.

Env vars:
    SELFREG_TOKEN                 raw per-guest token from the webhook payload
    SELFREG_IP                    guest's self-reported IP
    NETBOX_URL / NETBOX_TOKEN     read for the idempotency check (§5 step 2)
    SOPS_AGE_KEY_NETBOX           the terraform/netbox age key (same secret name
                                  as terraform-netbox.yml uses) — sops_set()
                                  below maps this to the SOPS_AGE_KEY env var
                                  sops itself actually reads; do not rename
                                  one without the other
    GITHUB_APP_ID
    GITHUB_APP_PRIVATE_KEY_PATH   PEM file path
    GITHUB_APP_INSTALLATION_ID
    GITHUB_REPOSITORY             "owner/repo"
    TF_TOKEN_app_terraform_io     HCP Terraform token, scoped to "Read outputs
                                  only" on the terraform/proxmox/* workspaces
                                  (see Design §4) — never the full-Read
                                  personal/admin token used during this
                                  design's own live-testing.

Exit codes: 0 = handled (registered, no-op idempotent, or a clean reject of
an unknown/bogus token — all three are the normal, expected outcomes of a
webhook fire). 1 = unexpected failure (network error, manifest not
parseable, terraform fmt/validate failed, etc) — Semaphore should alert on
1, never on 0.

Requires on PATH: terraform, sops. Requires the Python packages in
scripts/requirements-selfreg.txt (PyJWT[crypto], for the GitHub App JWT
exchange) — not part of this repo's existing ansible-agent/terraform-agent
images; provisioning them onto the Semaphore runner is part of Design §4's
"real provisioning work", not a detail to gloss over.

Must be run with the repo checked out at the tip of `main` in the current
working directory (terraform/netbox/ and terraform/proxmox/* are read and
written relative to cwd).
"""

import base64
import hashlib
import hmac
import ipaddress
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

PROXMOX_TREES = [
    "terraform/proxmox/rabbit",
    "terraform/proxmox/gozzi-hpelvisor",
    "terraform/proxmox/ec200",
]

SELF_REG_DIR = "terraform/netbox/self-registered"
SOPS_FILE = "terraform/netbox/secrets.sops.yaml"

GITHUB_API = "https://api.github.com"


# ── Step 1: manifest lookup — look up, never trust ──────────────────────────

def load_manifest_entries() -> list:
    """Fetch registration_manifest from every proxmox tree.

    An empty or missing output on a given tree is the normal day-one state
    (before any self-registering VM has been authored there yet) — treat it
    the same as "no entries from this tree", not as an error.
    """
    entries = []
    for tree in PROXMOX_TREES:
        try:
            result = subprocess.run(
                ["terraform", f"-chdir={tree}", "output", "-json", "registration_manifest"],
                check=True, capture_output=True, text=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"  [{tree}] registration_manifest output missing or tree not "
                  f"initialized, skipping: {e.stderr.strip()}", file=sys.stderr)
            continue
        try:
            manifest = json.loads(result.stdout)
        except json.JSONDecodeError as e:
            print(f"  [{tree}] registration_manifest is not valid JSON, skipping: {e}", file=sys.stderr)
            continue
        for entry in manifest or []:
            entry["_source_tree"] = tree
            entries.append(entry)
    return entries


def find_manifest_entry(token: str, entries: list):
    """Constant-time hash compare — never a raw-token equality check."""
    presented_hash = hashlib.sha256(token.encode()).hexdigest()
    for entry in entries:
        stored_hash = entry.get("token_hash", "")
        if hmac.compare_digest(presented_hash, stored_hash):
            return entry
    return None


# ── Step 2a: NetBox idempotency check (read-only) ───────────────────────────

def netbox_vm_has_primary_ip(netbox_url: str, netbox_token: str, name: str, cluster: str) -> bool:
    """Scoped by name AND cluster — NetBox VM names aren't guaranteed
    globally unique across sites/clusters, so an unscoped ?name= query risks
    matching the wrong VM (confirmed live: `cluster` accepts the cluster's
    plain name string, e.g. "rabbit-01-psp", and the response's primary_ip
    field is null when unset)."""
    url = (f"{netbox_url.rstrip('/')}/api/virtualization/virtual-machines/"
           f"?name={urllib.parse.quote(name)}&cluster={urllib.parse.quote(cluster)}")
    req = urllib.request.Request(url, headers={"Authorization": f"Token {netbox_token}"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read())
    results = data.get("results", [])
    if not results:
        return False
    return results[0].get("primary_ip") is not None


# ── Step 2b: atomic branch-create lock ───────────────────────────────────────

def local_head_sha() -> str:
    """Base the new branch on the local checkout's own HEAD, not a fresh
    GitHub API read of `main` — the file *bodies* committed later (§5) come
    from this same local checkout, so the branch's base and the local
    working tree must agree on which commit they're both starting from. If
    the checkout is stale relative to the remote `main`, that's a CI
    checkout-freshness problem to fix at the job level, not something this
    script should paper over by picking two different starting points."""
    result = subprocess.run(["git", "rev-parse", "HEAD"], check=True, capture_output=True, text=True)
    return result.stdout.strip()


def try_claim_registration_branch(repo: str, token: str, branch: str, base_sha: str) -> bool:
    """POST git/refs is atomic server-side. A 201 means we now own this
    registration; a 422 ("Reference already exists") means another run got
    there first — that IS the idempotency signal, not a prior existence
    check, so treat it as "exit clean", never as an error to retry."""
    body = json.dumps({"ref": f"refs/heads/{branch}", "sha": base_sha}).encode()
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/git/refs", data=body, method="POST",
        headers=_gh_headers(token),
    )
    try:
        with urllib.request.urlopen(req, timeout=15):
            return True
    except urllib.error.HTTPError as e:
        if e.code == 422:
            return False
        raise


def release_registration_branch(repo: str, token: str, branch: str):
    """Called only when something after the claim fails unexpectedly
    (terraform validate, sops, the Contents API commit, ...). Without this,
    a transient failure leaves the branch ref sitting there forever, and
    every future boot of this exact guest hits the 422 path in
    try_claim_registration_branch and silently no-ops — indistinguishable
    from "already successfully registered". The plan accepts a rebuilt VM
    permanently no-op'ing (Design's own deferred-items list); it does not
    accept a transient error doing the same."""
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/git/refs/heads/{branch}",
        method="DELETE",
        headers=_gh_headers(token),
    )
    try:
        with urllib.request.urlopen(req, timeout=15):
            pass
    except urllib.error.HTTPError as e:
        print(f"::warning:: failed to release branch {branch} after an error "
              f"(HTTP {e.code}) — it will need manual deletion before this "
              "guest can register again", file=sys.stderr)


# ── Step 3: HCL generation — trusted manifest values only ───────────────────

def generate_hcl(entry: dict) -> tuple:
    """Returns (relative_path, content). One dedicated new file per
    registration (not an append into ipam.tf/primary-ips.tf) — this is a
    deliberate implementation choice, not specified verbatim by the plan:
    a wholly-new file makes the narrow auto-merge gate's "exactly one new
    HCL file/block" check (Design §5 step 6) trivial to verify against a
    hand-authored file that might otherwise contain unrelated resources.
    """
    local_name = f"{entry['node']}_{entry['vmid']}_selfreg".replace("-", "_")
    vm_res = entry["netbox_vm_res"]
    iface_res = entry["netbox_iface_res"]
    sops_key = entry["sops_key"]  # e.g. "vms.rabbit_01_psp_501" -> local.ips.vms.rabbit_01_psp_501

    content = f'''# Generated by scripts/semaphore-netbox-register.py — self-registration for
# {vm_res} (node={entry["node"]}, vmid={entry["vmid"]}). Do not hand-edit;
# a rebuilt guest needs a fresh manifest entry + registration, not an edit
# here (see the self-registration plan's "VM rebuild" deferred item).

resource "netbox_ip_address" "{local_name}" {{
  ip_address   = local.ips.{sops_key}
  status       = "active"
  object_type  = "virtualization.vminterface"
  interface_id = {iface_res}.id
}}

resource "netbox_primary_ip" "{local_name}" {{
  ip_address_id      = netbox_ip_address.{local_name}.id
  virtual_machine_id = {vm_res}.id
}}
'''
    return f"{SELF_REG_DIR}/{local_name}.tf", content


def run_terraform_fmt_validate(path: str):
    subprocess.run(["terraform", "fmt", path], check=True)
    # -backend=false: validate only needs provider schemas, not R2 backend
    # credentials — this runs after the branch-create lock (see
    # release_registration_branch's caller), so it must not need any
    # network-dependent state that isn't already guaranteed available.
    subprocess.run(["terraform", "-chdir=terraform/netbox", "init", "-backend=false"], check=True)
    subprocess.run(["terraform", "-chdir=terraform/netbox", "validate"], check=True)


# ── Step 4: sops --set ───────────────────────────────────────────────────────

def sops_set(sops_key: str, ip: str):
    """sops itself reads SOPS_AGE_KEY (or SOPS_AGE_KEY_FILE), not
    SOPS_AGE_KEY_NETBOX — that's this repo's *secret* name for the same
    key (see terraform-netbox.yml). Translate here rather than requiring
    every caller to know sops's actual env var name."""
    selector = "".join(f'["{part}"]' for part in sops_key.split("."))
    env = dict(os.environ)
    if "SOPS_AGE_KEY_NETBOX" in env:
        env["SOPS_AGE_KEY"] = env["SOPS_AGE_KEY_NETBOX"]
    subprocess.run(
        ["sops", "--set", f'{selector} "{ip}"', SOPS_FILE],
        check=True, env=env,
    )


# ── Step 5: GitHub App installation token + Contents-API commit + PR ────────

def _gh_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}


def mint_installation_token() -> str:
    """JWT (app-level) -> installation access token exchange. Uses PyJWT for
    the RS256 signature — see scripts/requirements-selfreg.txt. UNVERIFIED:
    whether a Contents-API commit made with the resulting token comes back
    signed/verified has not been live-tested (see module docstring)."""
    import jwt  # PyJWT[crypto] — see scripts/requirements-selfreg.txt

    app_id = os.environ["GITHUB_APP_ID"]
    installation_id = os.environ["GITHUB_APP_INSTALLATION_ID"]
    with open(os.environ["GITHUB_APP_PRIVATE_KEY_PATH"]) as f:
        private_key = f.read()

    now = int(time.time())
    payload = {"iat": now - 60, "exp": now + 540, "iss": app_id}
    app_jwt = jwt.encode(payload, private_key, algorithm="RS256")

    req = urllib.request.Request(
        f"{GITHUB_API}/app/installations/{installation_id}/access_tokens",
        method="POST",
        headers={"Authorization": f"Bearer {app_jwt}", "Accept": "application/vnd.github+json"},
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())["token"]


def _get_file_sha(repo: str, token: str, path: str, ref: str):
    """None means the file doesn't exist on `ref` yet (a create, not an
    update) — fetched via the Contents API rather than local `git
    rev-parse` so this doesn't assume the local checkout is at the exact
    commit the branch was forked from."""
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/contents/{path}?ref={ref}",
        headers=_gh_headers(token),
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read())["sha"]
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def put_file_contents(repo: str, token: str, path: str, branch: str, message: str, local_path: str):
    with open(local_path, "rb") as f:
        content_b64 = base64.b64encode(f.read()).decode()
    sha = _get_file_sha(repo, token, path, branch)
    body = {"message": message, "content": content_b64, "branch": branch}
    if sha:
        body["sha"] = sha
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/contents/{path}",
        data=json.dumps(body).encode(), method="PUT",
        headers=_gh_headers(token),
    )
    with urllib.request.urlopen(req, timeout=15):
        pass


def open_pr(repo: str, token: str, branch: str, entry: dict) -> int:
    """`netbox_vm_name` lands directly in the PR title below. This repo's
    convention (feedback: never write full FQDNs/hostnames in PR text) means
    a manifest entry's `netbox_vm_name` must be the short NetBox name
    (e.g. "web1"), never an FQDN — enforce this at manifest-authoring time,
    not here; this script has no way to tell the difference."""
    body = (
        f"Automated NetBox self-registration for `{entry['netbox_vm_name']}` "
        f"(node `{entry['node']}`, vmid `{entry['vmid']}`).\n\n"
        "Initial registration only — this does not detect or correct a "
        "later DHCP reassignment for this guest; see the self-registration "
        "plan's accepted-gaps section.\n\n"
        "No hostnames/FQDNs or plaintext IPs are included in this "
        "description — see the diff (sops value stays encrypted)."
    )
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/pulls",
        data=json.dumps({
            "title": f"chore(netbox): self-register {entry['netbox_vm_name']}",
            "body": body,
            "base": "main",
            "head": branch,
        }).encode(),
        method="POST",
        headers=_gh_headers(token),
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())["number"]


# ── Step 6: narrow auto-merge gate ───────────────────────────────────────────

def ip_in_expected_subnet(ip: str, expected_cidr: str) -> bool:
    try:
        return ipaddress.ip_address(ip) in ipaddress.ip_network(expected_cidr)
    except ValueError:
        return False


def _sops_diff_is_single_value_replacement(compare: dict) -> bool:
    """(b) the changed sops key matches what step 3/4 just wrote — i.e. the
    diff is a single ENC[...] value swapped for another, never a structural
    change (added/removed keys, reordered blocks). sops always rewrites its
    own `mac:` line on every write regardless of what changed, so that line
    is excluded from the count on both sides (same approach the abandoned
    polling pipeline's own gate used, stashed at stash@{0} in this repo's
    reflog if the exact shape is needed again)."""
    patch = next((f.get("patch", "") for f in compare.get("files", []) if f["filename"] == SOPS_FILE), None)
    if patch is None:
        return False
    removed = [l for l in patch.splitlines() if l.startswith("-") and "ENC[" in l and "mac:" not in l]
    added = [l for l in patch.splitlines() if l.startswith("+") and "ENC[" in l and "mac:" not in l]
    return len(removed) == 1 and len(added) == 1


def narrow_gate_and_automerge(repo: str, token: str, pr_number: int, branch: str,
                               hcl_path: str, ip: str, expected_cidr: str):
    """(a) diff touches only SOPS_FILE + the one new HCL file, (b) the
    changed sops key is a single value replacement (never a structural
    change), (c) the IP is syntactically valid AND falls inside the VM's
    expected subnet/VLAN (cross-checked against NetBox's prefix, not just
    regex-validated). Anything else: leave the PR for manual review."""
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/compare/main...{branch}",
        headers=_gh_headers(token),
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        compare = json.loads(resp.read())
    changed = sorted(f["filename"] for f in compare.get("files", []))
    only_expected = changed == sorted([SOPS_FILE, hcl_path])
    sops_diff_ok = _sops_diff_is_single_value_replacement(compare)

    ip_ok = ip_in_expected_subnet(ip, expected_cidr)

    if only_expected and sops_diff_ok and ip_ok:
        merge_req = urllib.request.Request(
            f"{GITHUB_API}/repos/{repo}/pulls/{pr_number}/merge",
            data=json.dumps({"merge_method": "squash"}).encode(),
            method="PUT",
            headers=_gh_headers(token),
        )
        # NOTE: this fires the merge immediately rather than toggling GitHub's
        # auto-merge flag (which needs a GraphQL mutation, not exposed via
        # this REST call) — acceptable since by this point every required
        # check this PR needs has already been evaluated inline, above.
        # Confirm against real branch-protection required-checks config
        # before relying on this timing.
        with urllib.request.urlopen(merge_req, timeout=15):
            pass
        return True

    comment_req = urllib.request.Request(
        f"{GITHUB_API}/repos/{repo}/issues/{pr_number}/comments",
        data=json.dumps({
            "body": "Narrow auto-merge gate did not pass "
                    f"(files_ok={only_expected}, sops_diff_ok={sops_diff_ok}, "
                    f"ip_in_expected_subnet={ip_ok}) — needs manual review before merging."
        }).encode(),
        method="POST",
        headers=_gh_headers(token),
    )
    with urllib.request.urlopen(comment_req, timeout=15):
        pass
    return False


# ── main ──────────────────────────────────────────────────────────────────

def main() -> int:
    token = os.environ.get("SELFREG_TOKEN", "")
    ip = os.environ.get("SELFREG_IP", "")
    if not token or not ip:
        print("SELFREG_TOKEN/SELFREG_IP not set — nothing to do", file=sys.stderr)
        return 1

    entries = load_manifest_entries()
    entry = find_manifest_entry(token, entries)
    if entry is None:
        print("no manifest entry matches the presented token — rejecting cleanly "
              "(this is the expected outcome for an unknown/bogus/day-one-empty-manifest token)")
        return 0

    netbox_url = os.environ["NETBOX_URL"]
    netbox_token = os.environ["NETBOX_TOKEN"]
    if netbox_vm_has_primary_ip(netbox_url, netbox_token, entry["netbox_vm_name"], entry["node"]):
        print(f"{entry['netbox_vm_name']} already has a NetBox primary IP — no-op (reboot after merge)")
        return 0

    repo = os.environ["GITHUB_REPOSITORY"]
    gh_token = mint_installation_token()

    branch = f"netbox-register/{entry['node']}-{entry['vmid']}"
    base_sha = local_head_sha()
    if not try_claim_registration_branch(repo, gh_token, branch, base_sha):
        print(f"branch {branch} already exists — another run already owns this "
              "registration (or a PR is already open), exiting clean")
        return 0

    # Everything from here on is fallible (terraform validate, sops, the
    # Contents API). If any of it raises, release the branch we just
    # claimed before propagating — otherwise this exact guest's next boot
    # hits the 422 path above and no-ops forever, indistinguishable from a
    # real successful registration. See release_registration_branch().
    try:
        hcl_path, hcl_content = generate_hcl(entry)
        os.makedirs(os.path.dirname(hcl_path), exist_ok=True)
        with open(hcl_path, "w") as f:
            f.write(hcl_content)
        run_terraform_fmt_validate(hcl_path)

        sops_set(entry["sops_key"], ip)

        put_file_contents(repo, gh_token, hcl_path, branch,
                           f"chore(netbox): self-register {entry['netbox_vm_name']}", hcl_path)
        put_file_contents(repo, gh_token, SOPS_FILE, branch,
                           f"chore(netbox): self-register {entry['netbox_vm_name']}", SOPS_FILE)

        pr_number = open_pr(repo, gh_token, branch, entry)
    except Exception:
        release_registration_branch(repo, gh_token, branch)
        raise

    # expected_cidr: the prefix covering this VM's subnet/VLAN in NetBox.
    # Not yet wired — the manifest shape in Design §1 doesn't carry this
    # field today; add it (or look it up live via NetBox's ipam.prefix API
    # scoped by the VM's cluster/site) before end-to-end auto-merge can
    # actually fire. Left as an explicit fail-safe rather than silently
    # skipping the subnet check, since skipping it re-opens the exact gap
    # Design §5 step 6 called out (regex-only IP validation lets a
    # compromised guest claim any address). The PR itself is already open
    # and safe to sit for manual review — no need to release the branch
    # for this case, only for genuine failures above.
    expected_cidr = entry.get("expected_cidr")
    if not expected_cidr:
        print(f"::warning:: no expected_cidr on manifest entry for {entry['netbox_vm_name']} — "
              f"leaving PR #{pr_number} for manual review rather than skipping the subnet check")
        return 0

    narrow_gate_and_automerge(repo, gh_token, pr_number, branch, hcl_path, ip, expected_cidr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
