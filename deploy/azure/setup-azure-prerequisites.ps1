#requires -Version 7.0

<#
.SYNOPSIS
    Setup Azure prerequisites for Series Catalog Container Apps deployment

.DESCRIPTION
    Automates Azure cloud setup including:
    - Azure CLI and Docker validation
    - Azure authentication
    - Resource group creation/verification
    - Optional Container Registry (ACR) creation/verification
    - Local prerequisites verification

.PARAMETER ResourceGroup
    Azure resource group name (default: series-catalog-rg)

.PARAMETER AcrName
    Azure Container Registry name (must be globally unique, alphanumeric only)
    Used only when creating/verifying ACR

.PARAMETER CreateAcr
    If provided, create/verify Azure Container Registry (ACR)
    If omitted, the script skips ACR creation by default

.PARAMETER Location
    Azure region (default: eastus)

.PARAMETER Subscription
    Azure subscription ID or name (optional - uses default if not specified)

.PARAMETER AcrSku
    ACR pricing tier: Basic, Standard, Premium (default: Basic)

.EXAMPLE
    # Interactive setup with defaults
    .\\deploy\\azure\\setup-azure-prerequisites.ps1

.EXAMPLE
        # With specific parameters and ACR creation
    .\\deploy\\azure\\setup-azure-prerequisites.ps1 `
      -ResourceGroup "my-rg" `
            -CreateAcr `
      -AcrName "mycompanyacr" `
      -Location "eastus"

.EXAMPLE
        # With specific subscription (no ACR)
    .\\deploy\\azure\\setup-azure-prerequisites.ps1 `
      -Subscription "prod-subscription" `
            -Location "eastus"

