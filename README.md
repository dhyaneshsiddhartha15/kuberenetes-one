# Kubernetes from Zero

> 💬* This repo captures my real journey learning Kubernetes from scratch. Every script here has been tested on actual AWS cloud instances (Ubuntu 24.04 LTS) — not managed services, not kind/minikube shortcuts. I made every mistake in the book so you don't have to.

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


---

## License

MIT License — feel free to use this for learning, teaching, or building your own clusters.

---

**Happy K8sing! 🚀**

— Dhyanesh Siddhartha, 2026
