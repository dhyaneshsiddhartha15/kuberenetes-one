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

# Color variables (from common.sh, but defining fallbacks)
if [ -z "${RED}" ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m';
fi

print_banner

log_info "🚀 Dhyanesh says: Let's make sure your machine is ready for Kubernetes!"
echo ""

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to print check result
print_check() {
    local name="$1"
    local status="$2"
    local message="$3"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ "$status" = "PASS" ]; then
        echo -e "  ${GREEN}✓${NC} $name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "  ${RED}✗${NC} $name"
        if [ -n "$message" ]; then
            echo -e "    ${YELLOW}⚠ $message${NC}"
        fi
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  SYSTEM PRE-FLIGHT CHECKS"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check OS
log_info "Checking operating system..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$ID"
    OS_VERSION="$VERSION_ID"

    if [ "$OS_NAME" = "ubuntu" ]; then
        if dpkg --compare-versions "$OS_VERSION" "ge" "22.04"; then
            print_check "Operating System" "PASS" "Ubuntu $OS_VERSION"
        else
            print_check "Operating System" "FAIL" "Ubuntu $OS_VERSION is too old. Need 22.04+"
        fi
    else
        print_check "Operating System" "FAIL" "Not Ubuntu. Found: $PRETTY_NAME"
    fi
else
    print_check "Operating System" "FAIL" "Cannot detect OS"
fi
echo ""

# 2. Check RAM
log_info "Checking RAM resources..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))

if [ "$TOTAL_RAM_GB" -ge 2 ]; then
    print_check "RAM" "PASS" "$TOTAL_RAM_GB GB detected"
else
    print_check "RAM" "FAIL" "Only ${TOTAL_RAM_GB}GB. Need at least 2GB"
fi
echo ""

# 3. Check CPU cores
log_info "Checking CPU cores..."
CPU_CORES=$(nproc)

if [ "$CPU_CORES" -ge 2 ]; then
    print_check "CPU Cores" "PASS" "$CPU_CORES cores detected"
else
    print_check "CPU Cores" "FAIL" "Only ${CPU_CORES} core(s). Need at least 2"
fi
echo ""

# 4. Check swap status
log_info "Checking swap status..."
SWAP_USAGE=$(free | grep Swap | awk '{print $2}')
if [ "$SWAP_USAGE" -eq 0 ]; then
    print_check "Swap Disabled" "PASS" "Swap is already off"
else
    print_check "Swap Disabled" "FAIL" "Swap is enabled. Run 01-setup-prerequisites.sh to disable"
    SWAP_GB=$((SWAP_USAGE / 1024 / 1024))
    echo -e "    ${CYAN}ℹ${NC} Current swap: ${SWAP_GB}GB"
fi
echo ""

# 5. Check required ports
log_info "Checking if required ports are available..."
declare -A PORTS=(
    ["6443"]="Kubernetes API Server"
    ["2379-2380"]="etcd server client API"
    ["10250"]="Kubelet API"
    ["10251"]="kube-scheduler"
    ["10252"]="kube-controller-manager"
    ["5473"]="Calico (if installing)"
)

for port_range in "${!PORTS[@]}"; do
    port_name="${PORTS[$port_range]}"
    if [[ "$port_range" == *"-"* ]]; then
        # Handle port ranges
        start_port="${port_range%-*}"
        end_port="${port_range#*-}"
        port_in_use=false
        for ((port=start_port; port<=end_port; port++)); do
            if sudo lsof -i ":$port" >/dev/null 2>&1 || sudo ss -tuln | grep -q ":$port "; then
                port_in_use=true
                break
            fi
        done
        if [ "$port_in_use" = false ]; then
            print_check "Port $port_range ($port_name)" "PASS"
        else
            print_check "Port $port_range ($port_name)" "FAIL" "Port(s) in use"
        fi
    else
        # Handle single ports
        if sudo lsof -i ":$port_range" >/dev/null 2>&1 || sudo ss -tuln | grep -q ":$port_range "; then
            print_check "Port $port_range ($port_name)" "FAIL" "Port is in use"
        else
            print_check "Port $port_range ($port_name)" "PASS"
        fi
    fi
done
echo ""

# 6. Check internet connectivity
log_info "Checking internet connectivity..."
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    print_check "Internet (IPv4)" "PASS"
else
    print_check "Internet (IPv4)" "FAIL" "Cannot reach 8.8.8.8"
fi
echo ""

# 7. Check if running as root
log_info "Checking user permissions..."
if [ "$EUID" -eq 0 ]; then
    print_check "Running as root" "PASS" "Script has necessary privileges"
else
    print_check "Running with sudo" "WARN" "Some commands will need sudo access"
fi
echo ""

# 8. Check disk space
log_info "Checking disk space..."
DISK_AVAILABLE=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$DISK_AVAILABLE" -ge 20 ]; then
    print_check "Disk Space" "PASS" "${DISK_AVAILABLE}GB available"
else
    print_check "Disk Space" "WARN" "Only ${DISK_AVAILABLE}GB available. 20GB+ recommended"
fi
echo ""

# Print summary
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  SUMMARY"
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

echo -e "  ${BOLD}Total Checks:${NC} $TOTAL_CHECKS"
echo -e "  ${GREEN}Passed:${NC} $PASSED_CHECKS"
echo -e "  ${RED}Failed:${NC} $FAILED_CHECKS"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "✅ All checks passed! Your system is ready for Kubernetes."
    echo ""
    log_info "🚀 Next step: Run ${CYAN}sudo bash 01-setup-prerequisites.sh${NC}"
    exit 0
else
    log_error "❌ Some checks failed. Please fix the issues above before proceeding."
    echo ""
    log_warn "⚠️  Dhyanesh says: Don't skip these checks! I learned the hard way."
    exit 1
fi
