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

log_info "🚀 Dhyanesh says: Let's set up the foundations! Grab a chai ☕"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root (use sudo)"
    exit 1
fi

################################################################################
# STEP 1: Disable Swap
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Disabling Swap"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Turning off swap..."
swapoff -a
log_success "✓ Swap disabled for current session"

# Permanently disable swap in /etc/fstab
log_info "📦 Making swap disable permanent..."
if grep -q "^.*swap.*" /etc/fstab; then
    # Backup fstab
    cp /etc/fstab /etc/fstab.backup
    # Comment out swap entries
    sed -i 's/^.*swap.*/#&/' /etc/fstab
    log_success "✓ Swap disabled in /etc/fstab (backup saved)"
else
    log_info "ℹ No swap entry found in /etc/fstab"
fi
echo ""

################################################################################
# STEP 2: Load Kernel Modules
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Loading Kernel Modules"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Loading required kernel modules..."

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

log_success "✓ Kernel modules loaded: overlay, br_netfilter"
echo ""

################################################################################
# STEP 3: Configure Sysctl Parameters
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Configuring Sysctl Parameters"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Setting up networking parameters for Kubernetes..."

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system >/dev/null 2>&1

log_success "✓ Sysctl parameters applied:"
echo -e "    ${CYAN}•${NC} net.bridge.bridge-nf-call-iptables = 1"
echo -e "    ${CYAN}•${NC} net.bridge.bridge-nf-call-ip6tables = 1"
echo -e "    ${CYAN}•${NC} net.ipv4.ip_forward = 1"
echo ""

################################################################################
# STEP 4: Install containerd
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Installing containerd")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Updating apt packages..."
apt-get update >/dev/null 2>&1

log_info "📦 Installing dependencies..."
apt-get install -y ca-certificates curl gnupg lsb-release >/dev/null 2>&1

# Add Docker GPG key
log_info "📦 Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
log_info "📦 Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update >/dev/null 2>&1

# Install containerd
log_info "📦 Installing containerd..."
apt-get install -y containerd.io >/dev/null 2>&1

log_success "✓ containerd installed"

# Configure containerd
log_info "📦 Configuring containerd..."

# Create config directory
mkdir -p /etc/containerd

# Generate default config and modify it
containerd config default | tee /etc/containerd/config.toml >/dev/null

# Enable SystemdCgroup
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

log_success "✓ containerd configured with SystemdCgroup = true"

# Enable and start containerd
log_info "📦 Starting containerd service..."
systemctl enable containerd >/dev/null 2>&1
systemctl restart containerd

# Wait for containerd to be ready
sleep 2

if systemctl is-active --quiet containerd; then
    log_success "✓ containerd is running"
else
    log_error "✗ Failed to start containerd"
    exit 1
fi
echo ""

################################################################################
# STEP 5: Verify Installation
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 5: Verification"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking containerd version..."
CONTAINERD_VERSION=$(containerd --version | grep -oP 'containerd\h+\K[0-9.]+')
log_success "✓ containerd version: ${BOLD}$CONTAINERD_VERSION${NC}"

log_info "🔍 Verifying swap is off..."
SWAP_FREE=$(free | grep Swap | awk '{print $2}')
if [ "$SWAP_FREE" -eq 0 ]; then
    log_success "✓ Swap is disabled"
else
    log_warn "⚠️  Swap is still enabled (${SWAP_FREE} KB)"
fi

log_info "🔍 Verifying kernel modules..."
if lsmod | grep -q overlay; then
    log_success "✓ overlay module loaded"
else
    log_warn "⚠️  overlay module not loaded"
fi

if lsmod | grep -q br_netfilter; then
    log_success "✓ br_netfilter module loaded"
else
    log_warn "⚠️  br_netfilter module not loaded"
fi
echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  SUMMARY"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Prerequisites installed successfully!"
echo ""
log_info "🚀 Next step: Run ${CYAN}sudo bash 02-install-kubeadm.sh${NC}"
echo ""
log_info "🎉 Dhyanesh says: Great progress! You're one step closer to your cluster. 😎"
echo ""
