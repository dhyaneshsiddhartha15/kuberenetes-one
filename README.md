# Kubernetes from Zero

> 💬 **Dhyanesh's note:** This repo captures my real journey learning Kubernetes from scratch in 2026. Every script here has been tested on actual AWS cloud instances (Ubuntu 24.04 LTS) — not managed services, not kind/minikube shortcuts. I made every mistake in the book so you don't have to.

---

## What You Will Learn

| Topic | What You'll Master |
|-------|-------------------|
| **Cluster Setup** | Building a K8s cluster from scratch using kubeadm on AWS EC2 instances |
| **Container Runtime** | Installing and configuring containerd properly |
| **Networking** | Calico CNI, MetalLB load balancer, ingress-nginx, dual-stack IPv4+IPv6 |
| **TLS & Certificates** | Automated HTTPS with cert-manager + Let's Encrypt |
| **Workloads** | Deployments, Services, Ingress, HPA, ConfigMaps, Secrets |
| **Helm** | Package management and creating your own charts |
| **Security** | RBAC, Network Policies, Pod Security, Secrets management |
| **Monitoring** | Prometheus + Grafana with kube-prometheus-stack |

---

## Prerequisites (Step 0)

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |
| **RAM** | 2GB per node | 4GB per node |
| **CPU** | 2 cores | 4+ cores |
| **Instance Type** | t3.medium | t3.large or better |
| **Network** | Security groups open for ports 6443, 2379-2380, 10250, 10251, 10252 | All nodes in same VPC |
| **Tools** | curl, wget, git | - |

---

## Repository Structure

```
kubernetes-from-zero/
├── 01-setup/              # Cluster initialization with kubeadm
├── 02-networking/         # CNI, MetalLB, ingress-nginx, cert-manager
├── 03-workloads/          # Sample app (frontend + backend) + Helm chart
├── 04-security/           # RBAC, NetworkPolicies, Pod Security, Secrets
├── 05-monitoring/         # Prometheus + Grafana stack
├── scripts/               # Automation scripts (run these!)
└── README.md              # This file
```

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/dhyanesh-siddhartha/kubernetes-from-zero.git
cd kubernetes-from-zero

# Run the full cluster setup (on your control plane node)
sudo bash scripts/full-cluster-setup.sh

# Deploy the sample application
bash scripts/deploy-app.sh

# Check cluster health
bash scripts/health-check.sh
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Cloud Infrastructure                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    kubeadm                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │ Control Plane│  │ Worker Node 1│  │ Worker Node 2│  │   │
│  │  │  (EC2 Instance)│  │  (EC2 Instance)│  │  (EC2 Instance)│  │   │
│  │  │              │  │              │  │              │  │   │
│  │  │  API Server  │  │   kubelet    │  │   kubelet    │  │   │
│  │  │  Scheduler   │  │  containerd  │  │  containerd  │  │   │
│  │  │ Controller   │  │    Calico    │  │    Calico    │  │   │
│  │  │    etcd      │  │              │  │              │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        MetalLB                                    │
│                    (External IPs)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ingress-nginx                                │
│                   (LoadBalancer Service)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────┐           ┌─────────────────────┐
│     Frontend        │           │      Backend        │
│   (nginx:alpine)    │◄──────────►│   (FastAPI/Python)  │
│  Port 8080          │  /api/hello│   Port 8000         │
└─────────────────────┘           └─────────────────────┘
```

---

## Section Index

| Section | Description | Link |
|---------|-------------|------|
| **01. Setup** | Initialize cluster with kubeadm | [01-setup/README.md](01-setup/README.md) |
| **02. Networking** | CNI, MetalLB, Ingress, TLS | [02-networking/README.md](02-networking/README.md) |
| **03. Workloads** | Deploy apps with YAML and Helm | [03-workloads/README.md](03-workloads/README.md) |
| **04. Security** | RBAC, NetworkPolicies, Secrets | [04-security/README.md](04-security/README.md) |
| **05. Monitoring** | Prometheus + Grafana | [05-monitoring/README.md](05-monitoring/README.md) |

---

## Dhyanesh's Journey

I started learning Kubernetes in early 2026 because I was tired of clicking through AWS consoles and paying $100+/month for managed services that I didn't fully understand. I wanted to know what happens under the hood — what kubeadm actually does, how CNI plugins make pods talk to each other, why my LoadBalancer services stayed stuck in `<pending>` state.

I built this cluster using AWS EC2 instances (t3.medium and t3.large) to get real cloud experience. I messed up security group settings (twice!), fought with VPC network conflicts, spent hours debugging why CoreDNS pods wouldn't start (turns out I had the wrong CIDR), and accidentally terminated my control plane instance more times than I care to admit.

But every mistake taught me something. Now I can spin up a production-ready cluster in under 30 minutes, deploy apps with proper TLS, autoscaling, monitoring — all on AWS cloud infrastructure. This repo is that journey, distilled into scripts and documentation that actually work.

If you're following along: take your time, read the error messages, and don't be afraid to break things. That's how you learn.

---

## License

MIT License — feel free to use this for learning, teaching, or building your own clusters.

---

**Happy K8sing! 🚀**

— Dhyanesh Siddhartha, 2026
