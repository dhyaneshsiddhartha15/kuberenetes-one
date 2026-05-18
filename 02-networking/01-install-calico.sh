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

log_info "🚀 Dhyanesh says: Time to plug in the network cables!"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "✗ kubectl not found. Please run 02-install-kubeadm.sh first"
    exit 1
fi

################################################################################
# STEP 1: Install Calico Operator
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Installing Calico Operator")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Downloading Calico operator manifest..."
curl -sL https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml -o /tmp/tigera-operator.yaml

log_info "📦 Applying Calico operator..."
kubectl apply -f /tmp/tigera-operator.yaml

log_success "✓ Calico operator installed"
echo ""

################################################################################
# STEP 2: Apply Custom Resources
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Configuring Calico (Dual-Stack)")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Applying Calico custom resources..."
kubectl apply -f "${SCRIPT_DIR}/calico-custom-resources.yaml"

log_success "✓ Calico configured with dual-stack IPv4 + IPv6"
echo ""

################################################################################
# STEP 3: Wait for Calico Pods to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Waiting for Calico to Start")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for Calico pods to be ready..."
log_warn "This may take 2-3 minutes. Grab a chai ☕"
echo ""

# Wait for calico-system namespace to exist
log_info "Waiting for calico-system namespace..."
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if kubectl get namespace calico-system >/dev/null 2>&1; then
        log_success "✓ calico-system namespace created"
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# Wait for pods to be ready
wait_for_pods "calico-system" 300

if [ $? -eq 0 ]; then
    log_success "✓ All Calico pods are Running!"
else
    log_warn "⚠️  Some Calico pods may not be ready yet. Check with: kubectl get pods -n calico-system"
fi
echo ""

################################################################################
# STEP 4: Verify Nodes are Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Verifying Node Readiness")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking node status..."
echo ""

kubectl get nodes

echo ""

# Check if all nodes are Ready
NOT_READY_COUNT=$(kubectl get nodes | grep -v "NAME" | grep -vc " Ready " || true)

if [ "$NOT_READY_COUNT" -eq 0 ]; then
    NODE_COUNT=$(kubectl get nodes | grep -v "NAME" | wc -l)
    log_success "✓ All $NODE_COUNT node(s) are Ready!"
else
    log_warn "⚠️  $NOT_READY_COUNT node(s) are not Ready yet"
    log_info "This is normal if nodes are still joining. Check again in a minute."
fi
echo ""

################################################################################
# STEP 5: Verify CoreDNS
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 5: Verifying CoreDNS Pods")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking CoreDNS pods..."
echo ""

kubectl get pods -n kube-system | grep coredns

echo ""

COREDNS_RUNNING=$(kubectl get pods -n kube-system | grep coredns | grep -c "Running" || true)
COREDNS_TOTAL=$(kubectl get pods -n kube-system | grep coredns | wc -l)

if [ "$COREDNS_RUNNING" -eq "$COREDNS_TOTAL" ] && [ "$COREDNS_TOTAL" -gt 0 ]; then
    log_success "✓ All CoreDNS pods are Running!"
else
    log_warn "⚠️  CoreDNS pods may still be starting. Check with: kubectl get pods -n kube-system | grep coredns"
fi
echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Calico CNI installed successfully!"
echo ""
log_info "📋 Calico components:"
echo -e "  ${CYAN}•${NC} calico-system namespace created"
echo -e "  ${CYAN}•${NC} Dual-stack pod networking enabled (IPv4 + IPv6)"
echo -e "  ${CYAN}•${NC} Network policies available for security"
echo ""
log_info "🚀 Next step: Install MetalLB with ${CYAN}sudo bash 02-install-metallb.sh${NC}"
echo ""
log_info "🎉 Dhyanesh says: Your pods can now talk to each other! 🎊"
echo ""
