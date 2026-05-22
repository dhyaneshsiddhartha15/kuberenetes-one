# 04-Security: Harden Your Kubernetes Cluster

> 💬 **Dhyanesh's note:** Security is not an afterthought — it's a foundation. I learned this the hard way when I accidentally exposed a database to the internet. Don't be like me. Secure your cluster from day one.

---

## Why Security Matters in Kubernetes

Kubernetes clusters are powerful, and with power comes risk. A compromised cluster can:
- Expose sensitive data
- Mine cryptocurrency on your AWS infrastructure
- Attack other systems on your VPC
- Cause downtime and data loss
- Run up your AWS bill significantly

**Good news:** Kubernetes has powerful security features built-in. This section shows you how to use them.

---

## Security Concepts

### RBAC (Role-Based Access Control)

**What it is:** Controls who can do what in your cluster.

**Components:**
- **Role:** Defines permissions within a namespace
- **ClusterRole:** Defines permissions cluster-wide
- **RoleBinding:** Binds a Role to a user/group/ServiceAccount
- **ClusterRoleBinding:** Binds a ClusterRole cluster-wide

**Example:** Give developers read-only access to pods in the `dev` namespace.

---

### Network Policy

**What it is:** Firewall rules for pods. Controls which pods can talk to each other.

**Default behavior:** All pods can talk to all pods (no restrictions).

**Best practice:** Default-deny all traffic, then explicitly allow what's needed.

**Example:** Allow frontend pods to connect to backend pods on port 8000.

---

### Pod Security

**What it is:** Controls what pods are allowed to do.

**Features:**
- Run as non-root user
- Read-only root filesystem
- Drop capabilities
- Prevent privilege escalation
- Restrict seccomp profiles

**Best practice:** Use the `restricted` Pod Security Standard.

---

### Secrets Management

**What it is:** Store sensitive data (passwords, API keys, TLS certs).

**Options:**
1. **Kubernetes Secrets:** Built-in, base64 encoded (not encrypted by default)
2. **Sealed Secrets:** Encrypt secrets that can be committed to Git
3. **External Secrets Operator:** Sync secrets from external providers (AWS Secrets Manager, Vault, etc.)

---

## Common Security Mistakes

| Mistake | Why It's Bad | Fix |
|---------|--------------|-----|
| Running containers as root | If container is compromised, attacker has root access | Run as non-root user |
| Allowing privilege escalation | Container can gain more privileges | Set `allowPrivilegeEscalation: false` |
| Using `ClusterRoleBinding` for regular users | Grants cluster-wide access | Use namespace-scoped `RoleBinding` |
| No network policies | Any pod can talk to any pod | Implement default-deny + allow rules |
| Storing secrets in plain YAML | Anyone with repo access can read them | Use Sealed Secrets or external provider |
| Using `latest` tag | Unpredictable deployments, hard to rollback | Use specific version tags |
| `kubectl apply --validate=false` | Skips validation, can deploy broken configs | Fix your YAML instead |
| Giving `cluster-admin` to everyone | Anyone can do anything | Create specific roles per use case |
| No resource limits | One pod can starve the whole node | Set requests and limits |
| Exposing services directly with NodePort | Bypasses network policies | Use Ingress with proper rules |

---

## Security Checklist

Use this checklist before deploying to production:

- [ ] All pods run as non-root
- [ ] All pods have resource limits set
- [ ] Network policies are in place (at least default-deny)
- [ ] RBAC is configured (no cluster-admin for regular users)
- [ ] Secrets are encrypted (Sealed Secrets or external provider)
- [ ] Pod Security Admission is enabled
- [ ] Containers use specific image tags (no `:latest`)
- [ ] Ingress uses TLS (cert-manager + Let's Encrypt)
- [ ] Audit logging is enabled
- [ ] Regular security scans are configured

---

## Using This Section

```bash
# 1. Apply RBAC rules
kubectl apply -f rbac/

# 2. Apply network policies
kubectl apply -f network-policy/

# 3. Enable pod security
kubectl apply -f pod-security/

# 4. Choose a secrets solution
cd secrets/
```

---

## Testing Security

```bash
# Test RBAC - can a developer list pods?
kubectl auth can-i list pods --as=developer

# Test network policies - can frontend reach backend?
kubectl run test -image=busybox --rm -it --restart=Never -- wget -O- http://backend-service:8000/health

# Check pod security context
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'

# Check for secrets in plain text
grep -r "kind: Secret" --include="*.yaml" | grep -v "sealed"
```

---

**Happy K8sing! 🚀** — Dhyanesh Siddhartha
