# Helm Charts: Deploy Any App with Helm

> 💬 **Dhyanesh's note:** Helm is like apt/yum for Kubernetes. Instead of managing dozens of YAML files, you package everything into a "chart" and deploy with one command. Game changer!

---

## What is Helm?

**Helm** is a package manager for Kubernetes. It helps you:

- **Package applications** into reusable charts
- **Deploy complex apps** with a single command
- **Manage configuration** through values files
- **Upgrade and rollback** releases easily
- **Share applications** with your team or community

**Analogy:** Think of Helm as the "app store" for Kubernetes. A Helm chart is like a package (think `.deb` or `.rpm`), and a release is an installed instance of that package.

---

## Helm Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Chart** | A package of Kubernetes manifests | `myapp-chart/` |
| **Release** | An installed instance of a chart | `helm install myapp myapp-chart` |
| **Values** | Configuration values for a chart | `values.yaml` |
| **Template** | Go template files that generate manifests | `templates/deployment.yaml` |
| **Repository** | A collection of charts | `https://charts.bitnami.com/bitnami` |

---

## How to Install Helm

```bash
# Download and install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version

# Add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for charts
helm search repo bitnami
```

---

## Using Existing Charts

Deploy a third-party application in 2 commands:

```bash
# Add the repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Deploy Redis
helm install my-redis bitnami/redis \
    --set password=secretpassword \
    --set architecture=standalone

# Check status
helm status my-redis

# Uninstall
helm uninstall my-redis
```

---

## Creating Your Own Chart

### Step 1: Create a New Chart

```bash
helm create myapp-chart
```

This creates a folder structure:

```
myapp-chart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── charts/             # Dependency charts
├── templates/          # Template files
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── NOTES.txt       # Post-install notes
└── .helmignore         # Files to exclude
```

### Step 2: Understand the Folder Structure

| File/Folder | Purpose |
|-------------|---------|
| `Chart.yaml` | Chart metadata (name, version, description) |
| `values.yaml` | Default configuration values |
| `templates/` | Kubernetes manifest templates (Go templates) |
| `templates/NOTES.txt` | Message shown after install |
| `charts/` | Chart dependencies |
| `.helmignore` | Files to exclude from package |

### Step 3: Edit values.yaml

```yaml
# values.yaml
replicaCount: 2

image:
  repository: myregistry/myapp
  tag: "v1.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  hosts:
    - host: myapp.example.com
  tls:
    - secretName: myapp-tls
```

### Step 4: Install Your Chart

```bash
# Install with default values
helm install myapp ./myapp-chart

# Install with custom values
helm install myapp ./myapp-chart \
    --set replicaCount=3

# Install with values file
helm install myapp ./myapp-chart \
    -f custom-values.yaml
```

### Step 5: Upgrade Your Release

```bash
# Upgrade with new values
helm upgrade myapp ./myapp-chart \
    --set replicaCount=5

# Upgrade with new values file
helm upgrade myapp ./myapp-chart \
    -f production-values.yaml
```

### Step 6: Rollback if Something Goes Wrong

```bash
# List release history
helm history myapp

# Rollback to previous version
helm rollback myapp

# Rollback to specific revision
helm rollback myapp 2
```

---

## Adding Helm Repositories

```bash
# Add a repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io

# Update repository cache
helm repo update

# List repositories
helm repo list

# Remove a repository
helm repo remove prometheus-community
```

---

## Helm vs kubectl apply: When to Use Which

| Scenario | Use |
|----------|-----|
| **Learning Kubernetes** | `kubectl apply` - see every YAML |
| **Simple deployments** | `kubectl apply` - straightforward |
| **Complex apps (10+ resources)** | Helm - manage as one unit |
| **Production deployments** | Helm - versioning, rollback |
| **Sharing with team** | Helm - reusable charts |
| **Quick testing** | `kubectl apply` - faster iteration |
| **Multi-environment** | Helm - values files per env |
| **GitOps (ArgoCD, Flux)** | Helm charts or raw YAML |

---

## Helm Commands Reference

| Command | Description |
|---------|-------------|
| `helm create <name>` | Create a new chart |
| `helm install <release> <chart>` | Install a chart |
| `helm upgrade <release> <chart>` | Upgrade a release |
| `helm uninstall <release>` | Uninstall a release |
| `helm list` | List releases |
| `helm status <release>` | Show release status |
| `helm history <release>` | Show release history |
| `helm rollback <release> [revision]` | Rollback to revision |
| `helm get values <release>` | Show release values |
| `helm get manifest <release>` | Show generated manifests |
| `helm diff upgrade <release> <chart>` | Show upgrade diff |
| `helm lint <chart>` | Lint a chart |
| `helm template <chart>` | Render templates (dry-run) |
| `helm package <chart>` | Package a chart |
| `helm pull <repo/chart>` | Download a chart |
| `helm search repo <keyword>` | Search for charts |
| `helm show values <repo/chart>` | Show chart's default values |
| `helm repo add <name> <url>` | Add a repository |
| `helm repo update` | Update repositories |
| `helm env` | Show Helm environment |

---

## The myapp-chart

This folder contains a complete Helm chart for the myapp application.

### Deploy with Helm

```bash
# Install the chart
helm install myapp ./myapp-chart

# Install with custom values
helm install myapp ./myapp-chart \
    --set ingress.host=myapp.example.com

# Install with values file
helm install myapp ./myapp-chart \
    -f values-production.yaml

# Upgrade
helm upgrade myapp ./myapp-chart

# Uninstall
helm uninstall myapp
```

---

**Happy K8sing! 🚀** — Dhyanesh
