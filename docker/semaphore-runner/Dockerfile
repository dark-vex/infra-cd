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

# The base image bundles its own `terraform` (confirmed empirically:
# v1.8.2 in the v2.19.10 tag actually pulled here, not the newer version
# suggested by reading semaphoreui/semaphore's Dockerfile source on its
# default branch — that source has moved on since this tag was cut, don't
# trust it without checking the real image). 1.8.2 is below
# terraform/netbox's own required_version (>= 1.10.0) and
# terraform/semaphore's (>= 1.11.0) — scripts/semaphore-netbox-register.py
# runs `terraform -chdir=terraform/netbox validate` inside this exact
# container, so an old bundled binary would fail that call at runtime.
# Overwrite it with a pinned modern release, same pattern as the sops
# install below (Renovate doesn't track this either).
RUN TERRAFORM_VERSION=1.15.8 && \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) TF_ARCH=amd64; TF_SHA256=d25ce7b6902013ad905db3d2eab0be4cd905887fe88b81a6171b8d5503c31f3d ;; \
      aarch64) TF_ARCH=arm64; TF_SHA256=8891e9dcedc9e3b8950bc6af9d4d8af1f4cfade3062f53b9dc403a89f6ce8c9c ;; \
      *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" && \
    echo "${TF_SHA256}  /tmp/terraform.zip" | sha256sum -c - && \
    unzip -o /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip && \
    chmod +x /usr/local/bin/terraform && \
    terraform version

# PyJWT[crypto] — needed by scripts/semaphore-netbox-register.py (the
# Proxmox self-registration task) to mint the Semaphore GitHub App's
# installation token. Installed into the SYSTEM site-packages, not the
# base image's ansible venv (/opt/semaphore/apps/ansible/<version>/venv) -
# that venv was created with --system-site-packages, so a system-level
# install is visible from inside it too, without risking a dependency
# clash with ansible's own pinned boto3/requests/etc. `python3 -m pip`
# needs --break-system-packages here: this base is Alpine 3.24, whose
# python3 enforces PEP 668 (no unmanaged pip installs outside a venv) by
# default. cryptography (PyJWT[crypto]'s dependency) has no musllinux
# wheel for this arch as of this writing - confirmed by a real build: pip
# built it from source, needing the toolchain below. Mirrors this file's
# existing sops/ansible pattern of installing build deps, running the
# install, then removing them to keep the image slim. Empirically verified
# (local `docker build` + `docker run`, this exact Dockerfile): `import
# jwt` succeeds both from bare python3 and from inside the ansible venv
# (which resolves it via --system-site-packages), and
# scripts/semaphore-netbox-register.py itself byte-compiles cleanly under
# both. Not yet verified: the script's actual runtime behavior against a
# live Semaphore task dispatch - only its imports and syntax.
RUN apk add --no-cache -U python3-dev build-base openssl-dev libffi-dev cargo && \
    python3 -m pip install --no-cache-dir --break-system-packages 'PyJWT[crypto]>=2.8' && \
    apk del python3-dev build-base openssl-dev libffi-dev cargo && \
    rm -rf /var/cache/apk/*

COPY runner-entrypoint.sh /usr/local/bin/runner-entrypoint.sh
RUN chmod +x /usr/local/bin/runner-entrypoint.sh

# Restore the base image's non-root posture (it defaults to uid 1001/gid 0).
USER 1001

# Base image's own ENTRYPOINT (/sbin/tini --, for proper signal handling
# and zombie reaping of the ansible-playbook subprocesses this spawns) is
# inherited unchanged - only CMD is replaced.
CMD ["/usr/local/bin/runner-entrypoint.sh"]
