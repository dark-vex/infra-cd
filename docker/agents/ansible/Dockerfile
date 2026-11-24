FROM python:3.15-slim

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
    paramiko \
    pynetbox

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
    community.sops \
    netbox.netbox \
    community.zabbix \
    ansible.netcommon \
    community.docker

# Install the real sops binary (community.sops.sops shells out to it, does
# not reimplement decryption). Version tracked by Renovate together with
# awx-ee/execution-environment.yml; the sha256 values are the published
# checksums from that release's sops-vX.checksums.txt, refreshed by a Renovate
# postUpgradeTask (.github/scripts/update_sops_checksums.sh) and verified
# before use.
RUN SOPS_VERSION=3.13.3 && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) SOPS_SHA256=e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b ;; \
      arm64) SOPS_SHA256=53b0abacd38ef1b12a66d6c100956691b9cefce018d91f81e73ddf7438b94d77 ;; \
      *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /usr/local/bin/sops \
      "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" && \
    echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c - && \
    chmod +x /usr/local/bin/sops && \
    sops --version

WORKDIR /workspace
