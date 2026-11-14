# awx-ee — execution environment for the AWX Zabbix job templates (CODE-123)

Built by `.github/workflows/build-awx-ee.yml` into `ghcr.io/dark-vex/infra-cd-ee` (tag `sha-<12>`, referenced **by digest**). The AWX bootstrap registers it; a new digest reaches AWX only when `ansible/awx-zabbix-bootstrap` is re-run.

- **Why custom**: AWX's stock EE ships an old ansible-core; the roles are verified on the workstation's 2.21.x, so the same core and the same collection versions are pinned here.
- **Baked-in env**: `ANSIBLE_VARS_ENABLED` (SOPS vars plugin) and `ANSIBLE_INVENTORY_UNPARSED_FAILED=true`. AWX ignores each role's `ansible.cfg` and rejects `ANSIBLE_*` names from credential injectors, so they must live in the image. The setting is `..._UNPARSED_FAILED`; `..._UNPARSED_IS_FAILED` is silently ignored.
- **sops**: version tracked by Renovate, per-arch sha256 is not. A bump PR fails the build on a checksum mismatch until the values in `execution-environment.yml` are refreshed from the release's `sops-vX.checksums.txt`.
- **GHCR visibility**: a new package starts private. Make it public once (nothing secret inside); the workflow's anonymous-pull step fails until you do.
- **Local test** (arm64 or amd64): `ansible-builder build -f execution-environment.yml -t infra-cd-ee:local --container-runtime docker`, then run `smoke-test.sh` in it as the workflow does.
