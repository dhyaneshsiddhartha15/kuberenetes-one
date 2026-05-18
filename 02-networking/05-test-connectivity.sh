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

log_info "🚀 Dhyanesh says: Let's make sure everything actually works!"
echo ""

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print test result
print_test() {
    local name="$1"
    local status="$2"
    local message="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$status" = "PASS" ]; then
        echo -e "  ${GREEN}✓${NC} $name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "  ${RED}✗${NC} $name"
        if [ -n "$message" ]; then
            echo -e "    ${YELLOW}⚠ $message${NC}"
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

################################################################################
# TEST 1: Check Calico
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 1: Calico CNI Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking Calico pods..."
CALICO_PODS=$(kubectl get pods -n calico-system --no-headers 2>&1)

if [ $? -eq 0 ]; then
    CALICO_RUNNING=$(echo "$CALICO_PODS" | grep -c "Running" || true)
    CALICO_TOTAL=$(echo "$CALICO_PODS" | wc -l)

    if [ "$CALICO_RUNNING" -eq "$CALICO_TOTAL" ] && [ "$CALICO_TOTAL" -gt 0 ]; then
        print_test "Calico pods" "PASS" "All $CALICO_RUNNING pod(s) Running"
    else
        print_test "Calico pods" "FAIL" "Not all pods Running"
    fi
else
    print_test "Calico pods" "FAIL" "Cannot list calico-system pods"
fi

log_info "🔍 Checking node readiness..."
NODE_READY=$(kubectl get nodes | grep -v "NAME" | grep -c " Ready " || true)
NODE_TOTAL=$(kubectl get nodes | grep -v "NAME" | wc -l)

if [ "$NODE_READY" -eq "$NODE_TOTAL" ] && [ "$NODE_TOTAL" -gt 0 ]; then
    print_test "Node readiness" "PASS" "All $NODE_READY node(s) Ready"
else
    print_test "Node readiness" "FAIL" "$((NODE_TOTAL - NODE_READY)) node(s) not Ready"
fi
echo ""

################################################################################
# TEST 2: Check MetalLB
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 2: MetalLB Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking MetalLB pods..."
METALLB_PODS=$(kubectl get pods -n metallb-system --no-headers 2>&1)

if [ $? -eq 0 ]; then
    METALLB_RUNNING=$(echo "$METALLB_PODS" | grep -c "Running" || true)
    METALLB_TOTAL=$(echo "$METALLB_PODS" | wc -l)

    if [ "$METALLB_RUNNING" -eq "$METALLB_TOTAL" ] && [ "$METALLB_TOTAL" -gt 0 ]; then
        print_test "MetalLB pods" "PASS" "All $METALLB_RUNNING pod(s) Running"
    else
        print_test "MetalLB pods" "WARN" "Not all pods Running"
    fi
else
    print_test "MetalLB pods" "FAIL" "Cannot list metallb-system pods"
fi

log_info "🔍 Checking MetalLB IP pool..."
IPPOOL_OUTPUT=$(kubectl get ipaddresspool -n metallb-system --no-headers 2>&1)

if [ $? -eq 0 ]; then
    print_test "MetalLB IP pool" "PASS" "IP pool configured"
    echo -e "    ${CYAN}•${NC} $(echo "$IPPOOL_OUTPUT" | awk '{print $1}')"
else
    print_test "MetalLB IP pool" "FAIL" "No IP pool found"
fi
echo ""

################################################################################
# TEST 3: Check ingress-nginx
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 3: ingress-nginx Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking ingress-nginx pods..."
INGRESS_PODS=$(kubectl get pods -n ingress-nginx --no-headers 2>&1)

if [ $? -eq 0 ]; then
    INGRESS_RUNNING=$(echo "$INGRESS_PODS" | grep -c "Running" || true)
    INGRESS_TOTAL=$(echo "$INGRESS_PODS" | wc -l)

    if [ "$INGRESS_RUNNING" -eq "$INGRESS_TOTAL" ] && [ "$INGRESS_TOTAL" -gt 0 ]; then
        print_test "ingress-nginx pods" "PASS" "All $INGRESS_RUNNING pod(s) Running"
    else
        print_test "ingress-nginx pods" "WARN" "Not all pods Running"
    fi
else
    print_test "ingress-nginx pods" "FAIL" "Cannot list ingress-nginx pods"
fi

log_info "🔍 Checking ingress-nginx Service external IP..."
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$EXTERNAL_IP" ]; then
    print_test "ingress-nginx external IP" "PASS" "External IP: $EXTERNAL_IP"

    # Test if IP is reachable from host
    if ping -c 1 -W 2 "$EXTERNAL_IP" >/dev/null 2>&1; then
        print_test "ingress-nginx IP reachable" "PASS" "Can ping $EXTERNAL_IP"
    else
        print_test "ingress-nginx IP reachable" "WARN" "Cannot ping $EXTERNAL_IP (may be firewall)"
    fi
else
    print_test "ingress-nginx external IP" "FAIL" "No external IP assigned"
fi
echo ""

################################################################################
# TEST 4: Check cert-manager
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 4: cert-manager Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking cert-manager pods..."
CERT_PODS=$(kubectl get pods -n cert-manager --no-headers 2>&1)

