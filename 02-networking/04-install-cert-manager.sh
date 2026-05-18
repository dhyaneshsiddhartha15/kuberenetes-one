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
source "${SCRIPT_DIR}/../../scripts/common.sh"

print_banner

log_info "🚀 Dhyanesh says: Let's get automatic TLS certificates!"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "✗ kubectl not found. Please complete cluster setup first"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    log_info "📦 Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_success "✓ Helm installed"
fi

# Your email for Let's Encrypt
DEFAULT_EMAIL="admin@example.com"
read -p "Enter your email for Let's Encrypt certificates [$DEFAULT_EMAIL]: " LETSENCRYPT_EMAIL
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-$DEFAULT_EMAIL}

################################################################################
# STEP 1: Add cert-manager Helm Repository
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Adding cert-manager Repository")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Adding cert-manager repository..."
helm repo add jetstack https://charts.jetstack.io --force-update 2>&1 | grep -v "already exists" || true

log_success "✓ cert-manager repository added"
echo ""

################################################################################
# STEP 2: Install cert-manager CRDs
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 2: Installing cert-manager CRDs")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Applying cert-manager Custom Resource Definitions..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.0/cert-manager.crds.yaml

log_success "✓ CRDs installed"
echo ""

################################################################################
# STEP 3: Install cert-manager via Helm
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 3: Installing cert-manager")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Creating cert-manager namespace..."
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || true

log_info "📦 Installing cert-manager via Helm..."
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.15.0 \
    --set installCRDs=true

log_success "✓ cert-manager installed via Helm"
echo ""

################################################################################
# STEP 4: Wait for cert-manager Pods to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Waiting for cert-manager to Start")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for cert-manager pods to be ready..."

wait_for_pods "cert-manager" 120

if [ $? -eq 0 ]; then
    log_success "✓ All cert-manager pods are Running!"
else
    log_warn "⚠️  Some cert-manager pods may not be ready yet"
fi
echo ""

################################################################################
# STEP 5: Apply ClusterIssuer Resources
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 5: Configuring Let's Encrypt Issuers")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Applying Let's Encrypt ClusterIssuers..."

# Apply staging issuer first (for testing)
sed "s/EMAIL_PLACEHOLDER/${LETSENCRYPT_EMAIL}/g" "${SCRIPT_DIR}/clusterissuer-staging.yaml" | kubectl apply -f -

log_success "✓ Staging ClusterIssuer applied"

# Apply production issuer
sed "s/EMAIL_PLACEHOLDER/${LETSENCRYPT_EMAIL}/g" "${SCRIPT_DIR}/clusterissuer-production.yaml" | kubectl apply -f -

log_success "✓ Production ClusterIssuer applied"
echo ""

################################################################################
# STEP 6: Verify ClusterIssuers
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 6: Verification")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking ClusterIssuers..."
echo ""

kubectl get clusterissuer

echo ""

# Wait for issuers to be ready
log_info "Waiting for ClusterIssuers to become Ready..."
sleep 5

kubectl wait --for=condition=Ready clusterissuer/letsencrypt-staging --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=Ready clusterissuer/letsencrypt-production --timeout=60s 2>/dev/null || true

echo ""

log_info "🔍 cert-manager Pods:"
echo ""

kubectl get pods -n cert-manager

echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ cert-manager installed successfully!"
echo ""
log_info "📋 What cert-manager does:"
echo -e "  ${CYAN}•${NC} Automatically provisions TLS certificates from Let's Encrypt"
echo -e "  ${CYAN}•${NC} Renews certificates before they expire"
echo -e "  ${CYAN}•${NC} Integrates with Ingress resources"
echo ""
log_info "📋 ClusterIssuers configured:"
echo -e "  ${CYAN}•${NC} letsencrypt-staging - For testing (no rate limits)"
echo -e "  ${CYAN}•${NC} letsencrypt-production - For real certificates"
echo ""
log_info "📋 How to use in Ingress:"
echo -e "  Add these annotations to your Ingress:"
echo -e "  ${CYAN}cert-manager.io/cluster-issuer:${NC} letsencrypt-production"
echo -e "  ${CYAN}cert-manager.io/acme-challenge-type:${NC} http01"
echo ""
log_info "🚀 Next step: Test connectivity with ${CYAN}bash 05-test-connectivity.sh${NC}"
echo ""
log_info "🎉 Dhyanesh says: Automatic HTTPS! Your cluster is secure now 🔒"
echo ""
