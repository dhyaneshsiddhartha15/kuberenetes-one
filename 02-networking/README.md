# 02-Networking: CNI, LoadBalancer, and Ingress

> 💬 **Dhyanesh's note:** Networking was the most confusing part for me. Why were my LoadBalancer services stuck in `<pending>`? Why couldn't pods talk to each other? This section clears up all that confusion.

---

## What is a CNI Plugin?

**CNI** = Container Network Interface. It's the plugin that handles pod-to-pod networking.

**Analogy:** Think of the CNI as the "network switch" for your cluster. Without it, pods are like computers with network cards but no cables plugged in — they can't talk to each other.

**Why Calico?**
- Mature, production-grade, widely used
- Supports both pure networking and network policies (security)
- Great documentation and community support
- Dual-stack IPv4 + IPv6 support (which we're using!)

---

## What is MetalLB?

**Problem:** On cloud providers (AWS, GKE, EKS), Services of type `LoadBalancer` automatically get a real external IP. On AWS EC2 instances without cloud load balancers, they stay stuck in `<pending>` state forever.

**Solution:** MetalLB is a load-balancer implementation for bare metal and cloud instances. It:
1. Allocates IP addresses from a pool you define
2. Advertises those IPs via ARP (Layer 2) or BGP
3. Responds to ARP requests so traffic reaches your cluster

**In plain English:** MetalLB gives external IPs to your Services, just like a cloud load balancer would, but works on your AWS EC2 instances without additional AWS load balancer costs.

---

## What is ingress-nginx?

**Ingress** is a Kubernetes resource that routes HTTP/HTTPS traffic to Services based on hostnames and paths.

**ingress-nginx** is an Ingress controller that:
1. Watches for Ingress resources
2. Configures nginx to route traffic according to those rules
3. Runs as a LoadBalancer Service (gets IP from MetalLB)

**Why use Ingress instead of just LoadBalancer Services?**
- One IP for many applications
- Path-based routing (`/` → frontend, `/api` → backend)
- TLS termination at the ingress level
- Hostname-based routing (`app1.example.com`, `app2.example.com`)

---

## Traffic Flow: End to End

```
User's Browser
      │
      ▼
myapp.example.com
      │
      ▼
┌─────────────────────────────────────┐
│  MetalLB IP (e.g., 192.168.1.200)   │
│  (Advertised via ARP on AWS VPC)    │
└─────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────┐
│  ingress-nginx Service              │
│  (LoadBalancer, type=LoadBalancer)  │
│  External IP: 192.168.1.200         │
└─────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────┐
│  ingress-nginx Pod                  │
│  (Reads Ingress resources,          │
│   configures nginx routing rules)   │
└─────────────────────────────────────┘
      │
      ├─ /  → frontend-service:8080
      │         └─ Frontend Pod(s)
      │
      └─ /api → backend-service:8000
                 └─ Backend Pod(s)
```

---

## Script Execution Order

Run these scripts **in order** after your cluster is initialized:

```bash
# Step 1: Install Calico CNI (required for pods to communicate)
sudo bash 01-install-calico.sh

# Step 2: Install MetalLB (for LoadBalancer IPs)
sudo bash 02-install-metallb.sh

# Step 3: Install ingress-nginx (for HTTP routing)
sudo bash 03-install-ingress-nginx.sh

# Step 4: Install cert-manager (for automatic TLS)
sudo bash 04-install-cert-manager.sh

# Step 5: Test everything works
bash 05-test-connectivity.sh
```

---

## Important: Configure MetalLB IP Pool

**Before running `02-install-metallb.sh`**, edit `metallb-config.yaml`:

```yaml
# Change this to match your VPC subnet!
spec:
  addresses:
  - 192.168.1.200-192.168.1.220  # ← Your VPC subnet range
```

**How to find your VPC subnet range:**
```bash
ip route | grep default
# Output: default via 192.168.1.1 dev eth0
# Your VPC subnet is probably: 192.168.1.0/24
```

**Important:** Make sure the IPs you choose are:
1. In your VPC subnet's range
2. Not assigned by AWS DHCP
3. Not in use by any other EC2 instance

---

## DNS Configuration

To use `myapp.example.com` with TLS, you need to point it to your MetalLB IP:

**Option 1: Local testing (on your machine)**
```bash
# Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
192.168.1.200  myapp.example.com grafana.myapp.example.com
```

**Option 2: Real DNS (for production)**
```bash
# In Route 53 or your DNS provider's dashboard:
myapp.example.com     A    192.168.1.200
grafana.myapp.example.com A  192.168.1.200
```

---

## Verifying Installation

After each script, you can verify:

| After Script | Verification Command | Expected Output |
|--------------|---------------------|-----------------|
| `01-install-calico.sh` | `kubectl get nodes` | All nodes Ready |
| `02-install-metallb.sh` | `kubectl get ipaddresspool` | Pool shows IPs allocated |
| `03-install-ingress-nginx.sh` | `kubectl get svc -n ingress-nginx` | EXTERNAL-IP assigned |
| `04-install-cert-manager.sh` | `kubectl get clusterissuer` | Two issuers Ready |

---

## Next Steps

Once networking is set up:

1. **Deploy your app:** Go to `../03-workloads/` to deploy the sample application
2. **Configure TLS:** Edit `../03-workloads/ingress.yaml` with your domain
3. **Set up monitoring:** Go to `../05-monitoring/` for Prometheus + Grafana

---

**Happy K8sing! 🚀** — Dhyanesh Siddhartha