if [ $? -eq 0 ]; then
    CERT_RUNNING=$(echo "$CERT_PODS" | grep -c "Running" || true)
    CERT_TOTAL=$(echo "$CERT_PODS" | wc -l)

    if [ "$CERT_RUNNING" -eq "$CERT_TOTAL" ] && [ "$CERT_TOTAL" -gt 0 ]; then
        print_test "cert-manager pods" "PASS" "All $CERT_RUNNING pod(s) Running"
    else
        print_test "cert-manager pods" "WARN" "Not all pods Running"
    fi
else
    print_test "cert-manager pods" "FAIL" "Cannot list cert-manager pods"
fi

log_info "🔍 Checking ClusterIssuers..."
ISSUERS=$(kubectl get clusterissuer --no-headers 2>&1)

if [ $? -eq 0 ]; then
    ISSUER_COUNT=$(echo "$ISSUERS" | wc -l)
    print_test "ClusterIssuers" "PASS" "$ISSUER_COUNT issuer(s) configured"
    echo "$ISSUERS" | while read name ready; do
        echo -e "    ${CYAN}•${NC} $name - $ready"
    done
else
    print_test "ClusterIssuers" "FAIL" "No ClusterIssuers found"
fi
echo ""

################################################################################
# TEST 5: Test Pod-to-Pod Communication
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  TEST 5: Pod-to-Pod Communication")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Deploying test pods..."

# Create test namespace
kubectl create namespace connectivity-test --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || true

# Deploy nginx test pod
kubectl run test-nginx --image=nginx:alpine --restart=Never -n connectivity-test --expose --port=80 >/dev/null 2>&1 || true

log_info "Waiting for test pods to be ready..."
sleep 5

# Deploy busybox test pod
kubectl run test-busybox --image=busybox:1.28 --restart=Never -n connectivity-test --command -- sleep 30 >/dev/null 2>&1 || true

sleep 3

# Test connectivity
log_info "Testing connectivity from busybox to nginx..."
RESULT=$(kubectl exec test-busybox -n connectivity-test -- wget -q -O- http://test-nginx.connectivity-test --timeout=3 2>&1)

if echo "$RESULT" | grep -q "Welcome to nginx"; then
    print_test "Pod-to-pod HTTP" "PASS" "busybox can reach nginx"
else
    print_test "Pod-to-pod HTTP" "FAIL" "busybox cannot reach nginx"
fi

# Test DNS
log_info "Testing DNS resolution..."
DNS_RESULT=$(kubectl exec test-busybox -n connectivity-test -- nslookup kubernetes.default.svc.cluster.local 2>&1)

if echo "$DNS_RESULT" | grep -q "Address:"; then
    print_test "Cluster DNS" "PASS" "Can resolve internal services"
else
    print_test "Cluster DNS" "FAIL" "Cannot resolve internal DNS"
fi

# Clean up
log_info "Cleaning up test pods..."
kubectl delete namespace connectivity-test --grace-period=5 --timeout=10s >/dev/null 2>&1 || true

echo ""

################################################################################
# TEST 6: Test Service Discovery
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 6: Service Discovery")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "📦 Deploying test service..."
kubectl create namespace service-test --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || true

kubectl create deployment test-app --image=nginx:alpine -n service-test --replicas=2 >/dev/null 2>&1 || true

kubectl expose deployment test-app --port=80 -n service-test >/dev/null 2>&1 || true

sleep 5

# Check if service exists
if kubectl get svc test-app -n service-test >/dev/null 2>&1; then
    print_test "Service creation" "PASS" "test-app Service created"

    # Get cluster IP
    SVC_IP=$(kubectl get svc test-app -n service-test -o jsonpath='{.spec.clusterIP}')
    echo -e "    ${CYAN}•${NC} Cluster IP: $SVC_IP"

    # Test endpoint connectivity
    ENDPOINTS=$(kubectl get endpoints test-app -n service-test -o jsonpath='{.subsets[*].addresses[*].ip}')
    if [ -n "$ENDPOINTS" ]; then
        print_test "Service endpoints" "PASS" "Endpoints ready"
    else
        print_test "Service endpoints" "FAIL" "No endpoints ready"
    fi
else
    print_test "Service creation" "FAIL" "Could not create test service"
fi

# Clean up
kubectl delete namespace service-test --grace-period=5 --timeout=10s >/dev/null 2>&1 || true

echo ""

################################################################################
# Summary
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
log_section "  SUMMARY")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

echo -e "  ${BOLD}Total Tests:${NC} $TOTAL_TESTS"
echo -e "  ${GREEN}Passed:${NC} $PASSED_TESTS"
echo -e "  ${RED}Failed:${NC} $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    log_success "✅ All connectivity tests passed!"
    echo ""
    log_info "🚀 Your cluster networking is fully functional!"
    echo ""
    log_info "🎉 Dhyanesh says: Nice work! Time to deploy some apps 🚀"
    echo ""
    log_info "Next: Go to ${CYAN}../03-workloads/${NC} to deploy the sample application"
    exit 0
else
    log_warn "⚠️  Some tests failed. Check the output above."
    echo ""
    log_info "Common fixes:"
    echo -e "  ${CYAN}•${NC} Calico pods not Running → Check node readiness"
    echo -e "  ${CYAN}•${NC} No external IP → Check MetalLB is configured"
    echo -e "  ${CYAN}•${NC} DNS failures → Check CoreDNS pods are Running"
    echo ""
    exit 1
fi
