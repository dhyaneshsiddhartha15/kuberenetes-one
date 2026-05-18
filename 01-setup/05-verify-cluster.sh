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

log_info "🚀 Dhyanesh says: Let's make sure everything is working!"
echo ""

# Check KUBECONFIG
if [ -z "$KUBECONFIG" ] && [ ! -f "$HOME/.kube/config" ]; then
    log_error "✗ Kubeconfig not found. Please run 03-init-control-plane.sh first"
    exit 1
fi

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
# TEST 1: Check Nodes
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 1: Node Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking node status..."
NODE_OUTPUT=$(kubectl get nodes 2>&1)

if [ $? -eq 0 ]; then
    echo ""
    echo "$NODE_OUTPUT"
    echo ""

    # Count nodes and check readiness
    NODE_COUNT=$(echo "$NODE_OUTPUT" | tail -n +2 | wc -l)
    READY_COUNT=$(echo "$NODE_OUTPUT" | grep -c " Ready " || true)

    if [ "$NODE_COUNT" -gt 0 ]; then
        print_test "Cluster has nodes" "PASS" "$NODE_COUNT node(s) found"

        if [ "$READY_COUNT" -eq "$NODE_COUNT" ]; then
            print_test "All nodes Ready" "PASS" "All $NODE_COUNT node(s) are Ready"
        else
            NOT_READY_COUNT=$((NODE_COUNT - READY_COUNT))
            print_test "All nodes Ready" "FAIL" "$NOT_READY_COUNT node(s) not ready (CNI may not be installed)"
        fi
    else
        print_test "Cluster has nodes" "FAIL" "No nodes found"
    fi
else
    print_test "kubectl connectivity" "FAIL" "Cannot connect to cluster"
fi
echo ""

################################################################################
# TEST 2: Check System Pods
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 2: System Pods Status")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking system pods..."
PODS_OUTPUT=$(kubectl get pods -n kube-system 2>&1)

if [ $? -eq 0 ]; then
    echo ""
    echo "$PODS_OUTPUT"
    echo ""

    # Check for non-running pods
    RUNNING_COUNT=$(echo "$PODS_OUTPUT" | tail -n +2 | grep -c "Running" || true)
    PENDING_COUNT=$(echo "$PODS_OUTPUT" | tail -n +2 | grep -c "Pending" || true)
    CRASH_COUNT=$(echo "$PODS_OUTPUT" | tail -n +2 | grep -c "CrashLoopBackOff" || true)
    TOTAL_PODS=$(echo "$PODS_OUTPUT" | tail -n +2 | wc -l)

    if [ "$TOTAL_PODS" -gt 0 ]; then
        print_test "System pods exist" "PASS" "$TOTAL_PODS pod(s) in kube-system"

        if [ "$CRASH_COUNT" -eq 0 ]; then
            print_test "No CrashLoopBackOff" "PASS"
        else
            print_test "No CrashLoopBackOff" "FAIL" "$CRASH_COUNT pod(s) in CrashLoopBackOff"
        fi

        # Note: CoreDNS pods may be Pending without CNI
        if [ "$PENDING_COUNT" -gt 0 ]; then
            print_test "All pods Running" "WARN" "$PENDING_COUNT pod(s) Pending (expected for CoreDNS without CNI)"
        elif [ "$RUNNING_COUNT" -eq "$TOTAL_PODS" ]; then
            print_test "All pods Running" "PASS" "All $TOTAL_PODS pod(s) are Running"
        fi
    else
        print_test "System pods exist" "FAIL" "No pods found in kube-system"
    fi
else
    print_test "Pod listing" "FAIL" "Cannot list pods"
fi
echo ""

################################################################################
# TEST 3: Check Component Statuses
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 3: Component Statuses")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking component statuses..."

# Try kubectl get componentstatuses (deprecated in newer K8s, but try it)
CS_OUTPUT=$(kubectl get componentstatuses 2>&1)

