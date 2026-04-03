[CmdletBinding()]
param(
    [ValidateSet("docker-desktop-single", "docker-desktop")]
    [string]$Overlay = "docker-desktop-single",
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [switch]$SkipIngressInstall,
    [switch]$SkipBuild,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
Docker Desktop/local kind one-shot bootstrap + deploy script.

Usage:
    pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1 [-Overlay docker-desktop-single|docker-desktop] [-Namespace seriescatalog] [-Context <name>] [-SkipIngressInstall] [-SkipBuild]

Examples:
    pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1
    pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1 -Overlay docker-desktop
    pwsh deploy/k8s/scripts/docker-desktop/deploy-docker-desktop.ps1 -SkipIngressInstall
"@ | Write-Host
    return
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No Docker Desktop/local kind context found. Enable Kubernetes in Docker Desktop first."
}

Write-Host "Docker Desktop deploy mode"
Write-Host "Using context: $Context"
kubectl config use-context $Context | Out-Null

kubectl cluster-info
kubectl get nodes

if (-not $SkipIngressInstall) {
    Write-Host "Installing/updating ingress-nginx controller"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
    kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s
    kubectl get ingressclass
    kubectl get pods -n ingress-nginx
    kubectl get svc -n ingress-nginx
}
else {
    Write-Host "Skipping ingress-nginx install because -SkipIngressInstall was provided."
}

if (-not $SkipBuild) {
    Write-Host "Building local images"
    docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
    docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .
}
else {
    Write-Host "Skipping image builds because -SkipBuild was provided."
}

$overlayPath = "deploy/k8s/overlays/$Overlay"
Write-Host "Applying overlay: $overlayPath"
kubectl apply -k $overlayPath
kubectl rollout status deployment/seriescatalog-api -n $Namespace --timeout=180s
kubectl rollout status deployment/seriescatalog-frontend -n $Namespace --timeout=180s

Write-Host "Current namespace resources"
kubectl get pods,svc,ingress -n $Namespace

