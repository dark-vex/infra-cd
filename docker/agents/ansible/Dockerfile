FROM python:3.14-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    openssh-client \
    sshpass \
    jq \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible and tools
# ansible==10.* pulled ansible-core 2.17, which ansible-compat refuses to
# run under this image's Python 3.14 (requires ansible-core >= 2.20) —
# molecule/ansible-lint could not even start. Unpinned so pip resolves a
# current ansible-core compatible with the base image's Python version.
RUN pip install --no-cache-dir \
    ansible \
    ansible-lint \
    molecule \
    molecule-plugins[docker] \
    docker \
    netaddr \
    jmespath \
    paramiko

# Install commonly used Ansible collections
# community.sops is unpinned (not tracked by Renovate — collection versions
# aren't in its ecosystem coverage) — same manual-pin rationale as
# teleport_version in the ansible roles. Re-pin explicitly if a future
# version breaks the sops vars plugin.
RUN ansible-galaxy collection install \
    community.general \
    community.postgresql \
    ansible.posix \
    kubernetes.core \
    community.sops

# Install the real sops binary (community.sops.sops shells out to it, does
# not reimplement decryption). Version pinned manually — Renovate does not
# track this, same as teleport_version (see ansible/CLAUDE.md). Checksums
# are the published sha256 values from the v3.13.2 release's
# sops-v3.13.2.checksums.txt, verified before use.
RUN SOPS_VERSION=3.13.2 && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) SOPS_SHA256=154dfe4cd70554bdd82b98e4cd4acf191d43d01ead6f00a73477aa44c4ac42ef ;; \
      arm64) SOPS_SHA256=78abf2e15c86250a1553ae6f53aba96be6b2a8126f160b1534959add3467ad76 ;; \
      *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /usr/local/bin/sops \
      "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" && \
    echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c - && \
    chmod +x /usr/local/bin/sops && \
    sops --version

WORKDIR /workspace
