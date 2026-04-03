## Application

This repository now contains:

- ASP.NET API in src/apps/api-aspnet
- Blazor Web App frontend in src/apps/frontend-blazor

The app currently provides:

- Auth routes: `/login`, `/register`, `/changepassword`
- Protected admin routes: `/admin/home`, `/admin/users`, `/admin/series`
- Users list/details/delete
- Series dashboard, list, details, add, update, and delete

### Local Run

1. Restore and build the solution:

```bash
dotnet build appd5016-final-project.sln
```

2. Run the Blazor app:

```bash
dotnet run --project src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj
```

3. Run the API (separate terminal):

```bash
dotnet run --project src/apps/api-aspnet/SeriesCatalog.WebApi.csproj
```

4. Open the local apps:

- Frontend: http://localhost:5204
- API: http://localhost:5130

### Docker Run

From the repository root:

1. Create a local Docker env file (one-time setup):

```powershell
Copy-Item deploy/docker/.env.example deploy/docker/.env
```

2. Start the stack:

```bash
docker compose --env-file deploy/docker/.env -f deploy/docker/docker-compose.yml up --build -d
```

3. Open the containerized apps:

- Frontend: http://localhost:8082 (or the port configured by FRONTEND_PORT)

Security note: only the frontend is published on the host. API is internal-only and reachable by the frontend via the Docker network (`http://api:8080`).

4. Stop and remove the stack when done:

```bash
docker compose --env-file deploy/docker/.env -f deploy/docker/docker-compose.yml down
```

### k3s Baseline

This repository now includes a clean Kubernetes baseline under `deploy/k8s/base` with:

- Namespace
- Mongo secret placeholder
- API deployment + service
- Frontend deployment + service
- Path-based ingress (`/`, `/api`, `/auth`, `/users`, `/series`)

Apply it with:

```bash
kubectl apply -k deploy/k8s/base
```

If needed, customize:

- `deploy/k8s/base/secret.yaml` for Mongo connection settings
- `deploy/k8s/base/ingress.yaml` for host/domain and TLS
- `deploy/k8s/base/deployment-*.yaml` for image names/tags and replica counts

For Docker Desktop overlays and ingress-nginx installation steps, see `deploy/k8s/README.md`.

Quick start (Docker Desktop Kubernetes):

```powershell
$ErrorActionPreference = "Stop"
$ctx = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
if (-not $ctx) { throw "No docker-desktop/kind context found. Enable Kubernetes in Docker Desktop first." }

kubectl config use-context $ctx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s

docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .

kubectl apply -k deploy/k8s/overlays/docker-desktop-single
kubectl get pods,svc,ingress -n seriescatalog
```

Use `deploy/k8s/overlays/docker-desktop` instead if you want the 2+2 replica setup.

Frontend-only Kubernetes update:

```powershell
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .
kubectl apply -k deploy/k8s/overlays/docker-desktop-single
kubectl rollout restart deployment/seriescatalog-frontend -n seriescatalog
kubectl rollout status deployment/seriescatalog-frontend -n seriescatalog --timeout=180s
```

Backend-only Kubernetes update:

```powershell
docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
kubectl apply -k deploy/k8s/overlays/docker-desktop-single
kubectl rollout restart deployment/seriescatalog-api -n seriescatalog
kubectl rollout status deployment/seriescatalog-api -n seriescatalog --timeout=180s
```

For full context-selection and troubleshooting steps, see `deploy/k8s/README.md`.

### Local Configuration

- Frontend settings: src/apps/frontend-blazor/appsettings.json and src/apps/frontend-blazor/appsettings.Development.json
- API settings: src/apps/api-aspnet/appsettings.json and src/apps/api-aspnet/appsettings.Development.json
- Default frontend API base URL points to http://localhost:5130

## Migration Docs

- Migration prompts live in `.github/prompts/`
- API migration planning and gate documentation live in docs/api-migration

