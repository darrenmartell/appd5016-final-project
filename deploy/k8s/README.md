# k3s Baseline Deployment

This folder contains a clean baseline for running the app on k3s:

- `base/` contains core resources (namespace, secret, deployments, services, ingress).
- `optional/hpa.yaml` enables autoscaling once metrics server is available.
- `overlays/docker-desktop/` adapts ingress and images for Docker Desktop Kubernetes.
- `overlays/docker-desktop-single/` keeps Docker Desktop settings but forces one API pod and one frontend pod.

## 1) Update Images and Secrets

Before applying:

1. Update image names/tags in:
   - `base/api-deployment.yaml`
   - `base/frontend-deployment.yaml`
2. Set Mongo values in:
   - `base/secret.yaml`

## 2) Apply Baseline

```bash
kubectl apply -k deploy/k8s/base
```

## 3) Verify

```bash
kubectl get pods -n seriescatalog
kubectl get svc -n seriescatalog
kubectl get ingress -n seriescatalog
```

## 4) Optional Autoscaling

```bash
kubectl apply -f deploy/k8s/optional/hpa.yaml
kubectl get hpa -n seriescatalog
```

## Docker Desktop Kubernetes

This overlay keeps `base/` untouched and applies Docker Desktop defaults:

- Uses `ingressClassName: nginx`
- Removes Traefik-specific annotations
- Rewrites images to local Docker images (`docker-api:latest`, `docker-frontend:latest`)

Build local images first:

```bash
docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .
```

Apply overlay:

```bash
kubectl config use-context docker-desktop
kubectl apply -k deploy/k8s/overlays/docker-desktop
```

For a lighter local footprint (1 API + 1 frontend replica), apply:

```bash
kubectl config use-context docker-desktop
kubectl apply -k deploy/k8s/overlays/docker-desktop-single
```

Install ingress-nginx first if needed:

```bash
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl cluster-info
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s
kubectl get ingressclass
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

Expected result: an ingress class named `nginx` and a ready `ingress-nginx-controller` deployment.

Troubleshooting:

- If `docker-desktop` context is missing, enable Kubernetes in Docker Desktop first.
- If `current-context is not set`, run `kubectl config use-context docker-desktop`.
- If you cannot connect to `localhost:8080`, kubectl is not pointing at a running cluster.
- If you see `The antiforgery token could not be decrypted` after refreshes with multiple frontend replicas, verify shared key storage is mounted:
   - `kubectl get pvc -n seriescatalog`
   - `kubectl describe pvc seriescatalog-frontend-keys -n seriescatalog`
   - then restart frontend pods and clear browser cookies once.

One-shot PowerShell bootstrap (context + ingress-nginx + image build + deploy):

```powershell
$ErrorActionPreference = "Stop"

# Pick Docker Desktop or kind context automatically.
$ctx = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
if (-not $ctx) { throw "No docker-desktop/kind context found. Enable Kubernetes in Docker Desktop first." }

kubectl config use-context $ctx
kubectl cluster-info
kubectl get nodes

# Install ingress-nginx.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s
kubectl get ingressclass
kubectl get pods -n ingress-nginx

# Build local images for Docker Desktop overlays.
docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .

# Deploy lighter local overlay (1 API + 1 frontend replica).
kubectl apply -k deploy/k8s/overlays/docker-desktop-single
kubectl rollout status deployment/seriescatalog-api -n seriescatalog --timeout=180s
kubectl rollout status deployment/seriescatalog-frontend -n seriescatalog --timeout=180s
kubectl get pods,svc,ingress -n seriescatalog
```

Use `deploy/k8s/overlays/docker-desktop` instead if you want the 2+2 replica setup.

## Update Existing Deployment

Use these when you already deployed and only changed one side.

Frontend-only update:

```powershell
$ErrorActionPreference = "Stop"
$ctx = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
if (-not $ctx) { throw "No docker-desktop/kind context found. Enable Kubernetes in Docker Desktop first." }

kubectl config use-context $ctx
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .
kubectl apply -k deploy/k8s/overlays/docker-desktop-single
kubectl rollout restart deployment/seriescatalog-frontend -n seriescatalog
kubectl rollout status deployment/seriescatalog-frontend -n seriescatalog --timeout=180s
kubectl get pods,svc,ingress -n seriescatalog
```

Backend-only update:

```powershell
$ErrorActionPreference = "Stop"
$ctx = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
if (-not $ctx) { throw "No docker-desktop/kind context found. Enable Kubernetes in Docker Desktop first." }

kubectl config use-context $ctx
docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
kubectl apply -k deploy/k8s/overlays/docker-desktop-single
kubectl rollout restart deployment/seriescatalog-api -n seriescatalog
kubectl rollout status deployment/seriescatalog-api -n seriescatalog --timeout=180s
kubectl get pods,svc,ingress -n seriescatalog
```

Swap `deploy/k8s/overlays/docker-desktop-single` with `deploy/k8s/overlays/docker-desktop` if you are running the 2+2 replica overlay.

## Teardown

App teardown script (keeps cluster and ingress controller):

```powershell
pwsh deploy/k8s/scripts/teardown-app.ps1
```

App teardown with 2+2 overlay selection:

```powershell
pwsh deploy/k8s/scripts/teardown-app.ps1 -Overlay docker-desktop
```

App teardown plus persistent key storage cleanup:

```powershell
pwsh deploy/k8s/scripts/teardown-app.ps1 -DeletePvc
```

Full teardown (deletes app overlays and namespace):

```powershell
pwsh deploy/k8s/scripts/teardown-full.ps1
```

Full teardown including ingress-nginx uninstall:

```powershell
pwsh deploy/k8s/scripts/teardown-full.ps1 -DeleteIngressNginx
```

## Routing Model

- Frontend traffic: `/`
- API traffic: `/api`, `/auth`, `/users`, `/series`
- Frontend service uses `sessionAffinity: ClientIP` to reduce Blazor Server reconnect issues.
