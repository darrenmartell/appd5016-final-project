#requires -Version 7.0

<#
.SYNOPSIS
    Deploy Series Catalog Docker images to Azure Container Registry

.DESCRIPTION
    Builds and pushes API and Frontend Docker images to ACR.
    Can build locally or use ACR remote build.

.PARAMETER AcrName
    Azure Container Registry name (must be globally unique, no dashes)

.PARAMETER ResourceGroup
    Azure resource group name

.PARAMETER Location
    Azure region (default: eastus)

.PARAMETER BuildLocal
    If true, builds images locally with Docker. If false, builds in ACR (recommended for CI/CD)

.PARAMETER SkipPush
    If true, only builds images locally without pushing to ACR

.EXAMPLE
    # Build and push using ACR (recommended)
    .\deploy\azure\deploy-to-acr.ps1 -AcrName "yourcompanyacr" -ResourceGroup "my-rg"

.EXAMPLE
    # Build locally and push
    .\deploy\azure\deploy-to-acr.ps1 -AcrName "yourcompanyacr" -ResourceGroup "my-rg" -BuildLocal

.EXAMPLE
    # Only build locally
    .\deploy\azure\deploy-to-acr.ps1 -AcrName "yourcompanyacr" -BuildLocal -SkipPush
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$AcrName,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,

    [string]$Location = "eastus",

    [switch]$BuildLocal = $false,

    [switch]$SkipPush = $false
)

$ErrorActionPreference = "Stop"

# ========================================================================
# Load Configuration from azure-config.json
# ========================================================================
$configFilePath = $null
$scriptRepoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

# Check in current working directory first (where setup script saves it)
if (Test-Path -Path ".\azure-config.json") {
    $configFilePath = ".\azure-config.json"
}
# Check in parent directory of script
elseif (Test-Path -Path (Join-Path -Path $scriptRepoRoot -ChildPath "azure-config.json")) {
    $configFilePath = Join-Path -Path $scriptRepoRoot -ChildPath "azure-config.json"
}

