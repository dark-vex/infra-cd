FROM hashicorp/terraform:1.14

# Install supporting tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    python3 \
    py3-pip

# Install tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install checkov for security scanning
RUN pip3 install checkov --break-system-packages

# Install 1Password CLI
RUN OP_VERSION=$(curl -s https://app-updates.agilebits.com/check/1/0/CLI2/en/2.0.0/N -H "User-Agent: op" | jq -r '.version') && \
    curl -sSfo /tmp/op.zip "https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_VERSION}/op_linux_amd64_v${OP_VERSION}.zip" && \
    unzip /tmp/op.zip -d /usr/local/bin/ && \
    rm /tmp/op.zip

WORKDIR /workspace
