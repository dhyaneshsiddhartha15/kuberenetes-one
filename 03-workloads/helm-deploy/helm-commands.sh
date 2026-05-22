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

log_info "🚀 Dhyanesh says: Let's learn some Helm commands!"
echo ""

################################################################################
# Helm Repository Commands
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  Repository Management")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📋 Add a Helm repository:"
echo -e "${CYAN}helm repo add <name> <url>${NC}"
echo "Example: helm repo add bitnami https://charts.bitnami.com/bitnami"
echo ""

log_info "📋 List all repositories:"
echo -e "${CYAN}helm repo list${NC}"
echo ""

log_info "📋 Update repository cache:"
echo -e "${CYAN}helm repo update${NC}"
echo ""

log_info "📋 Remove a repository:"
echo -e "${CYAN}helm repo remove <name>${NC}"
echo "Example: helm repo remove bitnami"
echo ""

log_info "📋 Search for charts:"
echo -e "${CYAN}helm search repo <keyword>${NC}"
echo "Example: helm search repo nginx"
echo ""

################################################################################
# Chart Commands
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  Chart Management")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📋 Create a new chart:"
echo -e "${CYAN}helm create <chart-name>${NC}"
echo "Example: helm create myapp-chart"
echo ""

log_info "📋 Show chart's default values:"
echo -e "${CYAN}helm show values <repo/chart>${NC}"
echo "Example: helm show values bitnami/redis"
echo ""

log_info "📋 Download a chart without installing:"
echo -e "${CYAN}helm pull <repo/chart>${NC}"
echo "Example: helm pull bitnami/redis"
echo ""

log_info "📋 Package a chart directory:"
echo -e "${CYAN}helm package <chart-path>${NC}"
echo "Example: helm package ./myapp-chart"
echo ""

log_info "📋 Lint a chart for errors:"
echo -e "${CYAN}helm lint <chart-path>${NC}"
echo "Example: helm lint ./myapp-chart"
echo ""

log_info "📋 Render templates (dry-run):"
echo -e "${CYAN}helm template <release-name> <chart-path>${NC}"
echo "Example: helm template myapp ./myapp-chart"
echo ""

################################################################################
# Install Commands
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  Install & Upgrade")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📋 Install a chart with default values:"
echo -e "${CYAN}helm install <release> <chart>${NC}"
echo "Example: helm install myapp bitnami/nginx"
echo ""

log_info "📋 Install with custom values:"
echo -e "${CYAN}helm install <release> <chart> --set <key>=<value>${NC}"
echo "Example: helm install myapp bitnami/nginx --set replicaCount=3"
echo ""

log_info "📋 Install with values file:"
echo -e "${CYAN}helm install <release> <chart> -f <values-file>${NC}"
echo "Example: helm install myapp ./myapp-chart -f custom-values.yaml"
echo ""

log_info "📋 Install with multiple values files:"
echo -e "${CYAN}helm install <release> <chart> -f <file1> -f <file2>${NC}"
echo "Example: helm install myapp ./myapp-chart -f base.yaml -f prod.yaml"
echo ""

log_info "📋 Upgrade a release:"
echo -e "${CYAN}helm upgrade <release> <chart>${NC}"
echo "Example: helm upgrade myapp ./myapp-chart"
echo ""

log_info "📋 Upgrade with new values:"
echo -e "${CYAN}helm upgrade <release> <chart> --set <key>=<value>${NC}"
echo "Example: helm upgrade myapp ./myapp-chart --set image.tag=v2.0"
echo ""

################################################################################
# Release Management
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  Release Management")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📋 List all releases:"
echo -e "${CYAN}helm list${NC}"
echo "Or: helm list --all-namespaces"
echo ""

log_info "📋 Show release status:"
echo -e "${CYAN}helm status <release>${NC}"
echo "Example: helm status myapp"
echo ""

log_info "📋 Show release values:"
echo -e "${CYAN}helm get values <release>${NC}"
echo "Example: helm get values myapp"
echo ""

log_info "📋 Show release manifest (generated YAML):"
echo -e "${CYAN}helm get manifest <release>${NC}"
echo "Example: helm get manifest myapp"
echo ""

log_info "📋 Show release history:"
echo -e "${CYAN}helm history <release>${NC}"
echo "Example: helm history myapp"
echo ""

log_info "📋 Rollback to previous version:"
echo -e "${CYAN}helm rollback <release>${NC}"
echo "Example: helm rollback myapp"
echo ""

log_info "📋 Rollback to specific revision:"
echo -e "${CYAN}helm rollback <release> <revision>${NC}"
echo "Example: helm rollback myapp 2"
echo ""

log_info "📋 Uninstall a release:"
echo -e "${CYAN}helm uninstall <release>${NC}"
echo "Example: helm uninstall myapp"
echo ""

################################################################################
# Diff and Debug
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  Diff & Debug")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📋 Show diff between release and new chart:"
echo -e "${CYAN}helm diff upgrade <release> <chart>${NC}"
echo "Note: Requires helm-diff plugin"
echo "Example: helm diff upgrade myapp ./myapp-chart"
echo ""

log_info "📋 Dry-run an install (show what would be deployed):"
echo -e "${CYAN}helm install <release> <chart> --dry-run --debug${NC}"
echo "Example: helm install myapp ./myapp-chart --dry-run --debug"
echo ""

log_info "📋 Show Helm environment:"
echo -e "${CYAN}helm env${NC}"
echo ""

################################################################################
# Using the myapp-chart
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  Deploy myapp-chart")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📋 Install myapp-chart with default values:"
echo -e "${CYAN}helm install myapp ./myapp-chart${NC}"
echo ""

log_info "📋 Install with custom host:"
echo -e "${CYAN}helm install myapp ./myapp-chart --set ingress.host=myapp.example.com${NC}"
echo ""

log_info "📋 Install with custom image tag:"
echo -e "${CYAN}helm install myapp ./myapp-chart --set backend.image.tag=v2.0${NC}"
echo ""

log_info "📋 Install with production values:"
echo -e "${CYAN}helm install myapp ./myapp-chart -f values-production.yaml${NC}"
echo ""

log_info "📋 Upgrade myapp:"
echo -e "${CYAN}helm upgrade myapp ./myapp-chart${NC}"
echo ""

log_info "📋 Uninstall myapp:"
echo -e "${CYAN}helm uninstall myapp${NC}"
echo ""

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  END OF REFERENCE")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🎉 Dhyanesh says: Happy Helming! 🚀"
echo ""
