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
source "${SCRIPT_DIR}/../scripts/common.sh"

print_banner

log_info "🚀 Dhyanesh says: Let's deploy your app!"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "✗ kubectl not found. Please complete cluster setup first"
    exit 1
fi

################################################################################
# STEP 1: Create Namespace
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 1: Creating Namespace")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

kubectl apply -f "${SCRIPT_DIR}/00-namespace.yaml"

log_success "✓ Namespace 'myapp' created"
echo ""

################################################################################
# STEP 2: Deploy Backend
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 2: Deploying Backend")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Applying backend ConfigMap..."
kubectl apply -f "${SCRIPT_DIR}/backend/configmap.yaml"

log_info "📦 Applying backend Deployment..."
kubectl apply -f "${SCRIPT_DIR}/backend/deployment.yaml"

log_info "📦 Applying backend Service..."
kubectl apply -f "${SCRIPT_DIR}/backend/service.yaml"

log_info "📦 Applying backend HPA..."
kubectl apply -f "${SCRIPT_DIR}/backend/hpa.yaml"

log_success "✓ Backend deployed"
echo ""

################################################################################
# STEP 3: Deploy Frontend
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 3: Deploying Frontend")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Applying frontend Deployment..."
kubectl apply -f "${SCRIPT_DIR}/frontend/deployment.yaml"

log_info "📦 Applying frontend Service..."
kubectl apply -f "${SCRIPT_DIR}/frontend/service.yaml"

log_success "✓ Frontend deployed"
echo ""

################################################################################
# STEP 4: Deploy Ingress
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  STEP 4: Deploying Ingress")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Applying Ingress with TLS..."
kubectl apply -f "${SCRIPT_DIR}/ingress.yaml"

log_success "✓ Ingress deployed"
echo ""

################################################################################
# STEP 5: Wait for Pods to be Ready
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 5: Waiting for Pods to be Ready")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Waiting for backend pods..."
wait_for_deployment "myapp" "backend-deployment" 180

log_info "📦 Waiting for frontend pods..."
wait_for_deployment "myapp" "frontend-deployment" 120

log_success "✓ All pods are ready!"
echo ""

################################################################################
# STEP 6: Display Status
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 6: Deployment Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Pods:"
echo ""
kubectl get pods -n myapp
echo ""

log_info "🔍 Services:"
echo ""
kubectl get svc -n myapp
echo ""

log_info "🔍 Ingress:"
echo ""
kubectl get ingress -n myapp
echo ""

log_info "🔍 HPA:"
echo ""
kubectl get hpa -n myapp
echo ""

################################################################################
# STEP 7: Display Access Information
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  STEP 7: Access Information")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

# Get ingress external IP
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$EXTERNAL_IP" ]; then
    log_success "✓ Application deployed successfully!"
    echo ""
    log_info "🌐 Access your app at:"
    echo -e "  ${CYAN}https://myapp.example.com${NC}"
    echo ""
    log_info "📋 DNS Configuration:"
    echo -e "  Add to ${CYAN}/etc/hosts${NC}:"
    echo -e "  ${BOLD}$EXTERNAL_IP  myapp.example.com${NC}"
    echo ""
    log_info "📋 Or point your domain's A record to:"
    echo -e "  ${BOLD}$EXTERNAL_IP${NC}"
    echo ""

    # Test certificate
    log_info "🔍 Checking TLS certificate..."
    sleep 5

    CERT_SECRET=$(kubectl get secret myapp-tls-cert -n myapp --no-headers 2>/dev/null | wc -l)
    if [ "$CERT_SECRET" -gt 0 ]; then
        log_success "✓ TLS certificate issued!"
        echo ""
    else
        log_warn "⚠️  TLS certificate not yet issued. Check status with:"
        echo -e "  ${CYAN}kubectl get certificate -n myapp${NC}"
        echo ""
    fi

    # Offer to add to /etc/hosts
    log_info "💡 Quick setup: Add to /etc/hosts now?"
    read -p "Add '$EXTERNAL_IP myapp.example.com' to /etc/hosts? (y/N): " ADD_HOSTS

    if [[ "$ADD_HOSTS" =~ ^[Yy]$ ]]; then
        if grep -q "myapp.example.com" /etc/hosts 2>/dev/null; then
            log_warn "Entry already exists in /etc/hosts"
        else
            if echo "$EXTERNAL_IP myapp.example.com" | sudo tee -a /etc/hosts >/dev/null; then
                log_success "✓ Added to /etc/hosts"
            else
                log_warn "⚠️  Could not add to /etc/hosts (try manually)"
            fi
        fi
    fi
else
    log_warn "⚠️  Could not determine external IP"
    log_info "Check ingress-nginx service:"
    echo -e "  ${CYAN}kubectl get svc -n ingress-nginx${NC}"
fi

echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_success "✅ Application deployed successfully!"
echo ""
log_info "📋 Deployed components:"
echo -e "  ${CYAN}•${NC} Backend: FastAPI on port 8000 (2 replicas)"
echo -e "  ${CYAN}•${NC} Frontend: nginx on port 8080 (2 replicas)"
echo -e "  ${CYAN}•${NC} Ingress: TLS enabled with Let's Encrypt"
echo -e "  ${CYAN}•${NC} HPA: Auto-scaling enabled (2-5 pods)"
echo ""
log_info "📋 Useful commands:"
echo -e "  ${CYAN}kubectl logs -f deployment/backend-deployment -n myapp${NC} - View backend logs"
echo -e "  ${CYAN}kubectl logs -f deployment/frontend-deployment -n myapp${NC} - View frontend logs"
echo -e "  ${CYAN}kubectl get certificate -n myapp${NC} - Check TLS certificate"
echo -e "  ${CYAN}kubectl get hpa -n myapp${NC} - Check autoscaling status"
echo ""
log_info "🎉 Dhyanesh says: Your app is live! Happy K8sing! 🚀"
echo ""
