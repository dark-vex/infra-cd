#!/usr/bin/env bash

# Script per testare localmente la pipeline Kind + FluxCD
# Simula l'ambiente CI di GitHub Actions

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurazione
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind-test-local}"
FLUX_VERSION="${FLUX_VERSION:-2.4.0}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "${GREEN}=== Kind FluxCD Local Test ===${NC}"
echo "Cluster name: $KIND_CLUSTER_NAME"
echo "Current branch: $CURRENT_BRANCH"
echo ""

# Funzione per cleanup
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    kind delete cluster --name "$KIND_CLUSTER_NAME" 2>/dev/null || true
    rm -rf clusters/kubenuc-kind 2>/dev/null || true
}

# Trap per cleanup anche in caso di errore
trap cleanup EXIT

# Verifica prerequisiti
check_prerequisites() {
    echo -e "${GREEN}Checking prerequisites...${NC}"

    if ! command -v kind &> /dev/null; then
        echo -e "${RED}ERROR: kind not found. Install from https://kind.sigs.k8s.io/${NC}"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}ERROR: kubectl not found${NC}"
        exit 1
    fi

    if ! command -v flux &> /dev/null; then
        echo -e "${RED}ERROR: flux CLI not found. Installing...${NC}"
        curl -s https://fluxcd.io/install.sh | bash -s ${FLUX_VERSION}
    fi

    echo -e "${GREEN}✓ All prerequisites met${NC}"
}

# Crea cluster kind
create_cluster() {
    echo -e "${GREEN}Creating kind cluster: $KIND_CLUSTER_NAME${NC}"

    cat <<EOF | kind create cluster --name "$KIND_CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
EOF

    echo -e "${GREEN}✓ Cluster created${NC}"
}

