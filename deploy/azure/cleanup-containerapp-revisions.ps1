#requires -Version 7.0

<##
.SYNOPSIS
    Deactivate old inactive Azure Container App revisions

.DESCRIPTION
    Lists and deactivates inactive revisions for one or more Azure Container Apps.
    By default, only inactive revisions are targeted, which is the safe cleanup path.

.PARAMETER ResourceGroup
    Azure resource group name. If omitted, tries to load from azure-config.json.

.PARAMETER ContainerApps
    One or more Container App names to clean up (default: ca-api, ca-frontend).

.PARAMETER Preview
    Preview mode. Shows what would be deactivated without making changes.

.EXAMPLE
    .\deploy\azure\cleanup-containerapp-revisions.ps1

.EXAMPLE
    .\deploy\azure\cleanup-containerapp-revisions.ps1 -ResourceGroup "series-catalog-rg" -Preview

.EXAMPLE
    .\deploy\azure\cleanup-containerapp-revisions.ps1 -ContainerApps "ca-api"
##>

param(
    [string]$ResourceGroup,

    [string[]]$ContainerApps = @("ca-api", "ca-frontend"),

    [switch]$Preview = $false
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

try {
    # Load ResourceGroup from azure-config.json if not passed
    if (-not $ResourceGroup) {
        $configFilePath = $null
        $scriptRepoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        if (Test-Path -Path ".\azure-config.json") {
            $configFilePath = ".\azure-config.json"
        }
        elseif (Test-Path -Path (Join-Path -Path $scriptRepoRoot -ChildPath "azure-config.json")) {
            $configFilePath = Join-Path -Path $scriptRepoRoot -ChildPath "azure-config.json"
        }

        if ($configFilePath) {
            Write-Info "Loading configuration from: $configFilePath"
            $config = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json
            if ($config.resourceGroup) {
                $ResourceGroup = [string]$config.resourceGroup
                Write-Success "ResourceGroup loaded from config: $ResourceGroup"
            }
        }
    }

    if (-not $ResourceGroup) {
        Write-Error-Custom "ResourceGroup is required. Provide -ResourceGroup or ensure azure-config.json contains resourceGroup."
        exit 1
    }

    Write-Section "PRE-FLIGHT CHECKS"

    Write-Info "Checking Azure CLI..."
    $azCliVersion = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azCliVersion) {
        Write-Error-Custom "Azure CLI not found. Install from https://aka.ms/azcli"
        exit 1
    }
    Write-Success "Azure CLI found"

    Write-Info "Checking Azure authentication..."
    $account = az account show 2>$null
    if (-not $account) {
        Write-Error-Custom "Not logged in to Azure. Run 'az login' first"
        exit 1
    }
    Write-Success "Azure authentication confirmed"

    Write-Info "Checking resource group: $ResourceGroup"
    $rg = az group show --name $ResourceGroup 2>$null
    if (-not $rg) {
        Write-Error-Custom "Resource group not found: $ResourceGroup"
        exit 1
    }
    Write-Success "Resource group found"

    Write-Section "REVISION CLEANUP"

    $totalFound = 0
    $totalDeactivated = 0

    foreach ($appName in $ContainerApps) {
        Write-Info "Processing app: $appName"

        $app = az containerapp show --name $appName --resource-group $ResourceGroup 2>$null
        if (-not $app) {
            Write-Warning-Custom "Container app not found, skipping: $appName"
            continue
        }

        $inactiveRevisions = az containerapp revision list `
            --name $appName `
            --resource-group $ResourceGroup `
            --query "[?properties.active==\`false\`].name" `
            --output tsv 2>$null

        if (-not $inactiveRevisions) {
            Write-Success "No inactive revisions to clean up for $appName"
            continue
        }

        $revisionList = @($inactiveRevisions -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $totalFound += $revisionList.Count

        Write-Info "Inactive revisions found for ${appName}: $($revisionList.Count)"
        foreach ($revisionName in $revisionList) {
            if ($Preview) {
                Write-Host "  [PREVIEW] Would deactivate revision: $revisionName" -ForegroundColor Yellow
                continue
            }

            az containerapp revision deactivate `
                --name $appName `
                --resource-group $ResourceGroup `
                --revision $revisionName `
                --output none

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Deactivated revision: $revisionName"
                $totalDeactivated++
            }
            else {
                Write-Warning-Custom "Failed to deactivate revision: $revisionName"
            }
        }
    }

    Write-Section "SUMMARY"
    if ($Preview) {
        Write-Host "Preview complete. Inactive revisions found: $totalFound" -ForegroundColor Cyan
        Write-Host "No changes were made." -ForegroundColor Cyan
    }
    else {
        Write-Host "Inactive revisions found: $totalFound" -ForegroundColor Cyan
        Write-Host "Revisions deactivated:    $totalDeactivated" -ForegroundColor Cyan
    }
}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}