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

log_info "🚀 Dhyanesh says: Let's set up your cluster's front door!"
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

# Create ingress-nginx values file
cat > /tmp/ingress-nginx-values.yaml << 'EOF'
controller:
  replicaCount: 2
  service:
    type: LoadBalancer
    ports:
      http: 80
      https: 443
    enableHttp: true
    enableHttps: true
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    proxy-body-size: "10m"
    server-tokens: "false"
  admissionWebhooks:
    enabled: true
  watchIngressWithoutClass: true

defaultBackend:
  enabled: false

rbac:
  create: true

serviceAccount:
  create: true
EOF

################################################################################
# STEP 1: Add ingress-nginx Helm Repository
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Adding ingress-nginx Repository")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Adding ingress-nginx repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update 2>&1 | grep -v "already exists" || true

log_success "✓ ingress-nginx repository added"
echo ""

################################################################################
# STEP 2: Create Namespace
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Creating ingress-nginx Namespace")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Creating ingress-nginx namespace..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || true

log_success "✓ Namespace created"
echo ""

################################################################################
# STEP 3: Install ingress-nginx via Helm
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Installing ingress-nginx")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Installing ingress-nginx with LoadBalancer type..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --values /tmp/ingress-nginx-values.yaml

log_success "✓ ingress-nginx installed via Helm"
echo ""

################################################################################
# STEP 4: Wait for ingress-nginx Pods to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Waiting for ingress-nginx to Start")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for ingress-nginx pods to be ready..."
log_warn "This may take 2-3 minutes..."

wait_for_pods "ingress-nginx" 180

if [ $? -eq 0 ]; then
    log_success "✓ All ingress-nginx pods are Running!"
else
    log_warn "⚠️  Some ingress-nginx pods may not be ready yet"
fi
echo ""

################################################################################
# STEP 5: Get External IP
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 5: Getting External IP")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Waiting for external IP assignment..."
log_warn "This may take 30-60 seconds while MetalLB assigns the IP"

# Wait for external IP to be assigned
TIMEOUT=60
ELAPSED=0
EXTERNAL_IP=""

while [ $ELAPSED -lt $TIMEOUT ]; do
    EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi

    echo -ne "\r  Waiting... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo ""
echo ""

if [ -n "$EXTERNAL_IP" ]; then
    log_success "✓ External IP assigned: ${BOLD}$EXTERNAL_IP${NC}"
    echo ""
    log_info "📋 This is your cluster's front door!"
    echo -e "  ${CYAN}•${NC} Point your domain (${BOLD}myapp.example.com${NC}) to this IP"
    echo -e "  ${CYAN}•${NC} Or add to ${CYAN}/etc/hosts${NC}: ${BOLD}$EXTERNAL_IP myapp.example.com${NC}"
    echo -e "  ${CYAN}•${NC} Ingress resources will use this IP"
else
    log_warn "⚠️  External IP not yet assigned"
    log_info "Check status with: kubectl get svc -n ingress-nginx"
fi
echo ""

################################################################################
# STEP 6: Display Status
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 6: Current Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 ingress-nginx Service:"
echo ""

kubectl get svc -n ingress-nginx

echo ""

log_info "🔍 ingress-nginx Pods:"
echo ""

kubectl get pods -n ingress-nginx

echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ ingress-nginx installed successfully!"
echo ""
log_info "📋 What ingress-nginx does:"
echo -e "  ${CYAN}•${NC} Watches for Ingress resources"
echo -e "  ${CYAN}•${NC} Routes HTTP/HTTPS traffic based on hostnames and paths"
echo -e "  ${CYAN}•${NC} Terminates TLS at the ingress level"
echo -e "  ${CYAN}•${NC} Runs as LoadBalancer (IP from MetalLB)"
echo ""

if [ -n "$EXTERNAL_IP" ]; then
    log_info "🌐 External IP: ${BOLD}$EXTERNAL_IP${NC}"
fi

echo ""
log_info "🚀 Next step: Install cert-manager with ${CYAN}sudo bash 04-install-cert-manager.sh${NC}"
echo ""
log_info "🎉 Dhyanesh says: Your cluster has a front door now! 🚪✨"
echo ""