# Genera overlay per test
generate_test_overlay() {
    echo -e "${GREEN}Generating test overlay in clusters/kubenuc-kind/${NC}"

    # Crea struttura base
    mkdir -p clusters/kubenuc-kind/flux-system
    mkdir -p clusters/kubenuc-kind/apps

    # Copia componenti flux
    cp clusters/kubenuc/flux-system/gotk-components.yaml clusters/kubenuc-kind/flux-system/

    # Crea gotk-sync.yaml con branch corrente
    cat > clusters/kubenuc-kind/flux-system/gotk-sync.yaml <<EOF
# This manifest was generated for kind local testing
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: ${CURRENT_BRANCH}
  url: https://github.com/dark-vex/infra-cd.git
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./clusters/kubenuc-kind
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
EOF

    cat > clusters/kubenuc-kind/flux-system/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
EOF

    # Copia apps e charts
    cp clusters/kubenuc/apps.yaml clusters/kubenuc-kind/
    cp clusters/kubenuc/charts.yaml clusters/kubenuc-kind/

    # PostgreSQL - rimuovi pod_environment_secret
    echo -e "${YELLOW}  - Patching PostgreSQL (removing pod_environment_secret)${NC}"
    mkdir -p clusters/kubenuc-kind/apps/postgresql/manifests
    cp clusters/kubenuc/apps/postgresql/manifests/namespace.yml \
       clusters/kubenuc-kind/apps/postgresql/manifests/

    sed '/pod_environment_secret:/d' \
        clusters/kubenuc/apps/postgresql/manifests/release.yml > \
        clusters/kubenuc-kind/apps/postgresql/manifests/release.yml

    cat > clusters/kubenuc-kind/apps/postgresql/manifests/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yml
  - release.yml
EOF

    # Copia secrets e db
    if [ -d clusters/kubenuc/apps/postgresql/secrets ]; then
        cp -r clusters/kubenuc/apps/postgresql/secrets clusters/kubenuc-kind/apps/postgresql/
    fi
    if [ -d clusters/kubenuc/apps/postgresql/db ]; then
        cp -r clusters/kubenuc/apps/postgresql/db clusters/kubenuc-kind/apps/postgresql/
    fi

    # Deploy postgresql
    cat > clusters/kubenuc-kind/apps/postgresql/deploy.yaml <<EOF
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: postgresql-secrets
  namespace: flux-system
spec:
  interval: 15m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/kubenuc-kind/apps/postgresql/secrets
  prune: false
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: postgresql
  namespace: flux-system
spec:
  interval: 15m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/kubenuc-kind/apps/postgresql/manifests
  prune: false
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: postgresql-db
  namespace: flux-system
spec:
  dependsOn:
    - name: postgresql
  interval: 15m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/kubenuc-kind/apps/postgresql/db
  prune: false
EOF

    # Harbor - escludi backup
    echo -e "${YELLOW}  - Creating Harbor overlay (excluding backup)${NC}"
    mkdir -p clusters/kubenuc-kind/apps/harbor/manifests
    for file in clusters/kubenuc/apps/harbor/manifests/*.yml; do
        filename=$(basename "$file")
        if [ "$filename" != "backup.yml" ]; then
            cp "$file" clusters/kubenuc-kind/apps/harbor/manifests/
        fi
    done

    cat > clusters/kubenuc-kind/apps/harbor/manifests/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yml
  - redis.yml
  - release.yml
EOF

    # Harbor secrets (escludi backup)
    mkdir -p clusters/kubenuc-kind/apps/harbor/secrets
    for file in clusters/kubenuc/apps/harbor/secrets/*.yml; do
        filename=$(basename "$file")
        if [ "$filename" != "harbor-db-s3-backup.yml" ]; then
            cp "$file" clusters/kubenuc-kind/apps/harbor/secrets/
        fi
    done

    # Nextcloud - escludi backup
    echo -e "${YELLOW}  - Creating Nextcloud overlay (excluding backup)${NC}"
    mkdir -p clusters/kubenuc-kind/apps/nextcloud/manifests
    for file in clusters/kubenuc/apps/nextcloud/manifests/*.yml; do
        filename=$(basename "$file")
        if [ "$filename" != "backup.yml" ]; then
            cp "$file" clusters/kubenuc-kind/apps/nextcloud/manifests/
        fi
    done

    cat > clusters/kubenuc-kind/apps/nextcloud/manifests/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yml
  - release.yml
EOF

    # Nextcloud secrets (escludi backup)
    mkdir -p clusters/kubenuc-kind/apps/nextcloud/secrets
    for file in clusters/kubenuc/apps/nextcloud/secrets/*.yml; do
        filename=$(basename "$file")
        if [ "$filename" != "nextcloud-db-s3-backup.yml" ]; then
            cp "$file" clusters/kubenuc-kind/apps/nextcloud/secrets/
        fi
    done

    # Copia altre apps senza modifiche
    for app_dir in clusters/kubenuc/apps/*/; do
        app_name=$(basename "$app_dir")
        if [[ "$app_name" != "postgresql" && "$app_name" != "harbor" && \
              "$app_name" != "nextcloud" && "$app_name" != "fluxcd" ]]; then
            cp -r "$app_dir" clusters/kubenuc-kind/apps/
        fi
    done

    # Copia fluxcd app
    if [ -d clusters/kubenuc/apps/fluxcd ]; then
        cp -r clusters/kubenuc/apps/fluxcd clusters/kubenuc-kind/apps/
    fi

    # Copia charts
    if [ -d clusters/kubenuc/charts ]; then
        cp -r clusters/kubenuc/charts clusters/kubenuc-kind/
    fi

    echo -e "${GREEN}✓ Test overlay generated${NC}"
    echo ""
    echo "Overlay structure:"
    tree -L 3 clusters/kubenuc-kind/ 2>/dev/null || find clusters/kubenuc-kind -type d | head -20
}

