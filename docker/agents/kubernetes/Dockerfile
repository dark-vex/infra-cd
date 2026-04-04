FROM alpine:3.23

ARG KUBECTL_VERSION=v1.33.3
ARG HELM_VERSION=v3.17.3
ARG FLUX_VERSION=2.7.5
ARG KUSTOMIZE_VERSION=v5.6.0

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    yq

# kubectl
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# helm
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | \
    tar xz --strip-components=1 -C /usr/local/bin linux-amd64/helm

# flux CLI
RUN curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz" | \
    tar xz -C /usr/local/bin flux

# kustomize
RUN curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | \
    tar xz -C /usr/local/bin kustomize

WORKDIR /workspace
