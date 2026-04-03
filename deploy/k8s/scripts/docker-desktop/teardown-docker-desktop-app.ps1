[CmdletBinding()]
param(
    [ValidateSet("docker-desktop-single", "docker-desktop")]
    [string]$Overlay = "docker-desktop-single",
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [switch]$DeletePvc,
    [switch]$DeleteNamespace,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
Docker Desktop/local kind teardown script.

Usage:
    pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-app.ps1 [-Overlay docker-desktop-single|docker-desktop] [-Namespace seriescatalog] [-Context <name>] [-DeletePvc] [-DeleteNamespace]

Examples:
    pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-app.ps1
    pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-app.ps1 -Overlay docker-desktop
    pwsh deploy/k8s/scripts/docker-desktop/teardown-docker-desktop-app.ps1 -DeletePvc
"@ | Write-Host
    return
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No Docker Desktop/local kind context found. This teardown script targets Docker Desktop overlays only."
}

Write-Host "Docker Desktop teardown mode"
Write-Host "Using repository root: $repoRoot"
Write-Host "Using context: $Context"
kubectl config use-context $Context | Out-Null

$overlayPath = "deploy/k8s/overlays/$Overlay"
Write-Host "Deleting overlay resources: $overlayPath"
kubectl delete -k $overlayPath --ignore-not-found=true

Write-Host "Deleting optional HPA (if present)"
kubectl delete -f deploy/k8s/optional/hpa.yaml -n $Namespace --ignore-not-found=true

if ($DeletePvc) {
    Write-Host "Deleting PVC seriescatalog-frontend-keys"
    kubectl delete pvc seriescatalog-frontend-keys -n $Namespace --ignore-not-found=true
}

if ($DeleteNamespace) {
    Write-Host "Deleting namespace: $Namespace"
    kubectl delete namespace $Namespace --ignore-not-found=true
}
else {
    Write-Host "Current namespace resources:"
    kubectl get all -n $Namespace
    kubectl get ingress -n $Namespace --ignore-not-found=true
}

Write-Host "Docker Desktop app teardown complete."

