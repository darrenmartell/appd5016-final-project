[CmdletBinding()]
param(
    [ValidateSet("docker-desktop-single", "docker-desktop")]
    [string]$Overlay = "docker-desktop-single",
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
Docker Desktop/local kind frontend-only update script.

Usage:
    pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-frontend.ps1 [-Overlay docker-desktop-single|docker-desktop] [-Namespace seriescatalog] [-Context <name>]

Examples:
    pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-frontend.ps1
    pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-frontend.ps1 -Overlay docker-desktop
"@ | Write-Host
    return
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No Docker Desktop/local kind context found. Enable Kubernetes in Docker Desktop first."
}

Write-Host "Docker Desktop frontend update mode"
Write-Host "Using repository root: $repoRoot"
Write-Host "Using context: $Context"
kubectl config use-context $Context | Out-Null

Write-Host "Building frontend image"
docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .

$overlayPath = "deploy/k8s/overlays/$Overlay"
Write-Host "Applying overlay: $overlayPath"
kubectl apply -k $overlayPath

Write-Host "Restarting frontend deployment"
kubectl rollout restart deployment/seriescatalog-frontend -n $Namespace
kubectl rollout status deployment/seriescatalog-frontend -n $Namespace --timeout=180s

Write-Host "Current namespace resources"
kubectl get pods,svc,ingress -n $Namespace

Write-Host "Docker Desktop frontend update complete."

