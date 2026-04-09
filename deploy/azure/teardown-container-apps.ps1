#requires -Version 7.0

<#
.SYNOPSIS
    Teardown Azure Container Apps deployment

.DESCRIPTION
    Removes Container Apps, Container Apps Environment, and related resources.
    Can delete individual resources or the entire resource group.

.PARAMETER ResourceGroup
    Azure resource group name containing the resources

.PARAMETER DeleteResourceGroup
    If true, deletes the entire resource group (all resources including storage, databases, etc.)
    If false, only deletes Container Apps related resources

.PARAMETER Force
    If true, skips confirmation prompt and immediately deletes resources

.EXAMPLE
    # Remove only Container Apps resources (keeps resource group and other resources)
    .\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg"

.EXAMPLE
    # Remove entire resource group
    .\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg" -DeleteResourceGroup

.EXAMPLE
    # Skip confirmation
    .\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg" -Force
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [switch]$DeleteResourceGroup = $false,

    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Color output helpers
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
}

try {
    # ========================================================================
    # PRE-FLIGHT CHECKS
    # ========================================================================
    Write-Section "PRE-FLIGHT CHECKS"

    # Check Azure CLI
    Write-Info "Checking Azure CLI..."
    $azCliVersion = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azCliVersion) {
        Write-Error-Custom "Azure CLI not found. Install from https://aka.ms/azcli"
        exit 1
    }
    Write-Success "Azure CLI found"

    # Check authentication
    Write-Info "Checking Azure authentication..."
    $account = az account show 2>$null
    if (-not $account) {
        Write-Error-Custom "Not logged in to Azure. Run 'az login' first"
        exit 1
    }
    $accountInfo = $account | ConvertFrom-Json
    Write-Success "Logged in as: $($accountInfo.user.name)"

    # ========================================================================
    # VALIDATE RESOURCE GROUP
    # ========================================================================
    Write-Section "VALIDATING RESOURCE GROUP"

    Write-Info "Checking resource group: $ResourceGroup"
    $rg = az group show --name $ResourceGroup 2>$null
    if (-not $rg) {
        Write-Error-Custom "Resource group not found: $ResourceGroup"
        exit 1
    }
    Write-Success "Resource group found"

    # ========================================================================
    # SHOW RESOURCES TO BE DELETED
    # ========================================================================
    Write-Section "RESOURCES TO BE DELETED"

    Write-Info "Container Apps related resources:"
    
    # Check for Container Apps
    $containerApps = az containerapp list --resource-group $ResourceGroup --query "[].name" -o json 2>$null | ConvertFrom-Json
    if ($containerApps) {
        $containerApps | ForEach-Object { Write-Host "  • Container App: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  (None found)" -ForegroundColor Gray
    }

    # Check for Container Apps Environment
    $environments = az containerapp env list --resource-group $ResourceGroup --query "[].name" -o json 2>$null | ConvertFrom-Json
    if ($environments) {
        $environments | ForEach-Object { Write-Host "  • Container App Env: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  (None found)" -ForegroundColor Gray
    }

    # Check for Virtual Networks
    $vnets = az network vnet list --resource-group $ResourceGroup --query "[].name" -o json 2>$null | ConvertFrom-Json
    if ($vnets) {
        $vnets | ForEach-Object { Write-Host "  • Virtual Network: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  (None found)" -ForegroundColor Gray
    }

    # Check for NAT Gateways
    $natGateways = az network nat gateway list --resource-group $ResourceGroup --query "[].name" -o json 2>$null | ConvertFrom-Json
    if ($natGateways) {
        $natGateways | ForEach-Object { Write-Host "  • NAT Gateway: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  (None found)" -ForegroundColor Gray
    }

    # Check for Public IPs
    $publicIps = az network public-ip list --resource-group $ResourceGroup --query "[].name" -o json 2>$null | ConvertFrom-Json
    if ($publicIps) {
        $publicIps | ForEach-Object { Write-Host "  • Public IP: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  (None found)" -ForegroundColor Gray
    }

    # Check for Log Analytics Workspaces
    $lawWorkspaces = az monitor log-analytics workspace list --resource-group $ResourceGroup --query "[].name" -o json 2>$null | ConvertFrom-Json
    if ($lawWorkspaces) {
        $lawWorkspaces | ForEach-Object { Write-Host "  • Log Analytics Workspace: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  (None found)" -ForegroundColor Gray
    }

    Write-Info ""
    
    if ($DeleteResourceGroup) {
        Write-Warning-Custom "ENTIRE RESOURCE GROUP WILL BE DELETED: $ResourceGroup"
        Write-Host "  This includes ALL resources in the resource group (storage, databases, etc.)" -ForegroundColor Yellow
        Write-Host ""
    }

    # ========================================================================
    # CONFIRMATION
    # ========================================================================
    if (-not $Force) {
        Write-Section "CONFIRMATION REQUIRED"
        
        if ($DeleteResourceGroup) {
            Write-Warning-Custom "This will DELETE THE ENTIRE RESOURCE GROUP and all its resources!"
            Write-Host "Type 'DELETE-RG-$ResourceGroup' to confirm: " -ForegroundColor Red -NoNewline
        }
        else {
            Write-Warning-Custom "This will delete Container Apps and related networking resources"
            Write-Host "Type 'DELETE' to confirm: " -ForegroundColor Yellow -NoNewline
        }

        $confirmation = Read-Host

        if ($DeleteResourceGroup) {
            if ($confirmation -ne "DELETE-RG-$ResourceGroup") {
                Write-Warning-Custom "Confirmation mismatch. Teardown cancelled."
                exit 0
            }
        }
        else {
            if ($confirmation -ne "DELETE") {
                Write-Warning-Custom "Confirmation not provided. Teardown cancelled."
                exit 0
            }
        }
    }

    # ========================================================================
    # TEARDOWN
    # ========================================================================
    Write-Section "TEARING DOWN RESOURCES"

    if ($DeleteResourceGroup) {
        Write-Info "Deleting resource group: $ResourceGroup"
        Write-Info "This may take several minutes..."
        
        az group delete --name $ResourceGroup --yes --no-wait
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Resource group deletion initiated (running in background)"
            Write-Info "To check status: az group show --name $ResourceGroup"
        }
        else {
            Write-Error-Custom "Failed to initiate resource group deletion"
            exit 1
        }
    }
    else {
        # Delete only Container Apps resources
        
        # Delete Container Apps
        if ($containerApps) {
            Write-Info "Deleting Container Apps..."
            $containerApps | ForEach-Object {
                Write-Info "  Removing: $_"
                az containerapp delete --name $_ --resource-group $ResourceGroup --yes 2>$null
            }
            Write-Success "Container Apps deleted"
        }

        # Delete Container Apps Environment
        if ($environments) {
            Write-Info "Deleting Container App Environments..."
            $environments | ForEach-Object {
                Write-Info "  Removing: $_"
                az containerapp env delete --name $_ --resource-group $ResourceGroup --yes 2>$null
            }
            Write-Success "Container App Environments deleted"
        }

        # Delete Virtual Networks
        if ($vnets) {
            Write-Info "Deleting Virtual Networks..."
            $vnets | ForEach-Object {
                Write-Info "  Removing: $_"
                az network vnet delete --name $_ --resource-group $ResourceGroup --yes 2>$null
            }
            Write-Success "Virtual Networks deleted"
        }

        # Delete NAT Gateways
        if ($natGateways) {
            Write-Info "Deleting NAT Gateways..."
            $natGateways | ForEach-Object {
                Write-Info "  Removing: $_"
                az network nat gateway delete --name $_ --resource-group $ResourceGroup --yes 2>$null
            }
            Write-Success "NAT Gateways deleted"
        }

        # Delete Public IPs
        if ($publicIps) {
            Write-Info "Deleting Public IPs..."
            $publicIps | ForEach-Object {
                Write-Info "  Removing: $_"
                az network public-ip delete --name $_ --resource-group $ResourceGroup --yes 2>$null
            }
            Write-Success "Public IPs deleted"
        }

        # Delete Log Analytics Workspaces
        if ($lawWorkspaces) {
            Write-Info "Deleting Log Analytics Workspaces..."
            $lawWorkspaces | ForEach-Object {
                Write-Info "  Removing: $_"
                az monitor log-analytics workspace delete --name $_ --resource-group $ResourceGroup --yes --force 2>$null
            }
            Write-Success "Log Analytics Workspaces deleted"
        }
    }

    # ========================================================================
    # SUMMARY
    # ========================================================================
    Write-Section "TEARDOWN COMPLETE"

    if ($DeleteResourceGroup) {
        Write-Host "Resource group '$ResourceGroup' deletion initiated" -ForegroundColor Green
        Write-Host ""
        Write-Host "Status command:" -ForegroundColor Cyan
        Write-Host "  az group show --name $ResourceGroup" -ForegroundColor Gray
        Write-Host ""
        Write-Host "It may take several minutes for the deletion to complete." -ForegroundColor Yellow
    }
    else {
        Write-Host "Container Apps resources have been removed" -ForegroundColor Green
        Write-Host ""
        Write-Host "Resource group '$ResourceGroup' still exists" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To delete the entire resource group later:" -ForegroundColor Yellow
        Write-Host "  .\deploy\azure\teardown-container-apps.ps1 -ResourceGroup $ResourceGroup -DeleteResourceGroup" -ForegroundColor Gray
    }

}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}
