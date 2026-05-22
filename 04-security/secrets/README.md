# Secrets Management in Kubernetes

> 💬 **Dhyanesh's note:** Never commit plain secrets to Git. I learned this when I accidentally pushed an API key to a public repo. Use one of these secure methods instead.

---

## Overview

Kubernetes Secrets store sensitive data like passwords, OAuth tokens, and SSH keys. However, they're only base64-encoded by default, not encrypted. This section shows you three ways to manage secrets securely.

---

## Option 1: Kubernetes Secrets (Basic)

**Pros:**
- Built into Kubernetes
- Simple to use
- Works everywhere

**Cons:**
- Base64 encoding (anyone can decode)
- Stored in etcd (unless encryption at rest is enabled)
- Can't commit to Git safely

**When to use:**
- Local development
- Testing
- When you have encryption at rest configured

```bash
# Create a secret from literal values
kubectl create secret generic my-secret \
    --from-literal=username=admin \
    --from-literal=password=secretpass

# Create from files
kubectl create secret generic tls-cert \
    --from-file=tls.crt=./cert.pem \
    --from-file=tls.key=./key.pem

# Use in deployment
kubectl apply -f example-secret.yaml
```

---

## Option 2: Sealed Secrets (Recommended for GitOps)

**Pros:**
- Encrypt secrets so they can be committed to Git
- Native Kubernetes integration
- Works with existing GitOps tools (ArgoCD, Flux)
- No external dependency

**Cons:**
- Requires installing controller
- Sealing process requires cluster access initially

**When to use:**
- GitOps workflows
- Teams committing infrastructure to Git
- Multi-environment deployments

```bash
# Install Sealed Secrets controller (see sealed-secret-install.sh)

# Seal a secret (creates a SealedSecret resource)
kubeseal -f my-secret.yaml -w my-sealed-secret.yaml

# Commit to Git
git add my-sealed-secret.yaml
git commit -m "Add sealed secret"

# Apply to cluster (controller will decrypt)
kubectl apply -f my-sealed-secret.yaml
```

---

## Option 3: External Secrets Operator (Enterprise)

**Pros:**
- Integrates with external secret managers
- One source of truth for secrets
- Supports AWS Secrets Manager, Azure Key Vault, HashiCorp Vault, etc.
- Automatic sync

**Cons:**
- External dependency
- More complex setup
- Cost of external secret manager

**When to use:**
- Enterprise environments
- Already using AWS Secrets Manager or Parameter Store
- Compliance requirements
- Centralized secret management across AWS services

```bash
# Install external-secrets-operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets

# Create SecretStore (points to external provider)
kubectl apply -f secretstore.yaml

# Create ExternalSecret (syncs from external)
kubectl apply -f external-secret.yaml
```

---

## Comparison Table

| Feature | K8s Secrets | Sealed Secrets | External Secrets |
|---------|-------------|----------------|------------------|
| **Encryption** | Base64 only | Public key encryption | Provider-dependent |
| **Git-safe** | No | Yes | Yes (spec only) |
| **External deps** | None | Controller | Controller + Provider |
| **Setup complexity** | Low | Medium | High |
| **Best for** | Local/dev | GitOps | Enterprise |
| **Cost** | Free | Free | Varies |

---

## Recommendation

For this learning project, use **Sealed Secrets**:
1. Run `sealed-secret-install.sh` to install the controller
2. Create your secret normally
3. Seal it with `kubeseal`
4. Commit the sealed secret to Git

---

**Happy K8sing! 🚀** — Dhyanesh Siddhartha
