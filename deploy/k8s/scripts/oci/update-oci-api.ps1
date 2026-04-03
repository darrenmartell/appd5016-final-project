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
    pwsh deploy/k8s/scripts/oci/update-oci-api.ps1 -RegionKey <key> -OciUsername <user> -OciAuthToken <token> -Email <email> [-TenancyNamespace <ns>] [-Tag <tag>] [-Overlay oci-single|oci] [-Namespace seriescatalog] [-Context <name>] [-SkipBuild]

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

    if (-not $SkipBuild) {
        Write-Host "Building API image..."
        docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
    }
    else {
        Write-Host "Skipping API build because -SkipBuild was provided."
    }

    $apiImage = "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/api:$Tag"

    Write-Host "Logging in to OCIR..."
    $OciAuthToken | docker login "$RegionKey.ocir.io" -u "$TenancyNamespace/$OciUsername" --password-stdin

    Write-Host "Tagging and pushing API image..."
    docker tag docker-api:latest $apiImage
    docker push $apiImage

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
        ('$1' + $Tag)
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

