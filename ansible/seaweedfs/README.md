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

Override the SeaweedFS version when needed:

```bash
ansible-playbook -i inventory.yml playbook.yml -e seaweedfs_version=4.23
```

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
