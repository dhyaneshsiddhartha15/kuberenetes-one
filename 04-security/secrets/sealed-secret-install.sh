#!/bin/bash

################################################################################
#                                                                              #
#   ██╗  ██╗ █████╗ ███████╗                                                  #
#   ██║ ██╔╝██╔══██╗██╔════╝                                                  #
#   █████╔╝ ╚█████╔╝███████╗                                                  #
#   ██╔═██╗ ██╔══██╗╚════██║                                                  #
#   ██║  ██╗╚█████╔╝███████║                                                  #
#   ╚═╝  ╚═╝ ╚════╝ ╚══════╝                                                  #
#   kubernetes-from-zero | by Dhyanesh Siddhartha                            #
#   "Happy K8sing! 🚀"                                                        #
#                                                                              #
################################################################################

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/../../scripts/common.sh" ]; then
    source "${SCRIPT_DIR}/../../scripts/common.sh"
fi

# Color variables (fallback if common.sh not sourced)
if [ -z "${RED}" ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m';
fi

print_banner

log_info "🔒 Dhyanesh says: Let's secure those secrets!"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "✗ kubectl not found"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    log_info "📦 Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

################################################################################
# STEP 1: Add Sealed Secrets Helm Repository
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Adding Sealed Secrets Repository")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Adding Sealed Secrets repository..."
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets --force-update 2>&1 | grep -v "already exists" || true

log_success "✓ Repository added"
echo ""

################################################################################
# STEP 2: Install Sealed Secrets Controller
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 2: Installing Sealed Secrets Controller")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Creating namespace..."
kubectl create namespace sealed-secrets --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || true

log_info "📦 Installing Sealed Secrets controller..."
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
    --namespace sealed-secrets \
    --set fullnameOverride=sealed-secrets-controller

log_success "✓ Sealed Secrets controller installed"
echo ""

################################################################################
# STEP 3: Wait for Controller to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Waiting for Controller to Start")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for controller pod..."
sleep 5

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sealed-secrets-controller -n sealed-secrets --timeout=60s

log_success "✓ Controller is ready"
echo ""

################################################################################
# STEP 4: Download kubeseal CLI
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 4: Installing kubeseal CLI")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Detecting architecture..."
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
    *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

KUBESEAL_VERSION="0.24.0"
log_info "📦 Downloading kubeseal ${KUBESEAL_VERSION} for ${OS}-${ARCH}..."

curl -fsSL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${OS}-${ARCH}" -o /tmp/kubeseal

chmod +x /tmp/kubeseal

# Try to install to /usr/local/bin (requires sudo)
if sudo -n true 2>/dev/null; then
    sudo mv /tmp/kubeseal /usr/local/bin/kubeseal
    log_success "✓ kubeseal installed to /usr/local/bin/kubeseal"
else
    log_warn "⚠️  Cannot install to /usr/local/bin (need sudo)"
    log_info "Installing to ~/.local/bin instead..."
    mkdir -p ~/.local/bin
    mv /tmp/kubeseal ~/.local/bin/kubeseal

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "" >> ~/.bashrc
        echo "# Add ~/.local/bin to PATH" >> ~/.bashrc
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
        log_info "Added ~/.local/bin to PATH in ~/.bashrc"
    fi
    log_success "✓ kubeseal installed to ~/.local/bin/kubeseal"
fi

echo ""

################################################################################
# STEP 5: Verify Installation
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 5: Verification")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking kubeseal version..."
kubeseal --version

echo ""

log_info "🔍 Checking controller status..."
kubectl get pods -n sealed-secrets

echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Sealed Secrets installed successfully!"
echo ""
log_info "📋 How to use Sealed Secrets:"
echo ""
echo -e "  ${CYAN}1. Create a regular Secret:${NC}"
echo "     kubectl create secret generic my-secret \\"
echo "       --from-literal=password=secret123 \\"
echo "       --dry-run=client -o yaml > my-secret.yaml"
echo ""
echo -e "  ${CYAN}2. Seal the secret:${NC}"
echo "     kubeseal -f my-secret.yaml -w my-sealed-secret.yaml"
echo ""
echo -e "  ${CYAN}3. Commit to Git:${NC}"
echo "     git add my-sealed-secret.yaml"
echo "     git commit -m 'Add sealed secret'"
echo ""
echo -e "  ${CYAN}4. Apply to cluster:${NC}"
echo "     kubectl apply -f my-sealed-secret.yaml"
echo ""
log_info "🎉 Dhyanesh says: Your secrets are now safe for Git! 🔒"
echo ""
