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
RUN pip install --no-cache-dir \
    ansible==10.* \
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
