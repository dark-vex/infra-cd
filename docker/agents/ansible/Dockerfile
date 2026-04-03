FROM python:3.14-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    sshpass \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible and tools
RUN pip install --no-cache-dir \
    ansible==10.* \
    ansible-lint \
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
