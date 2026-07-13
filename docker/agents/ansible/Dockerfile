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
RUN ansible-galaxy collection install \
    community.general \
    community.postgresql \
    ansible.posix \
    kubernetes.core

WORKDIR /workspace
