# 01-Setup: Initialize Your Kubernetes Cluster

> 💬 **Dhyanesh's note:** This is where the magic happens. You'll go from a fresh Ubuntu install to a running Kubernetes cluster using kubeadm — the official tool for bootstrapping K8s clusters. No managed services, no shortcuts. Just you and the control plane.

---

## What is kubeadm?

`kubeadm` is Kubernetes' official cluster initialization tool. It handles the complex stuff:
- Setting up the control plane components (API server, scheduler, controller manager, etcd)
- Configuring certificates and authentication
- Joining worker nodes to the cluster

**Control Plane vs Worker Nodes (in plain English):**

| Component | Control Plane Node | Worker Node |
|-----------|-------------------|-------------|
| **Role** | The "brain" of the cluster | The "muscle" that runs your apps |
| **Runs** | API Server, Scheduler, Controller, etcd | kubelet, container runtime, your pods |
| **Decisions** | WHERE to schedule pods, HOW many replicas | Actually RUNNING the containers |
| **Quantity** | Usually 1 (for learning) or 3 (for HA) | As many as you need |

---

## Script Execution Order

Run these scripts **in order** on your control plane node:

```bash
# Step 0: Pre-flight checks
sudo bash 00-system-check.sh

# Step 1: Install prerequisites (containerd, kernel modules)
sudo bash 01-setup-prerequisites.sh

# Step 2: Install kubeadm, kubelet, kubectl
sudo bash 02-install-kubeadm.sh

# Step 3: Initialize the control plane
sudo bash 03-init-control-plane.sh

# Step 4: (On worker nodes) Join the cluster
sudo bash 04-join-worker.sh

# Step 5: Verify everything works
bash 05-verify-cluster.sh
```

---

## Common Errors (and How I Fixed Them)

### Error 1: "swap is enabled"

**Symptom:** `kubeadm init` fails immediately with message about swap being enabled.

**Fix:** Run `01-setup-prerequisites.sh` which disables swap permanently by:
1. Running `swapoff -a` (turn off swap now)
2. Commenting out swap line in `/etc/fstab` (prevent swap on reboot)

**Why this happens:** Kubernetes requires swap to be off because kubelet needs to manage memory precisely.

---

### Error 2: "port 6443 is already in use"

**Symptom:** `kubeadm init` fails saying the API server port is taken.

**Fix:** Check what's using the port:
```bash
sudo lsof -i :6443
```
If you see another process, kill it OR reinitialize with a different port (not recommended for learning).

**Pro tip:** Run `00-system-check.sh` BEFORE starting — it checks all required ports.

---

### Error 3: "CoreDNS pods are stuck in Pending"

**Symptom:** After `kubeadm init`, you see:
```
NAME           STATUS     ROLES           AGE   VERSION
master-node    NotReady   control-plane   5m    v1.30.0
```
And CoreDNS pods won't start.

**Fix:** Install a CNI plugin! Run the scripts in `02-networking/`. Without a CNI, your nodes can't become Ready, so CoreDNS has nowhere to run.

**Why:** Kubernetes needs a Container Network Interface plugin to handle pod-to-pod networking. kubeadm doesn't install one automatically.

---

### Error 4: "The connection to the server localhost:8080 was refused"

**Symptom:** Running `kubectl get nodes` gives connection error.

**Fix:** Set up your kubeconfig:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

This is done automatically by `03-init-control-plane.sh`.

---

## What to Verify After Each Step

| After Script | Run This Command | Expected Output |
|--------------|------------------|-----------------|
| `00-system-check.sh` | (Script prints table) | All checks GREEN |
| `01-setup-prerequisites.sh` | `systemctl status containerd` | Active (running) |
| `02-install-kubeadm.sh` | `kubeadm version` | Version v1.30.x |
| `03-init-control-plane.sh` | `kubectl get nodes` | Your node, Ready |
| `04-join-worker.sh` | `kubectl get nodes` | Control plane + worker(s) |
| `05-verify-cluster.sh` | (Script runs tests) | All tests PASS |

---

## Next Steps

Once your cluster is verified:

1. **Install Networking:** Go to `../02-networking/` to install Calico CNI
2. **Install LoadBalancer:** Set up MetalLB so your Services get external IPs
3. **Deploy Apps:** Move to `../03-workloads/` to run your first application

---

**Happy K8sing! 🚀** — Dhyanesh