if ($configFilePath) {
    Write-Host "ℹ Loading configuration from: $configFilePath" -ForegroundColor Cyan
    try {
        $config = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json
        
        # Apply config values only if parameters weren't provided
        if (-not $AcrName -and $config.acrName) {
            $AcrName = $config.acrName
            Write-Host "  ✓ Loaded AcrName from config: $AcrName" -ForegroundColor Gray
        }
        
        if (-not $ResourceGroup -and $config.resourceGroup) {
            $ResourceGroup = $config.resourceGroup
            Write-Host "  ✓ Loaded ResourceGroup from config: $ResourceGroup" -ForegroundColor Gray
        }
        
        if ($Location -eq "eastus" -and $config.location) {
            $Location = $config.location
            Write-Host "  ✓ Loaded Location from config: $Location" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "Failed to parse azure-config.json: $_"
    }
}

# Validate required parameters after loading config
if (-not $AcrName) {
    Write-Error-Custom "AcrName is required. Provide via -AcrName parameter or ensure azure-config.json exists in the root folder"
    exit 1
}

if (-not $ResourceGroup) {
    Write-Error-Custom "ResourceGroup is required. Provide via -ResourceGroup parameter or ensure azure-config.json exists in the root folder"
    exit 1
}

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

try {
    # ========================================================================
    # Validation
    # ========================================================================
    Write-Info "Validating prerequisites..."

    # Check if Azure CLI is installed
    $azCliVersion = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azCliVersion) {
        Write-Error-Custom "Azure CLI not found. Please install from https://aka.ms/azcli"
        exit 1
    }
    Write-Success "Azure CLI found"

    # Check if Docker is installed only when building locally.
    if ($BuildLocal) {
        $dockerVersion = docker version --format "{{.Client.Version}}" 2>$null
        if (-not $dockerVersion) {
            Write-Warning-Custom "Docker not found. Install from https://www.docker.com or use ACR builds"
            if ($BuildLocal) {
                exit 1
            }
        }
        else {
            Write-Success "Docker found: $dockerVersion"
        }
    }

    # Check Azure CLI authentication
    $account = az account show 2>$null
    if (-not $account) {
        Write-Error-Custom "Not logged in to Azure. Run 'az login' first"
        exit 1
    }
    Write-Success "Logged in to Azure"

    # ========================================================================
    # Azure Setup
    # ========================================================================
    Write-Info "Setting up Azure resources..."

    # Check if resource group exists
    $rg = az group show --name $ResourceGroup 2>$null
    if (-not $rg) {
        Write-Info "Creating resource group: $ResourceGroup"
        az group create --name $ResourceGroup --location $Location | Out-Null
        Write-Success "Resource group created"
    }
    else {
        Write-Success "Resource group found: $ResourceGroup"
    }

    # Check if ACR exists
    $acr = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
    if (-not $acr) {
        Write-Info "Creating Azure Container Registry: $AcrName"
        az acr create `
            --resource-group $ResourceGroup `
            --name $AcrName `
            --sku Basic `
            --admin-enabled true `
            --location $Location | Out-Null
        Write-Success "ACR created"
    }
    else {
        Write-Success "ACR found: $AcrName"
        
        # Ensure admin access is enabled for credential retrieval
        Write-Info "Ensuring admin access is enabled..."
        az acr update --name $AcrName --admin-enabled true --output none 2>$null
        Write-Success "Admin access enabled"
    }

    # Get ACR details
    $acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroup --query loginServer -o tsv
    $acrUsername = az acr credential show --name $AcrName --resource-group $ResourceGroup --query username -o tsv
    $acrPassword = az acr credential show --name $AcrName --resource-group $ResourceGroup --query 'passwords[0].value' -o tsv

    Write-Success "ACR Login Server: $acrLoginServer"

    # ========================================================================
    # Build & Push Images
    # ========================================================================
    Write-Info "Building and pushing images..."

    if ($BuildLocal) {
        # ====================================================================
        # LOCAL BUILD METHOD
        # ====================================================================
        Write-Info "Building images locally with Docker..."

        # Build API image
        Write-Info "Building API image..."
        docker build `
            -f deploy/docker/api/Dockerfile `
            -t series-catalog-api:latest `
            -t "$acrLoginServer/series-catalog-api:latest" `
            . | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to build API image"
            exit 1
        }
        Write-Success "API image built"

        # Build Frontend image
        Write-Info "Building Frontend image..."
        docker build `
            -f deploy/docker/frontend/Dockerfile `
            -t series-catalog-frontend:latest `
            -t "$acrLoginServer/series-catalog-frontend:latest" `
            . | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to build Frontend image"
            exit 1
        }
        Write-Success "Frontend image built"

        # Push to ACR
        if (-not $SkipPush) {
            Write-Info "Logging into ACR..."
            az acr login --name $AcrName | Out-Null
            Write-Success "Logged into ACR"

            Write-Info "Pushing API image to ACR..."
            docker push "$acrLoginServer/series-catalog-api:latest" | Out-Null

            if ($LASTEXITCODE -ne 0) {
                Write-Error-Custom "Failed to push API image"
                exit 1
            }
            Write-Success "API image pushed"

            Write-Info "Pushing Frontend image to ACR..."
            docker push "$acrLoginServer/series-catalog-frontend:latest" | Out-Null

            if ($LASTEXITCODE -ne 0) {
                Write-Error-Custom "Failed to push Frontend image"
                exit 1
            }
            Write-Success "Frontend image pushed"
        }
    }
    else {
        # ====================================================================
        # ACR BUILD METHOD (Recommended for CI/CD)
        # ====================================================================
        Write-Info "Building images in ACR (recommended for CI/CD)..."

        # Build API image
        Write-Info "Building API image in ACR..."
        az acr build `
            --registry $AcrName `
            --image "series-catalog-api:latest" `
            --file deploy/docker/api/Dockerfile `
            . | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to build API image in ACR"
            exit 1
        }
        Write-Success "API image built in ACR"

        # Build Frontend image
        Write-Info "Building Frontend image in ACR..."
        az acr build `
            --registry $AcrName `
            --image "series-catalog-frontend:latest" `
            --file deploy/docker/frontend/Dockerfile `
            . | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to build Frontend image in ACR"
            exit 1
        }
        Write-Success "Frontend image built in ACR"
    }

    # ========================================================================
    # Summary
    # ========================================================================
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "✓ Deployment Complete" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Container Registry: $acrName" -ForegroundColor Cyan
    Write-Host "Login Server: $acrLoginServer" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Images:" -ForegroundColor Cyan
    Write-Host "  API:      $acrLoginServer/series-catalog-api:latest"
    Write-Host "  Frontend: $acrLoginServer/series-catalog-frontend:latest"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Update deploy/azure/container-apps.bicep with ACR credentials"
    Write-Host "  2. Deploy with: az deployment group create --resource-group $ResourceGroup --template-file deploy/azure/container-apps.bicep"
    Write-Host "  3. Configure environment variables in the Bicep template"
    Write-Host ""
    Write-Host "Authentication for scripting:" -ForegroundColor Yellow
    Write-Host "  Username: $acrUsername"
    Write-Host "  Password: (stored in ACR, not shown for security)"
    Write-Host ""

    # Optional: List repositories
    Write-Info "ACR Repositories:"
    az acr repository list --name $AcrName --output table

}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}
