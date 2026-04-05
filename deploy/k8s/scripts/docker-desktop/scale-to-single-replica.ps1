[CmdletBinding()]
param(
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
Docker Desktop scale-down script: converts 2+2 (multi-replica) to 1+1 (single) deployment.

This script removes the docker-desktop overlay and applies the docker-desktop-single overlay,
scaling API and frontend from 2 replicas each to 1 replica each.

Usage:
    pwsh deploy/k8s/scripts/docker-desktop/scale-to-single-replica.ps1 [-Namespace seriescatalog] [-Context <name>]

Examples:
    pwsh deploy/k8s/scripts/docker-desktop/scale-to-single-replica.ps1
    pwsh deploy/k8s/scripts/docker-desktop/scale-to-single-replica.ps1 -Namespace seriescatalog
    pwsh deploy/k8s/scripts/docker-desktop/scale-to-single-replica.ps1 -Context docker-desktop
"@ | Write-Host
    return
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No Docker Desktop/local kind context found. This scale script targets Docker Desktop overlays only."
}

Write-Host "Docker Desktop scale-down: 2+2 → 1+1"
Write-Host "Using repository root: $repoRoot"
Write-Host "Using context: $Context"
Write-Host "Using namespace: $Namespace"
kubectl config use-context $Context | Out-Null

Write-Host "Removing multi-replica overlay (docker-desktop)..."
kubectl delete -k deploy/k8s/overlays/docker-desktop --ignore-not-found=true

Write-Host "Applying single-replica overlay (docker-desktop-single)..."
kubectl apply -k deploy/k8s/overlays/docker-desktop-single

Write-Host "Waiting for deployments to stabilize..."
kubectl rollout status deployment/seriescatalog-api -n $Namespace --timeout=5m
kubectl rollout status deployment/seriescatalog-frontend -n $Namespace --timeout=5m

Write-Host ""
Write-Host "✓ Scale-down complete! Checking replica status..."
kubectl get deployment -n $Namespace | Select-Object NAME, READY, AVAILABLE, REPLICAS
kubectl get pods -n $Namespace -l app=seriescatalog-api,app=seriescatalog-frontend

Write-Host ""
Write-Host "Scale-down successful: API and frontend now running 1 replica each."
