[CmdletBinding()]
param(
    [ValidateSet("oci-single", "oci")]
    [string]$Overlay = "oci-single",
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [string]$RegionKey,
    [string]$RegionIdentifier,
    [string]$ClusterOcid,
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
Usage:
    pwsh deploy/k8s/scripts/oci/deploy-oci.ps1 -RegionKey <key> -RegionIdentifier <id> -ClusterOcid <ocid> -OciUsername <user> -OciAuthToken <token> -Email <email> [-Context <name>] [-TenancyNamespace <ns>] [-Tag <tag>] [-Overlay oci-single|oci] [-SkipBuild]

Examples:
    pwsh deploy/k8s/scripts/oci/deploy-oci.ps1 -RegionKey iad -RegionIdentifier us-ashburn-1 -ClusterOcid ocid1.cluster.oc1.iad.example -OciUsername my.user@company.com -OciAuthToken "<token>" -Email my.user@company.com -Overlay oci-single

    pwsh deploy/k8s/scripts/oci/deploy-oci.ps1 -RegionKey iad -RegionIdentifier us-ashburn-1 -ClusterOcid ocid1.cluster.oc1.iad.example -OciUsername my.user@company.com -OciAuthToken "<token>" -Email my.user@company.com -TenancyNamespace mytenancyns -Tag v1 -Overlay oci -SkipBuild
"@ | Write-Host
    return
}

$requiredParams = @{
    RegionKey = $RegionKey
    RegionIdentifier = $RegionIdentifier
    ClusterOcid = $ClusterOcid
    OciUsername = $OciUsername
    OciAuthToken = $OciAuthToken
    Email = $Email
}

$missing = $requiredParams.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missing.Count -gt 0) {
    throw "Missing required parameters: $($missing -join ', '). Run with -Help for usage examples."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Push-Location $repoRoot

try {
    Write-Host "OCI deploy mode"

    if ([string]::IsNullOrWhiteSpace($TenancyNamespace)) {
        Write-Host "Resolving OCI tenancy namespace..."
        $TenancyNamespace = (oci os ns get --query data --raw-output).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($TenancyNamespace)) {
        throw "Unable to resolve tenancy namespace. Provide -TenancyNamespace explicitly."
    }

    $apiImage = "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/api:$Tag"
    $frontendImage = "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/frontend:$Tag"

    Write-Host "Using repository root: $repoRoot"
    Write-Host "Using tenancy namespace: $TenancyNamespace"
    Write-Host "Using image tag: $Tag"
    Write-Host "Using overlay: $Overlay"

    if (-not $SkipBuild) {
        Write-Host "Building API image..."
        docker build -f deploy/docker/api/Dockerfile -t docker-api:latest .
        Write-Host "Building frontend image..."
        docker build -f deploy/docker/frontend/Dockerfile -t docker-frontend:latest .
    }
    else {
        Write-Host "Skipping local image builds because -SkipBuild was provided."
    }

    Write-Host "Logging in to OCIR..."
    $OciAuthToken | docker login "$RegionKey.ocir.io" -u "$TenancyNamespace/$OciUsername" --password-stdin

    Write-Host "Tagging and pushing images..."
    docker tag docker-api:latest $apiImage
    docker tag docker-frontend:latest $frontendImage
    docker push $apiImage
    docker push $frontendImage

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

    $content = [regex]::Replace(
        $content,
        '(?ms)(- name: ghcr\.io/darrenmartell/seriescatalog-frontend\s+newName:\s+)[^\r\n]+',
        ('$1' + "$RegionKey.ocir.io/$TenancyNamespace/seriescatalog/frontend")
    )

    $content = [regex]::Replace(
        $content,
        '(?ms)(- name: ghcr\.io/darrenmartell/seriescatalog-frontend\s+newName:\s+[^\r\n]+\s+newTag:\s+)[^\r\n]+',
        ('$1' + $Tag)
    )

    Set-Content -Path $overlayFile -Value $content
    Write-Host "Updated overlay image references in $overlayFile"

    Write-Host "Configuring kubeconfig for OKE cluster..."
    oci ce cluster create-kubeconfig `
        --cluster-id $ClusterOcid `
        --file "$HOME/.kube/config" `
        --region $RegionIdentifier `
        --token-version 2.0.0 `
        --kube-endpoint PUBLIC_ENDPOINT

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = kubectl config current-context
    }

    if ([string]::IsNullOrWhiteSpace($Context)) {
        throw "No kubectl context set after kubeconfig creation. Set -Context explicitly and retry."
    }

    Write-Host "Using context: $Context"
    kubectl config use-context $Context | Out-Null

    kubectl get nodes

    Write-Host "Ensuring namespace and OCIR pull secret exist..."
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

    kubectl create secret docker-registry ocir-secret `
        -n $Namespace `
        --docker-server="$RegionKey.ocir.io" `
        --docker-username="$TenancyNamespace/$OciUsername" `
        --docker-password="$OciAuthToken" `
        --docker-email="$Email" `
        --dry-run=client -o yaml | kubectl apply -f -

    $overlayPath = "deploy/k8s/overlays/$Overlay"
    Write-Host "Deploying overlay: $overlayPath"
    kubectl apply -k $overlayPath

    kubectl rollout status deployment/seriescatalog-api -n $Namespace --timeout=180s
    kubectl rollout status deployment/seriescatalog-frontend -n $Namespace --timeout=180s

    Write-Host "Deployment complete. Current resources:"
    kubectl get pods,svc,ingress -n $Namespace

    Write-Host "OCI deploy complete."
}
finally {
    Pop-Location
}

