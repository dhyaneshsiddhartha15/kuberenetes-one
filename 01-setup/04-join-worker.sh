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

log_info "🚀 Dhyanesh says: Let's add this worker to the cluster!"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root (use sudo)"
    exit 1
fi

################################################################################
# STEP 1: Check for Join Command
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Reading Join Command")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

JOIN_COMMAND_FILE="${SCRIPT_DIR}/join-command.txt"

if [ ! -f "$JOIN_COMMAND_FILE" ]; then
    log_error "✗ Join command file not found: $JOIN_COMMAND_FILE"
    echo ""
    log_info "The join command should have been created by ${CYAN}03-init-control-plane.sh${NC}"
    echo ""
    log_info "You can also manually generate a join command on the control plane:"
    echo -e "  ${CYAN}kubeadm token create --print-join-command${NC}"
    echo ""

    # Allow user to paste the command manually
    read -p "Do you have a join command? Paste it here (or press Enter to exit): " MANUAL_JOIN
    if [ -z "$MANUAL_JOIN" ]; then
        log_info "Exiting..."
        exit 1
    fi
    JOIN_CMD="$MANUAL_JOIN"
else
    JOIN_CMD=$(cat "$JOIN_COMMAND_FILE")
    log_success "✓ Join command read from: $JOIN_COMMAND_FILE"
fi

echo ""
log_info "📋 Join command:"
echo ""
echo -e "${BOLD}$JOIN_CMD${NC}"
echo ""

################################################################################
# STEP 2: Run Join Command
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Joining the Cluster")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

if ! confirm "Proceed with joining the cluster?"; then
    log_info "Aborted by user."
    exit 0
fi

log_info "📦 Executing join command..."
log_warn "This may take 1-2 minutes..."
echo ""

# Execute the join command
eval "$JOIN_CMD"

if [ $? -eq 0 ]; then
    log_success "✓ Successfully joined the cluster!"
else
    log_error "✗ Failed to join the cluster"
    exit 1
fi
echo ""

################################################################################
# STEP 3: Verify Node Registration
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Verifying Node Registration")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for node to register..."
log_warn "Note: Node will show 'NotReady' until CNI is installed"

# Get current hostname
NODE_NAME=$(hostname)

log_info "Looking for node: ${BOLD}$NODE_NAME${NC}"
echo ""

# Check if node exists in control plane
# Note: We can't run kubectl here unless we have access to control plane
# So we just check if kubelet is running
log_info "Checking kubelet status..."
if systemctl is-active --quiet kubelet; then
    log_success "✓ Kubelet is running on this node"
else
    log_error "✗ Kubelet is not running"
    exit 1
fi

echo ""
log_info "📦 To verify the node from control plane, run:"
echo -e "  ${CYAN}kubectl get nodes${NC}"
echo ""
log_info "You should see: ${BOLD}$NODE_NAME${NC} in the list"
echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Worker node joined successfully!"
echo ""
log_info "🚀 Next steps:"
echo -e "  1. On control plane: Run ${CYAN}kubectl get nodes${NC} to verify"
echo -e "  2. On control plane: Install CNI: ${CYAN}cd ../02-networking && sudo bash 01-install-calico.sh${NC}"
echo -e "  3. After CNI: All nodes should become ${CYAN}Ready${NC}"
echo ""
log_info "🎉 Dhyanesh says: Welcome to the cluster! 🎊"
echo ""
