[CmdletBinding()]
param(
    [string]$Namespace = "seriescatalog",
    [string]$Context,
        [switch]$DeleteIngressNginx,
        [Alias("?")]
        [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
        @"
Usage:
    pwsh deploy/k8s/scripts/teardown-full.ps1 [-Namespace seriescatalog] [-Context <name>] [-DeleteIngressNginx]

Examples:
    pwsh deploy/k8s/scripts/teardown-full.ps1
    pwsh deploy/k8s/scripts/teardown-full.ps1 -DeleteIngressNginx
"@ | Write-Host
        return
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No docker-desktop/kind context found. Enable Kubernetes in Docker Desktop first."
}

Write-Host "Using context: $Context"
kubectl config use-context $Context | Out-Null

Write-Host "Deleting application overlays (both variants)"
kubectl delete -k deploy/k8s/overlays/docker-desktop-single --ignore-not-found=true
kubectl delete -k deploy/k8s/overlays/docker-desktop --ignore-not-found=true

Write-Host "Deleting optional HPA (if present)"
kubectl delete -f deploy/k8s/optional/hpa.yaml -n $Namespace --ignore-not-found=true

Write-Host "Deleting namespace: $Namespace"
kubectl delete namespace $Namespace --ignore-not-found=true

if ($DeleteIngressNginx) {
    Write-Host "Deleting ingress-nginx controller"
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml --ignore-not-found=true
}

Write-Host "Remaining namespaces:"
kubectl get ns

Write-Host "Full teardown complete."
