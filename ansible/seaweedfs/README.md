# SeaweedFS LXC deployment

This playbook installs SeaweedFS on the two Proxmox LXC containers created by Terraform:

- `seaweedfs-rabbit` on `rabbit-01-psp`
- `seaweedfs-hpelvisor` on `hpelvisor`

Both nodes run:

- `seaweedfs-master` on port `9333`
- `seaweedfs-volume` on port `8080`
- `seaweedfs-filer` on port `8888`

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

Add the Docker quorum master to the LXC services by passing its stable address:

```bash
ansible-playbook -i inventory.yml playbook.yml \
  -e '{"seaweedfs_external_master_peers":["<quorum-master-ip-or-dns>:9333"]}'
```

## Notes

Two master nodes are enough to run the requested two-node topology, but they are not an ideal HA quorum. For production-grade master availability, add a third small master node and include it via `seaweedfs_external_master_peers` or as another inventory host.