if [ $? -eq 0 ]; then
    echo ""
    echo "$CS_OUTPUT"
    echo ""

    # Check if all components are Healthy
    UNHEALTHY_COUNT=$(echo "$CS_OUTPUT" | grep -v "NAME" | grep -vc "Healthy" || true)

    if [ "$UNHEALTHY_COUNT" -eq 0 ]; then
        print_test "Component health" "PASS" "All components Healthy"
    else
        print_test "Component health" "FAIL" "$UNHEALTHY_COUNT component(s) not Healthy"
    fi
else
    # In newer K8s, componentstatuses is removed, so we check cluster-info instead
    log_info "Componentstatuses not available (deprecated in newer K8s)"
    CLUSTER_INFO=$(kubectl cluster-info 2>&1)

    if [ $? -eq 0 ]; then
        print_test "Cluster info" "PASS" "Control plane is reachable"
        echo ""
        echo "$CLUSTER_INFO" | head -3
    else
        print_test "Cluster info" "FAIL" "Cannot get cluster info"
    fi
fi
echo ""

################################################################################
# TEST 4: DNS Test
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 4: DNS Resolution")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Testing DNS resolution with busybox..."

# Deploy a test busybox pod
log_info "Deploying test pod..."
kubectl run dns-test --image=busybox:1.28 --restart=Never --command -- sleep 60 >/dev/null 2>&1 || true

# Wait for pod to be ready
sleep 3

# Try DNS lookup
DNS_RESULT=$(kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local 2>&1)

if echo "$DNS_RESULT" | grep -q "Address:"; then
    print_test "DNS resolution" "PASS" "Can resolve kubernetes.default.svc.cluster.local"
else
    print_test "DNS resolution" "FAIL" "Cannot resolve internal DNS"
fi

# Clean up test pod
kubectl delete pod dns-test --force --grace-period=0 >/dev/null 2>&1 || true

echo ""

################################################################################
# TEST 5: API Server Connectivity
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 5: API Server Connectivity")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Testing API server connectivity..."

API_VERSION=$(kubectl version --short 2>&1 | grep "Server Version" || true)

if [ -n "$API_VERSION" ]; then
    print_test "API server" "PASS" "Can communicate with API server"
    echo -e "    ${CYAN}•${NC} $API_VERSION"
else
    print_test "API server" "FAIL" "Cannot reach API server"
fi
echo ""

################################################################################
# TEST 6: Scheduler and Controller
################################################################################

log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_section "  TEST 6: Scheduler and Controller Manager")
log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
echo ""

log_info "🔍 Checking scheduler and controller manager pods..."

SCHEDULER_PODS=$(kubectl get pods -n kube-system -l component=kube-scheduler --no-headers 2>&1 | wc -l)
CONTROLLER_PODS=$(kubectl get pods -n kube-system -l component=kube-controller-manager --no-headers 2>&1 | wc -l)

if [ "$SCHEDULER_PODS" -gt 0 ]; then
    print_test "Scheduler pods" "PASS" "$SCHEDULER_PODS scheduler pod(s) found"
else
    print_test "Scheduler pods" "WARN" "No scheduler pods found (may be static pods)"
fi

if [ "$CONTROLLER_PODS" -gt 0 ]; then
    print_test "Controller manager pods" "PASS" "$CONTROLLER_PODS controller pod(s) found"
else
    print_test "Controller manager pods" "WARN" "No controller pods found (may be static pods)"
fi

echo ""

################################################################################
# Print Summary
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
    log_success "✅ All tests passed! Your cluster is healthy!"
    echo ""
    log_info "🚀 Next step: Install networking with ${CYAN}cd ../02-networking && sudo bash 01-install-calico.sh${NC}"
    echo ""
    log_info "🎉 Dhyanesh says: Nice! Your cluster is ready for action! 🚀"
    exit 0
else
    log_warn "⚠️  Some tests failed. Check the output above for details."
    echo ""
    log_warn "⚠️  Dhyanesh says: Don't skip this step. Fix the issues before moving on."
    echo ""
    log_info "Common fixes:"
    echo -e "  ${CYAN}•${NC} Nodes NotReady → Install CNI (cd ../02-networking)"
    echo -e "  ${CYAN}•${NC} DNS failing → Check if CoreDNS pods are Running"
    echo -e "  ${CYAN}•${NC} API errors → Check KUBECONFIG path"
    echo ""
    exit 1
fi
