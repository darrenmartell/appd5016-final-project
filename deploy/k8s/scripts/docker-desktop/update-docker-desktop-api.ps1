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
Docker Desktop/local kind backend-only update script.

Usage:
    pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-api.ps1 [-Overlay docker-desktop-single|docker-desktop] [-Namespace seriescatalog] [-Context <name>]

Examples:
    pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-api.ps1
    pwsh deploy/k8s/scripts/docker-desktop/update-docker-desktop-api.ps1 -Overlay docker-desktop
"@ | Write-Host
    return
}

function Assert-DockerBuildReady {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI was not found on PATH. Install Docker Desktop and retry."
    }

    try {
        docker info | Out-Null
    }
    catch {
        throw "Docker daemon is not reachable. Start Docker Desktop and retry."
    }

    try {
        docker buildx version | Out-Null
    }
    catch {
        throw "Docker buildx is not available. Update Docker Desktop and retry."
    }

    try {
        docker buildx inspect --bootstrap | Out-Null
    }
    catch {
        throw @"
No active docker buildx builder is available.
Create and select one, then retry:
  docker buildx create --name seriescatalog-builder --use
  docker buildx inspect --bootstrap
"@
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config get-contexts -o name | Where-Object { $_ -match "docker-desktop|kind" } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No Docker Desktop/local kind context found. Enable Kubernetes in Docker Desktop first."
}

Write-Host "Docker Desktop API update mode"
Write-Host "Using repository root: $repoRoot"
Write-Host "Using context: $Context"
kubectl config use-context $Context | Out-Null

Write-Host "Running Docker preflight checks..."
Assert-DockerBuildReady

Write-Host "Building API image"
docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .

$overlayPath = "deploy/k8s/overlays/$Overlay"
Write-Host "Applying overlay: $overlayPath"
kubectl apply -k $overlayPath

Write-Host "Restarting API deployment"
kubectl rollout restart deployment/seriescatalog-api -n $Namespace
kubectl rollout status deployment/seriescatalog-api -n $Namespace --timeout=180s

Write-Host "Current namespace resources"
kubectl get pods,svc,ingress -n $Namespace

Write-Host "Docker Desktop API update complete."

