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

log_info "🚀 Dhyanesh says: Time to install the heart of Kubernetes — kubeadm!"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root (use sudo)"
    exit 1
fi

# Kubernetes version to install
K8S_VERSION="v1.30"

################################################################################
# STEP 1: Add Kubernetes Apt Repository
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Adding Kubernetes Repository")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Installing apt-transport-https and curl..."
apt-get update >/dev/null 2>&1
apt-get install -y apt-transport-https ca-certificates curl gpg >/dev/null 2>&1

log_info "📦 Downloading Kubernetes GPG key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

log_info "📦 Adding Kubernetes apt repository..."
echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ \
  /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update >/dev/null 2>&1

log_success "✓ Kubernetes repository added"
echo ""

################################################################################
# STEP 2: Install Kubernetes Components
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Installing kubeadm, kubelet, kubectl")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Installing Kubernetes packages..."
apt-get install -y kubelet kubeadm kubectl >/dev/null 2>&1

log_success "✓ Packages installed:"
echo -e "    ${CYAN}•${NC} kubelet - the node agent"
echo -e "    ${CYAN}•${NC} kubeadm - the cluster bootstrapper"
echo -e "    ${CYAN}•${NC} kubectl - the command line tool"

# Pin versions to prevent auto-upgrades
log_info "📦 Pinning package versions..."
apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1

log_success "✓ Package versions pinned (won't auto-upgrade)"
echo ""

################################################################################
# STEP 3: Enable and Start Kubelet
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Starting Kubelet Service")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Enabling kubelet service..."
systemctl enable kubelet >/dev/null 2>&1

# Note: kubelet will be in a failed/inactive state until kubeadm init is run
# This is normal and expected
log_info "📦 Starting kubelet service..."
systemctl start kubelet 2>/dev/null || true

log_success "✓ Kubelet service enabled"
echo -e "    ${YELLOW}⚠${NC} Note: kubelet may show errors until cluster is initialized"
echo ""

################################################################################
# STEP 4: Verification
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Verification")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking installed versions..."

KUBEADM_VERSION=$(kubeadm version -o short)
KUBELET_VERSION=$(kubelet --version | grep -oP 'Kubernetes\h+\K[0-9.]+')
KUBECTL_VERSION=$(kubectl version --client --short | grep -oP 'Client\h+Version:\h+\K[v0-9.]+' || kubectl version --client -o json | grep -oP '"gitVersion":"\K[^"]+')

log_success "✓ Component versions:"
echo -e "    ${CYAN}•${NC} kubeadm: ${BOLD}$KUBEADM_VERSION${NC}"
echo -e "    ${CYAN}•${NC} kubelet: ${BOLD}$KUBELET_VERSION${NC}"
echo -e "    ${CYAN}•${NC} kubectl: ${BOLD}$KUBECTL_VERSION${NC}"
echo ""

log_info "🔍 Checking kubelet service status..."
if systemctl is-enabled --quiet kubelet; then
    log_success "✓ Kubelet is enabled"
else
    log_error "✗ Kubelet is not enabled"
fi
echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Kubernetes components installed successfully!"
echo ""
log_info "🚀 Next step: Run ${CYAN}sudo bash 03-init-control-plane.sh${NC} (on control plane)"
echo ""
log_info "🚀 For worker nodes: Run ${CYAN}sudo bash 04-join-worker.sh${NC} after control plane is ready"
echo ""
log_info "🎉 Dhyanesh says: You're doing great! The cluster is almost alive. 🔥"
echo ""
