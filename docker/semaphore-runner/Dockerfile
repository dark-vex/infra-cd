# Base is semaphoreui/runner, NOT semaphoreui/semaphore (the server image) -
# a distinct, dedicated remote-runner image purpose-built for the
# register/start bootstrap flow used by runner-entrypoint.sh. Alpine-based
# (musl), not Debian/apt like docker/agents/ansible/Dockerfile - confirmed
# by inspecting the image, do not assume the two share a package manager.
#
# Pinned to the exact app version currently deployed by the server's
# HelmRelease (clusters/k8s-vms-daniele/apps/semaphore/manifests/release.yml,
# chart 16.2.2 -> appVersion v2.18.3). The server and this runner track two
# different images now (server: semaphoreui/semaphore, runner:
# semaphoreui/runner) so they no longer need to move in lockstep the way a
# single forked image would have, but they speak the same runner protocol -
# treat every Renovate PR that bumps the server's pinned chart version as
# the trigger to also rebuild/push a matching runner image tag. See
# clusters/k8s-vms-daniele/CLAUDE.md.
FROM semaphoreui/runner:v2.19.10

# The base image already ships ansible-core plus every collection this repo
# needs (community.sops, community.general, community.postgresql,
# ansible.posix, kubernetes.core - confirmed via `ansible-galaxy collection
# list` against this exact tag) in a venv already on PATH. The one missing
# piece is the real `sops` binary: community.sops.sops shells out to it
# rather than reimplementing decryption, and the base image doesn't include
# it. Manually pinned with the same version/checksums as
# docker/agents/ansible/Dockerfile (same upstream release, same file) -
# Renovate doesn't track this, same rationale as documented there.
USER root

RUN SOPS_VERSION=3.13.2 && \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) SOPS_ARCH=amd64; SOPS_SHA256=154dfe4cd70554bdd82b98e4cd4acf191d43d01ead6f00a73477aa44c4ac42ef ;; \
      aarch64) SOPS_ARCH=arm64; SOPS_SHA256=78abf2e15c86250a1553ae6f53aba96be6b2a8126f160b1534959add3467ad76 ;; \
      *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /usr/local/bin/sops \
      "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${SOPS_ARCH}" && \
    echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c - && \
    chmod +x /usr/local/bin/sops && \
    sops --version

COPY runner-entrypoint.sh /usr/local/bin/runner-entrypoint.sh
RUN chmod +x /usr/local/bin/runner-entrypoint.sh

# Restore the base image's non-root posture (it defaults to uid 1001/gid 0).
USER 1001

# Base image's own ENTRYPOINT (/sbin/tini --, for proper signal handling
# and zombie reaping of the ansible-playbook subprocesses this spawns) is
# inherited unchanged - only CMD is replaced.
CMD ["/usr/local/bin/runner-entrypoint.sh"]
