# OCI OKE Free Tier Deployment Runbook

This runbook deploys the SeriesCatalog application to Oracle Cloud Infrastructure (OCI) Kubernetes Engine (OKE) using the OCI overlays in this repository.

- 2+2 replicas overlay: `deploy/k8s/overlays/oci`
- 1+1 replicas overlay: `deploy/k8s/overlays/oci-single`

## 1. Prerequisites

- OCI account and target compartment
- OKE cluster created and Active
- OCI CLI configured (`oci setup config`)
- `kubectl` installed
- Docker installed locally

Reference docs (Oracle):

- OKE cluster access with kubectl: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengaccessingclusterkubectl
- Pushing images to OCIR: https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrypushingimagesusingthedockercli

## 2. Quick Map: What You Must Change

You must update these values before deploy:

1. OCI image registry paths and tag in `deploy/k8s/overlays/oci/kustomization.yaml`
2. Create `ocir-secret` in namespace `seriescatalog`

Overlay file values to replace:

- `replace-tenancy-namespace`
- `replace-with-tag`
- `iad.ocir.io` (if your region is not `iad`)

## 3. Step-by-Step (PowerShell)

Run commands from repository root.

### 3.1 Define variables

```powershell
$RegionKey = "iad"                                  # Example: iad, us-ashburn-1, ca-toronto-1
$RegionIdentifier = "us-ashburn-1"                  # OKE region identifier
$ClusterOcid = "<your-oke-cluster-ocid>"
$TenancyNamespace = (oci os ns get --query data --raw-output).Trim()
$OciUsername = "<your-oci-username>"                # If federated, use OCI documented federated username format
$OciAuthToken = "<your-oci-auth-token>"
$Email = "<your-email>"
$Tag = (Get-Date -Format "yyyyMMddHHmmss")
```

### 3.2 Build local images

```powershell
docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .
```

### 3.3 Log in to OCIR

```powershell
docker login "$RegionKey.ocir.io" -u "$TenancyNamespace/$OciUsername" -p "$OciAuthToken"
```

### 3.4 Tag and push images to OCIR

```powershell
$ApiImage = "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/api:$Tag"
$FrontendImage = "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/frontend:$Tag"

docker tag docker-api:latest $ApiImage
docker tag docker-frontend:latest $FrontendImage

docker push $ApiImage
docker push $FrontendImage
```

### 3.5 Update OCI overlay image references

```powershell
$overlayFile = "deploy/k8s/overlays/oci/kustomization.yaml"
$content = Get-Content -Path $overlayFile -Raw

$content = $content.Replace("iad.ocir.io/replace-tenancy-namespace/seriescatalog/api", "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/api")
$content = $content.Replace("iad.ocir.io/replace-tenancy-namespace/seriescatalog/frontend", "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/frontend")
$content = $content.Replace("replace-with-tag", $Tag)

Set-Content -Path $overlayFile -Value $content
```

### 3.6 Configure kubectl access to OKE

```powershell
oci ce cluster create-kubeconfig `
  --cluster-id $ClusterOcid `
  --file "$HOME/.kube/config" `
  --region $RegionIdentifier `
  --token-version 2.0.0 `
  --kube-endpoint PUBLIC_ENDPOINT

kubectl get nodes
```

### 3.7 Create namespace and OCIR pull secret

```powershell
kubectl create namespace seriescatalog --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry ocir-secret `
  -n seriescatalog `
  --docker-server="$RegionKey.ocir.io" `
  --docker-username="$TenancyNamespace/$OciUsername" `
  --docker-password="$OciAuthToken" `
  --docker-email="$Email" `
  --dry-run=client -o yaml | kubectl apply -f -

kubectl get secret ocir-secret -n seriescatalog
```

Note: OCI overlays already patch both deployments to use `imagePullSecrets: [ocir-secret]`.

### 3.8 Deploy 1+1 first (recommended)

```powershell
kubectl apply -k deploy/k8s/overlays/oci-single
kubectl rollout status deployment/seriescatalog-api -n seriescatalog --timeout=180s
kubectl rollout status deployment/seriescatalog-frontend -n seriescatalog --timeout=180s
```

### 3.9 Scale to 2+2 after verification

```powershell
kubectl apply -k deploy/k8s/overlays/oci
kubectl rollout status deployment/seriescatalog-api -n seriescatalog --timeout=180s
kubectl rollout status deployment/seriescatalog-frontend -n seriescatalog --timeout=180s
```

## 4. One-Run PowerShell Script

Reusable script file:

- `deploy/k8s/scripts/oci/deploy-oci.ps1`
- `deploy/k8s/scripts/oci/update-oci-frontend.ps1`
- `deploy/k8s/scripts/oci/update-oci-api.ps1`
- `deploy/k8s/scripts/oci/teardown-oci-app.ps1`
- `deploy/k8s/scripts/oci/teardown-oci-full.ps1`

Example command line (1+1 deployment):

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

Example command line (2+2 deployment, skip local rebuild):

```powershell
pwsh deploy/k8s/scripts/oci/deploy-oci.ps1 `
  -RegionKey iad `
  -RegionIdentifier us-ashburn-1 `
  -ClusterOcid ocid1.cluster.oc1.iad.example `
  -Context my-oke-context `
  -OciUsername my.user@company.com `
  -OciAuthToken "<auth-token>" `
  -Email my.user@company.com `
  -TenancyNamespace mytenancyns `
  -Tag v1 `
  -Overlay oci `
  -SkipBuild
```

Frontend-only update example:

```powershell
pwsh deploy/k8s/scripts/oci/update-oci-frontend.ps1 `
  -RegionKey iad `
  -OciUsername my.user@company.com `
  -OciAuthToken "<auth-token>" `
  -Email my.user@company.com `
  -Overlay oci-single
```

API-only update example:

```powershell
pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 `
  -RegionKey iad `
  -OciUsername my.user@company.com `
  -OciAuthToken "<auth-token>" `
  -Email my.user@company.com `
  -Overlay oci-single
```

OCI app teardown examples:

```powershell
pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1
pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1 -Overlay oci
pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1 -DeletePvc
```

OCI full teardown examples:

```powershell
pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1
pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1 -DeleteIngressNginx
```

## 5. Ingress Controller and External Access

The OCI overlays set ingress class to `nginx` and include sticky session/timeouts for Blazor Server compatibility.

If ingress-nginx is not installed on your OKE cluster, install it first. Then verify:

```powershell
kubectl get ingressclass
kubectl get ingress -n seriescatalog
```

When external address is provisioned, test:

- `/`
- `/api/health`
- `/auth/login`

## 6. Verification Commands

```powershell
kubectl get pods,svc,ingress -n seriescatalog
kubectl logs -n seriescatalog deployment/seriescatalog-api --since=5m
kubectl logs -n seriescatalog deployment/seriescatalog-frontend --since=5m
```

## 7. Cost Guidance (Free Tier)

- Start with `oci-single` to minimize resource usage
- Keep worker nodes at minimum size/count while testing
- Monitor Billing & Cost Management regularly
- Public load balancer usage can incur cost depending account state and usage

