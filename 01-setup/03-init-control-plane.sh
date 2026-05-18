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

log_info "🚀 Dhyanesh says: Let's get this cluster running!"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root (use sudo)"
    exit 1
fi

# Configuration
POD_NETWORK_CIDR_V4="192.168.0.0/16"
POD_NETWORK_CIDR_V6="fd00::/48"
SERVICE_CIDR_V4="10.96.0.0/12"
SERVICE_CIDR_V6="fd01::/108"

# Get the primary IP address of this machine
log_info "🔍 Detecting your IP address..."
NODE_IP=$(hostname -I | awk '{print $1}')

if [ -z "$NODE_IP" ]; then
    log_error "✗ Could not detect IP address. Please set NODE_IP variable manually."
    exit 1
fi

log_success "✓ Detected IP: ${BOLD}$NODE_IP${NC}"
echo ""

# Confirm with user
log_warn "⚠️  About to initialize Kubernetes control plane on this machine:"
echo -e "    ${CYAN}•${NC} Pod Network CIDR (IPv4): $POD_NETWORK_CIDR_V4"
echo -e "    ${CYAN}•${NC} Pod Network CIDR (IPv6): $POD_NETWORK_CIDR_V6"
echo -e "    ${CYAN}•${NC} Service CIDR (IPv4): $SERVICE_CIDR_V4"
echo -e "    ${CYAN}•${NC} Service CIDR (IPv6): $SERVICE_CIDR_V6"
echo -e "    ${CYAN}•${NC} API Server advertise address: ${BOLD}$NODE_IP${NC}"
echo ""

if ! confirm "Continue with control plane initialization?"; then
    log_info "Aborted by user."
    exit 0
fi

################################################################################
# STEP 1: Initialize Control Plane with kubeadm
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Initializing Control Plane")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Running kubeadm init..."
log_warn "This may take 2-5 minutes. Grab a chai ☕"
echo ""

# Run kubeadm init with dual-stack configuration
kubeadm init \
  --pod-network-cidr="${POD_NETWORK_CIDR_V4},${POD_NETWORK_CIDR_V6}" \
  --service-cidr="${SERVICE_CIDR_V4},${SERVICE_CIDR_V6}" \
  --apiserver-advertise-address="$NODE_IP" \
  --kubernetes-version="stable-1.30" \
  --ignore-preflight-errors=NumCPU 2>&1 | tee /tmp/kubeadm-init.log

# Check if init was successful
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log_success "✓ Control plane initialized successfully!"
else
    log_error "✗ Control plane initialization failed. Check /tmp/kubeadm-init.log"
    exit 1
fi
echo ""

################################################################################
# STEP 2: Set Up Kubeconfig for Current User
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Setting Up Kubeconfig")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

# Get the non-root username
SUDO_USER=${SUDO_USER:-$(whoami)}
if [ "$SUDO_USER" = "root" ]; then
    # If running as root directly, set up for root
    log_info "📦 Setting up kubeconfig for root user..."
    export KUBECONFIG=/etc/kubernetes/admin.conf
    mkdir -p /root/.kube
    cp -i /etc/kubernetes/admin.conf /root/.kube/config
    chown root:root /root/.kube/config
else
    # If running via sudo, set up for the actual user
    log_info "📦 Setting up kubeconfig for user: $SUDO_USER..."
    mkdir -p "/home/$SUDO_USER/.kube"
    cp -i /etc/kubernetes/admin.conf "/home/$SUDO_USER/.kube/config"
    chown "$SUDO_USER:$SUDO_USER" "/home/$SUDO_USER/.kube/config"

    # Also set up for root for convenience
    mkdir -p /root/.kube
    cp -i /etc/kubernetes/admin.conf /root/.kube/config
    chown root:root /root/.kube/config
fi

log_success "✓ Kubeconfig configured"
echo ""

################################################################################
# STEP 3: Save Join Command
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Saving Worker Join Command")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Generating join command for worker nodes..."

# Create join command
JOIN_CMD=$(kubeadm token create --print-join-command 2>/dev/null)
echo "$JOIN_CMD" > "${SCRIPT_DIR}/join-command.txt"

log_success "✓ Join command saved to: ${CYAN}${SCRIPT_DIR}/join-command.txt${NC}"
log_warn "⚠️  Keep this file safe! Worker nodes need this command."
echo ""

# Display the join command
log_info "📋 Worker join command:"
echo ""
echo -e "${BOLD}$JOIN_CMD${NC}"
echo ""

################################################################################
# STEP 4: Wait for Control Plane Pods to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Waiting for Control Plane Pods")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for control plane components to start..."
log_warn "Note: CoreDNS pods will be Pending until CNI is installed (next step)"
echo ""

# Use kubectl to wait for pods
export KUBECONFIG=/etc/kubernetes/admin.conf

# Wait for kube-system pods (excluding CoreDNS which needs CNI)
log_info "Waiting for system pods (this may take 2-3 minutes)..."

# Function to check if critical pods are ready
check_critical_pods() {
    local ready_count=0
    local total_count=0

    while IFS= read -r line; do
        pod_name=$(echo "$line" | awk '{print $1}')
        pod_status=$(echo "$line" | awk '{print $3}')

        # Skip DNS pods as they need CNI
        if [[ "$pod_name" =~ coredns ]]; then
            continue
        fi

        total_count=$((total_count + 1))
        if [ "$pod_status" = "Running" ]; then
            ready_count=$((ready_count + 1))
        fi
    done < <(kubectl get pods -n kube-system --no-headers 2>/dev/null)

    echo "$ready_count/$total_count"
}

# Wait up to 5 minutes
TIMEOUT=300
ELAPSED=0
INTERVAL=10

while [ $ELAPSED -lt $TIMEOUT ]; do
    status=$(check_critical_pods)
    ready=$(echo "$status" | cut -d'/' -f1)
    total=$(echo "$status" | cut -d'/' -f2)

    if [ "$ready" = "$total" ] && [ "$total" -gt 0 ]; then
        log_success "✓ All critical control plane pods are Running!"
        break
    fi

    echo -ne "\r  Progress: $status ready... (${ELAPSED}s/${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo ""
echo ""

################################################################################
# STEP 5: Display Current Status
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 5: Current Cluster Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Node status:"
kubectl get nodes
echo ""

log_info "🔍 System pods:"
kubectl get pods -n kube-system
echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Control plane is up and running!"
echo ""
log_info "🚀 Next steps:"
echo -e "  1. Install CNI plugin: ${CYAN}cd ../02-networking && sudo bash 01-install-calico.sh${NC}"
echo -e "  2. For worker nodes: Copy ${CYAN}join-command.txt${NC} and run:"
echo -e "     ${CYAN}sudo bash 04-join-worker.sh${NC} ${YELLOW}(on each worker node)${NC}"
echo -e "  3. After CNI: Run ${CYAN}bash 05-verify-cluster.sh${NC} to verify everything"
echo ""
log_info "🎉 Dhyanesh says: Your control plane is alive! You're a K8s engineer now 😎"
echo ""
