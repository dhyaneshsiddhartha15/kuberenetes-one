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

log_info "🚀 Dhyanesh says: Let's get those LoadBalancer IPs working!"
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

################################################################################
# STEP 1: Add MetalLB Helm Repository
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Adding MetalLB Helm Repository")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Adding MetalLB repository..."
helm repo add metallb https://metallb.github.io/metallb --force-update 2>&1 | grep -v "already exists" || true

log_success "✓ MetalLB repository added"
echo ""

################################################################################
# STEP 2: Install MetalLB via Helm
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Installing MetalLB")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Creating metallb-system namespace..."
kubectl create namespace metallb-system --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || true

log_info "📦 Installing MetalLB via Helm..."
helm upgrade --install metallb metallb/metallb \
    --namespace metallb-system \
    --set controller.replicas=1 \
    --set speaker.replicas=1

log_success "✓ MetalLB installed via Helm"
echo ""

################################################################################
# STEP 3: Wait for MetalLB Pods to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Waiting for MetalLB to Start")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for MetalLB pods to be ready..."

wait_for_pods "metallb-system" 120

if [ $? -eq 0 ]; then
    log_success "✓ All MetalLB pods are Running!"
else
    log_warn "⚠️  Some MetalLB pods may not be ready yet"
fi
echo ""

################################################################################
# STEP 4: Apply MetalLB Configuration
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 4: Configuring MetalLB IP Pool")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_warn "⚠️  Before proceeding, edit metallb-config.yaml with your LAN IP range!"
echo ""
log_info "Current configuration:"
echo ""
cat "${SCRIPT_DIR}/metallb-config.yaml"
echo ""

# Confirm with user
if ! confirm "Apply this MetalLB configuration?"; then
    log_info "Skipped. Please edit metallb-config.yaml and run this script again."
    log_info "To apply manually: kubectl apply -f 02-networking/metallb-config.yaml"
    exit 0
fi

log_info "📦 Applying MetalLB IP pool and L2 advertisement..."
kubectl apply -f "${SCRIPT_DIR}/metallb-config.yaml"

log_success "✓ MetalLB configuration applied"
echo ""

################################################################################
# STEP 5: Verify MetalLB is Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 5: Verification")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking MetalLB resources..."
echo ""

kubectl get ipaddresspool -n metallb-system
echo ""

kubectl get l2advertisement -n metallb-system
echo ""

log_info "🔍 Checking MetalLB pods..."
echo ""

kubectl get pods -n metallb-system
echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ MetalLB installed and configured!"
echo ""
log_info "📋 What MetalLB does:"
echo -e "  ${CYAN}•${NC} Assigns external IPs to LoadBalancer Services"
echo -e "  ${CYAN}•${NC} Advertises IPs via ARP (Layer 2 mode)"
echo -e "  ${CYAN}•${NC} Enables bare-metal clusters to have real external IPs"
echo ""
log_info "📋 IP Pool configured:"
kubectl get ipaddresspool -n metallb-system -o jsonpath='{.items[0].spec.addresses}' 2>/dev/null || echo "See metallb-config.yaml"
echo ""
log_info "🚀 Next step: Install ingress-nginx with ${CYAN}sudo bash 03-install-ingress-nginx.sh${NC}"
echo ""
log_info "🎉 Dhyanesh says: No more pending LoadBalancer Services! 🎊"
echo ""