# Installa Flux
install_flux() {
    echo -e "${GREEN}Installing Flux in cluster${NC}"
    flux install --namespace flux-system

    # Attendi che i pod siano ready
    kubectl wait --for=condition=ready pod \
        -l app=source-controller \
        -n flux-system \
        --timeout=5m

    kubectl wait --for=condition=ready pod \
        -l app=kustomize-controller \
        -n flux-system \
        --timeout=5m

    kubectl wait --for=condition=ready pod \
        -l app=helm-controller \
        -n flux-system \
        --timeout=5m

    echo -e "${GREEN}✓ Flux installed${NC}"
}

# Commit overlay to current branch
commit_overlay() {
    echo -e "${GREEN}Committing test overlay to current branch${NC}"

    # Configure git
    git config user.name "kind-flux-test"
    git config user.email "test@local"

    # Add overlay
    git add clusters/kubenuc-kind/

    if git diff --staged --quiet; then
        echo "No changes to commit"
    else
        git commit -m "ci: add ephemeral test overlay for kind cluster [skip ci]"
        echo -e "${GREEN}✓ Overlay committed (locally only, not pushed)${NC}"
    fi
}

# Bootstrap Flux
bootstrap_flux() {
    echo -e "${GREEN}Bootstrapping Flux with test overlay${NC}"

    kubectl apply -f clusters/kubenuc-kind/flux-system/gotk-sync.yaml

    echo "Waiting for GitRepository to be ready..."
    kubectl wait --for=condition=ready \
        gitrepository/flux-system \
        -n flux-system \
        --timeout=5m || true

    echo -e "${GREEN}✓ Flux bootstrapped${NC}"
}

# Verifica configurazione
verify_configuration() {
    echo -e "${GREEN}Verifying configuration${NC}"

    sleep 30  # Attendi reconciliation iniziale

    # Verifica postgres operator senza pod_environment_secret
    echo -e "${YELLOW}Checking PostgreSQL Operator...${NC}"
    if kubectl get helmrelease postgres-operator -n databases -o yaml 2>/dev/null | grep -q "pod_environment_secret"; then
        echo -e "${RED}✗ ERROR: pod_environment_secret should NOT be present!${NC}"
        return 1
    else
        echo -e "${GREEN}✓ pod_environment_secret correctly removed${NC}"
    fi

    # Verifica assenza backup CronJobs
    echo -e "${YELLOW}Checking backup CronJobs...${NC}"
    if kubectl get cronjob harbor-db-backup -n harbor 2>/dev/null; then
        echo -e "${RED}✗ ERROR: harbor-db-backup should NOT exist!${NC}"
        return 1
    else
        echo -e "${GREEN}✓ harbor-db-backup correctly excluded${NC}"
    fi

    if kubectl get cronjob nextcloud-db-backup -n nextcloud-fastnetserv 2>/dev/null; then
        echo -e "${RED}✗ ERROR: nextcloud-db-backup should NOT exist!${NC}"
        return 1
    else
        echo -e "${GREEN}✓ nextcloud-db-backup correctly excluded${NC}"
    fi

    echo -e "${GREEN}✓ All verifications passed${NC}"
}

# Mostra stato
show_status() {
    echo -e "${GREEN}=== Flux Status ===${NC}"
    flux get all -A

    echo ""
    echo -e "${GREEN}=== Pods Status ===${NC}"
    kubectl get pods -A
}

# Main
main() {
    check_prerequisites
    create_cluster
    generate_test_overlay
    commit_overlay
    install_flux
    bootstrap_flux
    verify_configuration
    show_status

    echo ""
    echo -e "${GREEN}=== Test completed successfully! ===${NC}"
    echo ""
    echo "The cluster is still running. You can interact with it:"
    echo "  kubectl get all -A"
    echo "  flux get all -A"
    echo ""
    echo "To delete the cluster:"
    echo "  kind delete cluster --name $KIND_CLUSTER_NAME"
    echo ""
    echo "To cleanup the overlay:"
    echo "  git reset --hard HEAD~1  # Remove commit"
    echo "  rm -rf clusters/kubenuc-kind"
    echo ""

    # Non eseguire cleanup automatico se tutto va bene
    trap - EXIT
}

# Esegui main
main
