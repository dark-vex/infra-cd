# SeaweedFS LXC deployment

This playbook installs SeaweedFS on the two Proxmox LXC containers created by Terraform:

- `seaweedfs-rabbit` on `rabbit-01-psp`
- `seaweedfs-hpelvisor` on `hpelvisor`

By default the first inventory host runs the SeaweedFS master, and both nodes
run data services:

- `seaweedfs-master` on port `9333` plus gRPC port `19333` on the first inventory host
- `seaweedfs-volume` on port `8080`
- `seaweedfs-filer` on port `8888`
- `seaweedfs-admin` on port `23646` on master hosts

The default replication is `100`, which means SeaweedFS keeps one additional replica in a different data center. The inventory therefore labels the two LXCs as different data centers:

- `bgy` for `seaweedfs-rabbit`
- `lug` for `seaweedfs-hpelvisor`

## Usage

Update `inventory.yml` with the DHCP addresses assigned to the LXCs, then run:

```bash
ansible-playbook -i inventory.yml playbook.yml
```

The playbook connects as the `ansible` user (`seaweedfs_ansible_user`) and uses
`become`. On a new LXC that user does not exist yet; create it once, as root,
with the bootstrap play, which connects as root on its own (a 1Password Connect session is required, see
`ansible/CLAUDE.md`):

```bash
ansible-playbook -i inventory.yml bootstrap.yml --check --diff --limit <host>
ansible-playbook -i inventory.yml bootstrap.yml --limit <host>
```

It creates the user, authorizes exactly the two managed public keys (read from
1Password) and adds a validated passwordless sudoers drop-in. Root SSH is left
enabled on the LXCs.

Override the SeaweedFS version when needed. The archive is verified against
`seaweedfs_download_checksum`, so override both together:

```bash
ansible-playbook -i inventory.yml playbook.yml \
  -e seaweedfs_version=4.23 -e seaweedfs_download_checksum=sha256:<digest>
```

### Download checksum

Upstream publishes only `.md5` files, so the pinned value is the sha256 digest
GitHub exposes for each release asset. A version bump needs a matching checksum
bump in `group_vars/seaweedfs.yml`:

```bash
gh api repos/seaweedfs/seaweedfs/releases/tags/<version> \
  --jq '.assets[] | select(.name == "linux_amd64.tar.gz") | .digest'
```

The `seaweedfs-checksum` workflow compares the pinned value with that digest on
every PR touching the file, so a Renovate version bump that forgets the checksum
fails the PR check instead of a deploy. Molecule sets the checksum to an empty
string because its stub tarball has no real digest.

SeaweedFS requires an odd number of masters. To run a three-master quorum, set
an odd-sized list of inventory master hosts and/or add external master peers:

```bash
ansible-playbook -i inventory.yml playbook.yml \
  -e '{"seaweedfs_master_hosts":["seaweedfs-rabbit","seaweedfs-hpelvisor"],"seaweedfs_external_master_peers":["<quorum-master-ip-or-dns>:9333"]}'
```

## Notes

Two master nodes are not supported by SeaweedFS. Keep the default single-master
topology, or add a third small master and include it via
`seaweedfs_external_master_peers` or as another inventory host.

All volume and filer nodes must be able to reach every configured master on the
HTTP port `9333` and the master gRPC port `19333`. Cross-site replication will
not work if routing or firewall policy blocks those ports between sites.

The Admin UI is a separate `weed admin` process, not the classic Master UI.
Open it at `http://<master-ip>:23646` after the playbook converges. It also
uses gRPC on port `33646` for worker connections.

## Testing

Molecule covers the role with two Debian 12 systemd containers, a master and a
worker. From `docker/agents`:

```bash
docker compose exec -w /workspace/ansible/seaweedfs ansible-agent molecule test
```

The `weed` binary is stubbed with a fake tarball built in `prepare.yml`, so the
test proves unit rendering, the master versus non-master handling (including
removal of stale master and admin units), the topology and OS asserts, and
idempotence. It does not prove the real GitHub download or a working cluster.
