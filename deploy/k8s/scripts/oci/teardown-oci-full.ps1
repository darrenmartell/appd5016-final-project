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
OCI OKE full teardown script.

Usage:
    pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1 [-Namespace seriescatalog] [-Context <name>] [-DeleteIngressNginx]

Examples:
    pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1
    pwsh deploy/k8s/scripts/oci/teardown-oci-full.ps1 -DeleteIngressNginx
"@ | Write-Host
    return
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    $Context = kubectl config current-context
}

if ([string]::IsNullOrWhiteSpace($Context)) {
    throw "No kubectl context set. Set -Context explicitly before running OCI full teardown."
}

Write-Host "OCI full teardown mode"
Write-Host "Using context: $Context"
kubectl config use-context $Context | Out-Null

Write-Host "Deleting application overlays (both OCI variants)"
kubectl delete -k deploy/k8s/overlays/oci-single --ignore-not-found=true
kubectl delete -k deploy/k8s/overlays/oci --ignore-not-found=true

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

Write-Host "OCI full teardown complete."

