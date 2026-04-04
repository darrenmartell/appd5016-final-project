[CmdletBinding()]
param(
    [ValidateSet("oci-single", "oci")]
    [string]$Overlay = "oci-single",
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [string]$RegionKey,
    [string]$TenancyNamespace,
    [string]$OciUsername,
    [string]$OciAuthToken,
    [string]$Email,
    [string]$Tag = (Get-Date -Format "yyyyMMddHHmmss"),
    [string]$ImagePlatform = "linux/arm64",
    [switch]$MultiArch,
    [switch]$SkipBuild,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
OCI OKE API-only update script.

Usage:
    pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 -RegionKey <key> -OciUsername <user> -OciAuthToken <token> -Email <email> [-TenancyNamespace <ns>] [-Tag <tag>] [-ImagePlatform linux/arm64] [-MultiArch] [-Overlay oci-single|oci] [-Namespace seriescatalog] [-Context <name>] [-SkipBuild]

Examples:
    pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 -RegionKey iad -OciUsername my.user@company.com -OciAuthToken "<token>" -Email my.user@company.com
    pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 -RegionKey iad -OciUsername my.user@company.com -OciAuthToken "<token>" -Email my.user@company.com -Overlay oci -Tag v2
"@ | Write-Host
    return
}

$requiredParams = @{
    RegionKey = $RegionKey
    OciUsername = $OciUsername
    OciAuthToken = $OciAuthToken
    Email = $Email
}

$missing = $requiredParams.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missing.Count -gt 0) {
    throw "Missing required parameters: $($missing -join ', '). Run with -Help for usage examples."
}

function Assert-BuildxReady {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI was not found on PATH. Install Docker Desktop (or Docker Engine) and retry."
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
        throw "Docker buildx is not available in this Docker installation. Update Docker Desktop/CLI and retry."
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

if ([string]::IsNullOrWhiteSpace($TenancyNamespace)) {
    Write-Host "Resolving OCI tenancy namespace..."
    $TenancyNamespace = (oci os ns get --query data --raw-output).Trim()
}

if ([string]::IsNullOrWhiteSpace($TenancyNamespace)) {
    throw "Unable to resolve tenancy namespace. Provide -TenancyNamespace explicitly."
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config current-context
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No kubectl context set. Set -Context explicitly or configure kubectl for OKE first."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Push-Location $repoRoot

try {
    Write-Host "OCI API update mode"
    Write-Host "Using context: $Context"
    kubectl config use-context $Context | Out-Null

    $platforms = if ($MultiArch) { "linux/amd64,linux/arm64" } else { $ImagePlatform }
    Write-Host "Using image platform(s): $platforms"
    $apiImage = "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/api:$Tag"

    if (-not $SkipBuild) {
        Write-Host "Running docker/buildx preflight checks..."
        Assert-BuildxReady

        Write-Host "Logging in to OCIR..."
        $OciAuthToken | docker login "$RegionKey.ocir.io" -u "$TenancyNamespace/$OciUsername" --password-stdin

        Write-Host "Building and pushing API image with buildx..."
        docker buildx build --platform $platforms -f deploy/docker/api/Dockerfile -t $apiImage . --push
    }
    else {
        Write-Host "Skipping API image build/push because -SkipBuild was provided. Ensure image tag already exists in OCIR."
    }

    $overlayFile = "deploy/k8s/overlays/oci/kustomization.yaml"
    $content = Get-Content -Path $overlayFile -Raw

    $content = [regex]::Replace(
        $content,
        '(?ms)(- name: ghcr\.io/darrenmartell/seriescatalog-api\s+newName:\s+)[^\r\n]+',
        ('$1' + "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/api")
    )

    $content = [regex]::Replace(
        $content,
        '(?ms)(- name: ghcr\.io/darrenmartell/seriescatalog-api\s+newName:\s+[^\r\n]+\s+newTag:\s+)[^\r\n]+',
        ('$1' + '"' + $Tag + '"')
    )

    Set-Content -Path $overlayFile -Value $content
    Write-Host "Updated API image reference in $overlayFile"

    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret docker-registry ocir-secret `
        -n $Namespace `
        --docker-server="$RegionKey.ocir.io" `
        --docker-username="$TenancyNamespace/$OciUsername" `
        --docker-password="$OciAuthToken" `
        --docker-email="$Email" `
        --dry-run=client -o yaml | kubectl apply -f -

    $overlayPath = "deploy/k8s/overlays/$Overlay"
    Write-Host "Applying overlay: $overlayPath"
    kubectl apply -k $overlayPath

    Write-Host "Restarting API deployment"
    kubectl rollout restart deployment/seriescatalog-api -n $Namespace
    kubectl rollout status deployment/seriescatalog-api -n $Namespace --timeout=180s

    kubectl get pods,svc,ingress -n $Namespace

    Write-Host "OCI API update complete."
}
finally {
    Pop-Location
}