.EXAMPLE
        # With specific subscription and ACR
        .\\deploy\\azure\\setup-azure-prerequisites.ps1 `
            -Subscription "prod-subscription" `
            -CreateAcr `
      -AcrSku "Basic"
#>

param(
    [string]$ResourceGroup = "series-catalog-rg",
    [string]$AcrName,
        [switch]$CreateAcr = $false,
    [string]$Location = "eastus",
    [string]$Subscription,
    [ValidateSet("Basic", "Standard", "Premium")]
    [string]$AcrSku = "Basic"
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
    # STEP 1: Check Local Prerequisites
    # ========================================================================
    Write-Section "CHECKING LOCAL PREREQUISITES"

    # Check Docker
    Write-Info "Checking Docker..."
    $dockerVersion = docker version --format "{{.Client.Version}}" 2>$null
    if (-not $dockerVersion) {
        Write-Warning-Custom "Docker not found"
        Write-Host "   Install from: https://www.docker.com/products/docker-desktop" -ForegroundColor Gray
        Write-Host "   Windows: Use Docker Desktop or https://aka.ms/wsl2" -ForegroundColor Gray
    }
    else {
        Write-Success "Docker found: $dockerVersion"
    }

    # Check Azure CLI
    Write-Info "Checking Azure CLI..."
    $azCliVersion = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azCliVersion) {
        Write-Error-Custom "Azure CLI not found"
        Write-Host "   Install from: https://aka.ms/azcli" -ForegroundColor Gray
        exit 1
    }
    Write-Success "Azure CLI found: $($azCliVersion.'azure-cli')"

    # ========================================================================
    # STEP 2: Azure Authentication
    # ========================================================================
    Write-Section "AZURE AUTHENTICATION"

    Write-Info "Checking Azure login status..."
    $account = az account show 2>$null
    if (-not $account) {
        Write-Info "Not logged in. Opening device code authentication..."
        Write-Host "   (Better support for multi-factor authentication)" -ForegroundColor Gray
        az login --use-device-code | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Azure CLI authentication failed"
            Write-Host "   Try manual login: az login --use-device-code" -ForegroundColor Gray
            exit 1
        }
        Write-Success "Logged in to Azure"
    }
    else {
        $accountObj = $account | ConvertFrom-Json
        Write-Success "Already logged in as: $($accountObj.user.name)"
    }

    # Handle subscription selection
    if ($Subscription) {
        Write-Info "Setting subscription to: $Subscription"
        az account set --subscription $Subscription 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to set subscription: $Subscription"
            Write-Info "Available subscriptions:"
            az account list --output table
            exit 1
        }
        Write-Success "Subscription set"
    }

    # Get current account info
    $currentAccount = az account show --output json | ConvertFrom-Json
    Write-Success "Active Subscription: $($currentAccount.name) (ID: $($currentAccount.id))"

    # ========================================================================
    # STEP 3: Resource Group Setup
    # ========================================================================
    Write-Section "RESOURCE GROUP SETUP"

    Write-Info "Checking resource group: $ResourceGroup"
    $rg = az group show --name $ResourceGroup 2>$null
    
    if (-not $rg) {
        Write-Info "Creating resource group: $ResourceGroup in $Location"
        az group create --name $ResourceGroup --location $Location --output none
        Write-Success "Resource group created"
    }
    else {
        $rgObj = $rg | ConvertFrom-Json
        Write-Success "Resource group exists (Location: $($rgObj.location))"
    }

    # ========================================================================
    # STEP 4: Optional Container Registry Setup
    # ========================================================================
    $shouldConfigureAcr = $CreateAcr -or -not [string]::IsNullOrWhiteSpace($AcrName)
    $acrLoginServer = $null
    $acrUsername = $null

    Write-Section "OPTIONAL CONTAINER REGISTRY SETUP"

    if ($shouldConfigureAcr) {
        if (-not $CreateAcr -and -not [string]::IsNullOrWhiteSpace($AcrName)) {
            Write-Info "AcrName provided. Enabling ACR setup."
        }

        # Generate ACR name if not provided
        if (-not $AcrName) {
            $timestamp = Get-Date -Format "HHmmss"
            $AcrName = "acr$(($ResourceGroup -replace '[^a-zA-Z0-9]', '').ToLower())$timestamp"
            Write-Info "Generated ACR name: $AcrName"
        }

        # Validate ACR name
        $acrNameValid = $AcrName -match '^[a-z0-9]+$' -and $AcrName.Length -ge 5 -and $AcrName.Length -le 50
        if (-not $acrNameValid) {
            Write-Error-Custom "Invalid ACR name: $AcrName"
            Write-Host "   Requirements:" -ForegroundColor Gray
            Write-Host "   - 5-50 characters" -ForegroundColor Gray
            Write-Host "   - Lowercase letters and numbers only" -ForegroundColor Gray
            Write-Host "   - Globally unique" -ForegroundColor Gray
            exit 1
        }

        # Check if ACR exists
        Write-Info "Checking Container Registry: $AcrName"
        $acr = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null

        if (-not $acr) {
            Write-Info "Creating Container Registry: $AcrName (SKU: $AcrSku)"
            az acr create `
                --resource-group $ResourceGroup `
                --name $AcrName `
                --sku $AcrSku `
                --location $Location `
                --admin-enabled true `
                --output none

            if ($LASTEXITCODE -ne 0) {
                Write-Error-Custom "Failed to create ACR (name may not be globally unique)"
                exit 1
            }
            Write-Success "Container Registry created"
        }
        else {
            $acrObj = $acr | ConvertFrom-Json
            Write-Success "Container Registry exists (SKU: $($acrObj.sku.name))"

            # Ensure admin access is enabled
            Write-Info "Ensuring admin access is enabled..."
            az acr update --name $AcrName --admin-enabled true --output none
            Write-Success "Admin access enabled"
        }

        # Get ACR details
        $acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroup --query loginServer -o tsv
        $acrUsername = az acr credential show --name $AcrName --resource-group $ResourceGroup --query username -o tsv

        Write-Success "Container Registry Login Server: $acrLoginServer"
        Write-Success "Container Registry Username: $acrUsername"

        # ========================================================================
        # STEP 5: Verify ACR Access
        # ========================================================================
        Write-Section "VERIFYING ACR ACCESS"

        Write-Info "Testing ACR login..."
        $loginTest = az acr login --name $AcrName 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "ACR login successful"
        }
        else {
            Write-Warning-Custom "ACR login test failed (this may be normal in CI/CD)"
            Write-Info "You can manually test with: az acr login --name $AcrName"
        }
    }
    else {
        Write-Info "Skipping ACR setup (default behavior). Use -CreateAcr to create/configure ACR."
    }

    # ========================================================================
    # STEP 6: Summary and Save Configuration
    # ========================================================================
    Write-Section "CONFIGURATION SUMMARY"

    Write-Host ""
    Write-Host "Azure Setup Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration Details:" -ForegroundColor Cyan
    Write-Host "  Resource Group:    $ResourceGroup"
    Write-Host "  Location:          $Location"
    if ($shouldConfigureAcr) {
        Write-Host "  Container Registry: $AcrName"
        Write-Host "  ACR SKU:           $AcrSku"
        Write-Host "  Login Server:      $acrLoginServer"
    }
    else {
        Write-Host "  Container Registry: (not configured)"
    }
    Write-Host "  Subscription:      $($currentAccount.name)"
    Write-Host ""

    # Save configuration to file
    $configPath = ".\azure-config.json"
    $config = @{
        resourceGroup = $ResourceGroup
        location = $Location
        createAcr = $shouldConfigureAcr
        acrName = $AcrName
        acrLoginServer = $acrLoginServer
        acrUsername = $acrUsername
        acrSku = if ($shouldConfigureAcr) { $AcrSku } else { $null }
        subscription = $currentAccount.name
        subscriptionId = $currentAccount.id
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $config | ConvertTo-Json | Set-Content $configPath
    Write-Success "Configuration saved to: $configPath"

    # ========================================================================
    # STEP 7: Next Steps
    # ========================================================================
    Write-Section "NEXT STEPS"

    Write-Host ""
    if ($shouldConfigureAcr) {
        Write-Host "1. Build and push images to ACR:" -ForegroundColor Yellow
        Write-Host "   .\deploy\azure\deploy-to-acr.ps1 -AcrName $AcrName"
        Write-Host ""
        Write-Host "2. Deploy to Container Apps:" -ForegroundColor Yellow
        Write-Host "   .\deploy\azure\deploy-container-apps.ps1 -ResourceGroup $ResourceGroup -AcrName $AcrName"
        Write-Host ""
        Write-Host "3. Verify Azure setup:" -ForegroundColor Yellow
        Write-Host "   az group show --name $ResourceGroup"
        Write-Host "   az acr show --name $AcrName --resource-group $ResourceGroup"
        Write-Host ""
        Write-Host "4. View ACR repositories:" -ForegroundColor Yellow
        Write-Host "   az acr repository list --name $AcrName --output table"
    }
    else {
        Write-Host "1. Verify Azure setup:" -ForegroundColor Yellow
        Write-Host "   az group show --name $ResourceGroup"
        Write-Host ""
        Write-Host "2. Deploy to Container Apps with external images (no ACR):" -ForegroundColor Yellow
        Write-Host "   .\deploy\azure\deploy-container-apps.ps1 -ResourceGroup $ResourceGroup -ApiImage \"<api-image>\" -FrontendImage \"<frontend-image>\""
        Write-Host ""
        Write-Host "3. Optional: create ACR later if needed:" -ForegroundColor Yellow
        Write-Host "   .\deploy\azure\setup-azure-prerequisites.ps1 -ResourceGroup $ResourceGroup -CreateAcr"
    }
    Write-Host ""

    # Optional: Display the saved configuration
    Write-Info "Saved configuration file contents:"
    Write-Host ""
    Get-Content $configPath | Write-Host
    Write-Host ""

}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}
