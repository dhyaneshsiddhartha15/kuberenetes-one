# 03-Workloads: Deploy Applications on Kubernetes

> 💬 **Dhyanesh's note:** This is the fun part! You'll deploy a real application with frontend, backend, TLS certificates, and autoscaling. I'll show you the exact steps to deploy ANY app on this cluster.

---

## How to Deploy ANY App on This Cluster

This is the generic step-by-step guide. Follow these steps for any application you want to deploy.

### Step 1: Containerize Your App

Write a `Dockerfile` for your application:

```dockerfile
# Example for a Python app
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "main.py"]
```

Build and push to a registry:

```bash
# Build
docker build -t yourusername/yourapp:v1.0 .

# Push to Docker Hub (or your registry)
docker push yourusername/yourapp:v1.0
```

**Tip:** For local development without a registry, you can:
- Use `imagePullPolicy: Never` and load images on nodes
- Run a local registry: `docker run -d -p 5000:5000 registry:2`

---

### Step 2: Create a Namespace

Namespaces isolate your applications:

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
  labels:
    app: myapp
    environment: production
```

Apply it:

```bash
kubectl apply -f namespace.yaml
```

---

### Step 3: Create a Deployment

The Deployment manages your application pods:

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: yourusername/yourapp:v1.0
        ports:
        - containerPort: 8000
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
kubectl apply -f deployment.yaml
```

---

### Step 4: Create a Service

The Service provides stable networking to your pods:

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: myapp
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8000
```

```bash
kubectl apply -f service.yaml
```

---

### Step 5: Create an Ingress with TLS

The Ingress routes external traffic to your Service:

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: myapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

```bash
kubectl apply -f ingress.yaml
```

---

### Step 6: Verify

Check that everything is running:

```bash
# Check pods
kubectl get pods -n myapp

# Check service
kubectl get svc -n myapp

# Check ingress
kubectl get ingress -n myapp

# Test the endpoint (add /etc/hosts entry if using test domain)
curl https://myapp.example.com
```

---

## The Sample Application

This folder contains a complete sample application with:

- **Backend:** FastAPI with `/health` and `/api/hello` endpoints
- **Frontend:** Simple HTML page that calls the backend API
- **Single Domain:** Both services on `myapp.example.com`
- **Path Routing:** `/` → frontend, `/api` → backend

### Architecture

```
User Browser
      │
      ▼
myapp.example.com
      │
      ├─ /           → Frontend (nginx)
      │                    └── Fetches /api/hello
      │
      └─ /api/*      → Backend (FastAPI)
                           └── Returns JSON response
```

### How Path Routing Works

The Ingress uses path-based routing with rewrite:

```yaml
# Frontend: no rewrite needed
path: /
backend:
  service:
    name: frontend-service

# Backend: rewrite /api/* to /*
path: /api(/|$)(.*)
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2
backend:
  service:
    name: backend-service
```

**Example:**
- Request: `GET /api/hello`
- Ingress rewrites to: `GET /hello`
- Backend receives: `GET /hello`

---

## Horizontal Pod Autoscaler (HPA)

The HPA automatically scales your pods based on CPU/memory:

```bash
# Create HPA
kubectl apply -f backend/hpa.yaml

# Check HPA status
kubectl get hpa -n myapp

# Generate load to test scaling
kubectl run load-generator --image=busybox --restart=Never -i -- tty -- sh
# Inside pod: while true; do wget -q -O- http://backend-service:8000/api/hello; done
```

**How it works:**
1. You set `targetCPUUtilizationPercentage: 70`
2. When CPU exceeds 70%, HPA adds more pods
3. When CPU drops below, HPA removes pods

---

## Useful kubectl Commands

| Command | Description |
|---------|-------------|
| `kubectl get pods -n <namespace>` | List all pods |
| `kubectl get svc -n <namespace>` | List all services |
| `kubectl get ingress -n <namespace>` | List all ingresses |
| `kubectl describe pod <name> -n <namespace>` | Show pod details |
| `kubectl logs <pod-name> -n <namespace>` | Show pod logs |
| `kubectl exec -it <pod-name> -n <namespace> -- sh` | Open shell in pod |
| `kubectl scale deployment <name> --replicas=5 -n <namespace>` | Scale manually |
| `kubectl rollout restart deployment <name> -n <namespace>` | Restart deployment |
| `kubectl rollout undo deployment <name> -n <namespace>` | Rollback update |
| `kubectl delete -f <file.yaml>` | Delete resources |
| `kubectl get all -n <namespace>` | Show everything |

---

## Deploy the Sample App

```bash
# Option 1: Using the deploy script
bash deploy-app.sh

# Option 2: Manual deployment
kubectl apply -f 00-namespace.yaml
kubectl apply -f backend/
kubectl apply -f frontend/
kubectl apply -f ingress.yaml

# Option 3: Using Helm
cd helm-deploy
helm install myapp ./myapp-chart
```

After deployment, add to `/etc/hosts`:

```bash
# Get the ingress external IP
INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$INGRESS_IP myapp.example.com" | sudo tee -a /etc/hosts
```

Then visit: `https://myapp.example.com`

---

## Troubleshooting

**Pods not starting?**
```bash
kubectl describe pod <pod-name> -n myapp
kubectl logs <pod-name> -n myapp
```

**Service not reachable?**
```bash
kubectl get endpoints <service-name> -n myapp
kubectl port-forward svc/backend-service 8000:80 -n myapp
```

**Ingress not working?**
```bash
kubectl describe ingress myapp -n myapp
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

**Certificate not issued?**
```bash
kubectl get certificate -n myapp
kubectl describe certificate <cert-name> -n myapp
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager
```

---

**Happy K8sing! 🚀** — Dhyanesh
