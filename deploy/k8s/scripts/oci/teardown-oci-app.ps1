[CmdletBinding()]
param(
    [ValidateSet("oci-single", "oci")]
    [string]$Overlay = "oci-single",
    [string]$Namespace = "seriescatalog",
    [string]$Context,
    [switch]$DeletePvc,
    [switch]$DeleteNamespace,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
OCI OKE app teardown script.

Usage:
    pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1 [-Overlay oci-single|oci] [-Namespace seriescatalog] [-Context <name>] [-DeletePvc] [-DeleteNamespace]

Examples:
    pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1
    pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1 -Overlay oci
    pwsh deploy/k8s/scripts/oci/teardown-oci-app.ps1 -DeletePvc
"@ | Write-Host
    return
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config current-context
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No kubectl context set. Set -Context explicitly before running OCI teardown."
}

Write-Host "OCI app teardown mode"
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
    kubectl get all -n $Namespace --ignore-not-found=true
    kubectl get ingress -n $Namespace --ignore-not-found=true
}

Write-Host "OCI app teardown complete."

