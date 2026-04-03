# Kubernetes Deployment Guide

This folder contains Kubernetes manifests and scripts for three deployment targets: k3s baseline, Docker Desktop, and OCI OKE.

## 1) k3s Baseline

Use this section when you want a plain baseline deployment without Docker Desktop- or OCI-specific overlays.

### What this section is for

- Fast baseline install on any compatible Kubernetes cluster.
- Foundation manifests used by Docker Desktop and OCI overlays.

### Core resources

- `deploy/k8s/base/` for namespace, secret, deployments, services, ingress
- `deploy/k8s/optional/hpa.yaml` for optional autoscaling

### Script guidance

- No dedicated k3s baseline script is required.
- Use direct kubectl commands in the Baseline steps below.
- For scripted workflows, use Docker Desktop scripts or OCI scripts in their respective sections.

### Baseline steps

1. Update Mongo values in `deploy/k8s/base/secret.yaml`
2. Apply baseline manifests:

```bash
kubectl apply -k deploy/k8s/base
```

3. Verify:

```bash
kubectl get pods -n seriescatalog
kubectl get svc -n seriescatalog
kubectl get ingress -n seriescatalog
```

4. Optional HPA:

```bash
kubectl apply -f deploy/k8s/optional/hpa.yaml
kubectl get hpa -n seriescatalog
```

## 2) Docker Desktop

Use this section for local development on Docker Desktop (or local kind) with local Docker images.

### What this section is for

- Local inner-loop deployment and iteration.
- Scripted deploy/update/teardown workflows for Docker Desktop.

### Overlays

- `deploy/k8s/overlays/docker-desktop` for 2 API + 2 frontend replicas
- `deploy/k8s/overlays/docker-desktop-single` for 1 API + 1 frontend replica

### Script location

- `deploy/k8s/scripts/docker-desktop/`

### Script catalog

- `deploy-docker-desktop.ps1`: bootstrap + deploy (optionally installs ingress-nginx)
- `update-docker-desktop-frontend.ps1`: build/push local frontend image and restart frontend
- `update-docker-desktop-api.ps1`: build/push local API image and restart API
- `teardown-docker-desktop-app.ps1`: remove app resources only
- `teardown-docker-desktop-full.ps1`: remove app resources + namespace (optionally ingress-nginx)

### Common commands

Show help for all Docker Desktop scripts:

```powershell
pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1 -Help
pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-frontend.ps1 -Help
pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-api.ps1 -Help
pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-app.ps1 -Help
pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-full.ps1 -Help
```

One-shot local deploy (1+1):

```powershell
pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1
```

One-shot local deploy (2+2):

```powershell
pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1 -Overlay docker-desktop
```

Frontend-only update:

```powershell
pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-frontend.ps1
```

Backend-only update:

```powershell
pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-api.ps1
```

App teardown:

```powershell
pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-app.ps1
```

Full teardown:

```powershell
pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-full.ps1
```

### Docker Desktop notes

- If `docker-desktop` context is missing, enable Kubernetes in Docker Desktop first.
- If `current-context` is not set, run `kubectl config use-context docker-desktop`.
- If antiforgery token decrypt errors appear with multiple frontend replicas, verify shared key storage:

```powershell
kubectl get pvc -n seriescatalog
kubectl describe pvc seriescatalog-frontend-keys -n seriescatalog
```

### Docker Desktop known issue

Docker Desktop can hit kube-proxy iptables issues that break ClusterIP routing. Full fix details:

- [docs/kube-proxy-ipvs-fix.md](../../docs/kube-proxy-ipvs-fix.md)

Quick verify command:

```powershell
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=10 | Select-String "Proxier|Sync failed"
```

### Docker Desktop traffic logs

```powershell
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f --since=2m
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f --since=2m | Select-String -Pattern "/api|/_blazor|/auth|/users|/series"
kubectl logs -n seriescatalog deployment/seriescatalog-frontend -f --since=2m
kubectl logs -n seriescatalog deployment/seriescatalog-api -f --since=2m
```

## 3) OCI OKE

Use this section when deploying to Oracle Kubernetes Engine (OKE) with images stored in OCIR.

### What this section is for

- OKE deployments using OCI overlays.
- Scripted deploy/update/teardown flows with OCIR image publishing.

### Overlays

- `deploy/k8s/overlays/oci` for 2 API + 2 frontend replicas
- `deploy/k8s/overlays/oci-single` for 1 API + 1 frontend replica

### Script location

- `deploy/k8s/scripts/oci/`

### Script catalog

- `deploy-oci.ps1`: build/push images, patch overlay tags, set kubeconfig, deploy
- `update-oci-frontend.ps1`: frontend image update + rollout
- `update-oci-api.ps1`: API image update + rollout
- `teardown-oci-app.ps1`: remove app resources only
- `teardown-oci-full.ps1`: remove app resources + namespace (optionally ingress-nginx)

### Common commands

Show help for all OCI scripts:

```powershell
pwsh deploy/k8s/scripts/oci/deploy-oci.ps1 -Help
pwsh deploy/k8s/scripts/oci/update-oci-frontend.ps1 -Help
pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 -Help
pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1 -Help
pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1 -Help
```

Deploy to OKE (1+1):

```powershell
pwsh deploy/k8s/scripts/oci/deploy-oci.ps1 `
  -RegionKey iad `
  -RegionIdentifier us-ashburn-1 `
  -ClusterOcid ocid1.cluster.oc1.iad.example `
  -Context my-oke-context `
  -OciUsername my.user@company.com `
  -OciAuthToken "<auth-token>" `
  -Email my.user@company.com `
  -Overlay oci-single
```

Frontend-only update:

```powershell
pwsh deploy/k8s/scripts/oci/update-oci-frontend.ps1 `
  -RegionKey iad `
  -OciUsername my.user@company.com `
  -OciAuthToken "<auth-token>" `
  -Email my.user@company.com
```

Backend-only update:

```powershell
pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 `
  -RegionKey iad `
  -OciUsername my.user@company.com `
  -OciAuthToken "<auth-token>" `
  -Email my.user@company.com
```

OCI teardown:

```powershell
pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1
pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1
```

### Full OCI guide

- [docs/oci-oke-free-tier-runbook.md](../../docs/oci-oke-free-tier-runbook.md)

## Routing model

- Frontend traffic: `/`
- API traffic: `/api`, `/auth`, `/users`, `/series`
- Frontend service uses `sessionAffinity: ClientIP` to reduce Blazor Server reconnect issues

