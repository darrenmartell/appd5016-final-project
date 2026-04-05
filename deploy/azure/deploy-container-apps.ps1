#requires -Version 7.0

<#
.SYNOPSIS
    Deploy Series Catalog to Azure Container Apps

.DESCRIPTION
    Deploys API and Frontend containers to Azure Container Apps using Bicep template.
    Handles validation, credential retrieval, and deployment with what-if preview.

.PARAMETER ResourceGroup
    Azure resource group name (where Container Apps will be deployed)
    If not provided, loaded from azure-config.json when available

.PARAMETER AcrName
    Azure Container Registry name (where images are stored)
    If not provided, loaded from azure-config.json when available (ACR mode)

.PARAMETER ApiImage
    Full image reference for API container (external registry mode)
    Example: ghcr.io/owner/series-catalog-api:latest

.PARAMETER FrontendImage
    Full image reference for Frontend container (external registry mode)
    Example: ghcr.io/owner/series-catalog-frontend:latest

.PARAMETER RegistryServer
    Registry server hostname for private external registries
    Example: ghcr.io or index.docker.io

.PARAMETER RegistryUsername
    Registry username for private external registries

.PARAMETER RegistryPassword
    Registry password/token for private external registries

.PARAMETER Location
    Azure region (default: eastus)

.PARAMETER MongoDbConnectionString
    MongoDB connection string for the application
    If not provided, will prompt for it

.PARAMETER MongoDbDatabaseName
    MongoDB database name for the application
    If not provided, attempts appsettings.Development.json, then defaults to series_catalog

.PARAMETER JwtSigningKey
    JWT signing key for API auth tokens
    If not provided, attempts JWT_SIGNING_KEY environment variable, then prompts

.PARAMETER DataProtectionKeyRingPath
    Optional Data Protection key-ring path for frontend cookie protection
    Use a mounted persistent path for production

.PARAMETER SkipValidation
    If true, skips the what-if validation step

.PARAMETER TemplateFile
    Path to the Bicep template file (default: deploy/azure/container-apps.bicep)

.EXAMPLE
    # Interactive deployment
    .\deploy\azure\deploy-container-apps.ps1 -ResourceGroup "my-rg" -AcrName "myacr"

.EXAMPLE
    # Non-interactive with MongoDB connection
    .\deploy\azure\deploy-container-apps.ps1 `
      -ResourceGroup "my-rg" `
      -AcrName "myacr" `
            -MongoDbConnectionString "mongodb+srv://user:pass@host/db" `
            -MongoDbDatabaseName "harlan_coben" `
            -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters"

.EXAMPLE
        # Deploy without ACR using public images
        .\deploy\azure\deploy-container-apps.ps1 `
            -ResourceGroup "my-rg" `
            -ApiImage "ghcr.io/owner/series-catalog-api:latest" `
            -FrontendImage "ghcr.io/owner/series-catalog-frontend:latest" `
            -MongoDbConnectionString "mongodb+srv://user:pass@host/db" `
            -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters"

.EXAMPLE
        # Deploy without ACR using private registry credentials
        .\deploy\azure\deploy-container-apps.ps1 `
            -ResourceGroup "my-rg" `
            -ApiImage "my-registry.example.com/series-catalog-api:latest" `
            -FrontendImage "my-registry.example.com/series-catalog-frontend:latest" `
            -RegistryServer "my-registry.example.com" `
            -RegistryUsername "my-user" `
            -RegistryPassword "my-password-or-token" `
            -MongoDbConnectionString "mongodb+srv://user:pass@host/db" `
            -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters"

.EXAMPLE
    # Deploy with custom template location
    .\deploy\azure\deploy-container-apps.ps1 `
      -ResourceGroup "my-rg" `
      -AcrName "myacr" `
      -TemplateFile "./infra/container-apps.bicep"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$AcrName,

    [string]$ApiImage,

    [string]$FrontendImage,

    [string]$RegistryServer,

    [string]$RegistryUsername,

    [string]$RegistryPassword,

    [string]$Location = "eastus",

    [string]$MongoDbConnectionString,

    [string]$MongoDbDatabaseName,

    [string]$JwtSigningKey,

    [string]$DataProtectionKeyRingPath,

    [switch]$SkipValidation = $false,

    [string]$TemplateFile = "deploy/azure/container-apps.bicep"
)

$ErrorActionPreference = "Stop"

# ========================================================================
# Load Configuration from azure-config.json
# ========================================================================
$configFilePath = $null
$scriptRepoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

if (Test-Path -Path ".\azure-config.json") {
    $configFilePath = ".\azure-config.json"
}
elseif (Test-Path -Path (Join-Path -Path $scriptRepoRoot -ChildPath "azure-config.json")) {
    $configFilePath = Join-Path -Path $scriptRepoRoot -ChildPath "azure-config.json"
}

if ($configFilePath) {
    Write-Host "ℹ Loading configuration from: $configFilePath" -ForegroundColor Cyan
    try {
        $config = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json

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

if (-not $ResourceGroup) {
    Write-Error-Custom "ResourceGroup is required. Provide via -ResourceGroup parameter or ensure azure-config.json exists in the root folder"
    exit 1
}

$useExternalImages = -not [string]::IsNullOrWhiteSpace($ApiImage) -or -not [string]::IsNullOrWhiteSpace($FrontendImage)

if ($useExternalImages) {
    if ([string]::IsNullOrWhiteSpace($ApiImage) -or [string]::IsNullOrWhiteSpace($FrontendImage)) {
        Write-Error-Custom "When using external image mode, both -ApiImage and -FrontendImage are required"
        exit 1
    }
}
elseif (-not $AcrName) {
    Write-Error-Custom "AcrName is required for ACR mode. Provide via -AcrName parameter or ensure azure-config.json exists in the root folder"
    exit 1
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

    # Verify template file exists
    Write-Info "Checking Bicep template..."
    if (-not (Test-Path $TemplateFile)) {
        Write-Error-Custom "Template file not found: $TemplateFile"
        exit 1
    }
    Write-Success "Template file found: $TemplateFile"

    # ========================================================================
    # VALIDATE AZURE RESOURCES
    # ========================================================================
    Write-Section "VALIDATING AZURE RESOURCES"

    # Check resource group
    Write-Info "Checking resource group: $ResourceGroup"
    $rg = az group show --name $ResourceGroup 2>$null
    if (-not $rg) {
        Write-Error-Custom "Resource group not found: $ResourceGroup"
        Write-Info "Create resource group first: az group create --name $ResourceGroup --location $Location"
        exit 1
    }
    Write-Success "Resource group found"

    if ($useExternalImages) {
        Write-Info "Using external image mode"
        Write-Success "API image: $ApiImage"
        Write-Success "Frontend image: $FrontendImage"
    }
    else {
        # Check ACR exists
        Write-Info "Checking Container Registry: $AcrName"
        $acr = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
        if (-not $acr) {
            Write-Error-Custom "ACR not found: $AcrName in $ResourceGroup"
            exit 1
        }
        Write-Success "ACR found"

        # Verify images exist in ACR
        Write-Info "Checking container images..."
        $apiRepo = az acr repository show --name $AcrName --repository "series-catalog-api" 2>$null
        $frontendRepo = az acr repository show --name $AcrName --repository "series-catalog-frontend" 2>$null

        if (-not $apiRepo) {
            Write-Warning-Custom "API image not found in ACR. Run deploy script first."
        }
        else {
            Write-Success "API image found"
        }

        if (-not $frontendRepo) {
            Write-Warning-Custom "Frontend image not found in ACR. Run deploy script first."
        }
        else {
            Write-Success "Frontend image found"
        }
    }

    # ========================================================================
    # GATHER CREDENTIALS
    # ========================================================================
    Write-Section "GATHERING CREDENTIALS"

    $deployApiImage = $ApiImage
    $deployFrontendImage = $FrontendImage
    $useRegistryCredentials = $false
    $deployRegistryServer = ""
    $deployRegistryUsername = ""
    $deployRegistryPassword = ""

    if ($useExternalImages) {
        $hasAnyRegistryCredentialField =
            -not [string]::IsNullOrWhiteSpace($RegistryServer) -or
            -not [string]::IsNullOrWhiteSpace($RegistryUsername) -or
            -not [string]::IsNullOrWhiteSpace($RegistryPassword)

        if ($hasAnyRegistryCredentialField) {
            if ([string]::IsNullOrWhiteSpace($RegistryServer) -or [string]::IsNullOrWhiteSpace($RegistryUsername) -or [string]::IsNullOrWhiteSpace($RegistryPassword)) {
                Write-Error-Custom "For private external registries, provide -RegistryServer, -RegistryUsername, and -RegistryPassword"
                exit 1
            }

            $useRegistryCredentials = $true
            $deployRegistryServer = $RegistryServer
            $deployRegistryUsername = $RegistryUsername
            $deployRegistryPassword = $RegistryPassword
            Write-Success "External registry credentials configured for server: $deployRegistryServer"
        }
        else {
            Write-Info "No external registry credentials provided. Assuming public images."
        }
    }
    else {
        # Get ACR credentials
        Write-Info "Retrieving ACR credentials..."
        $acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroup --query loginServer -o tsv
        $acrUsername = az acr credential show --name $AcrName --resource-group $ResourceGroup --query username -o tsv
        $acrPassword = az acr credential show --name $AcrName --resource-group $ResourceGroup --query 'passwords[0].value' -o tsv

        if (-not $acrLoginServer -or -not $acrUsername -or -not $acrPassword) {
            Write-Error-Custom "Failed to retrieve ACR credentials"
            exit 1
        }
        Write-Success "ACR credentials retrieved"

        $useRegistryCredentials = $true
        $deployRegistryServer = $acrLoginServer
        $deployRegistryUsername = $acrUsername
        $deployRegistryPassword = $acrPassword
        $deployApiImage = "$acrLoginServer/series-catalog-api:latest"
        $deployFrontendImage = "$acrLoginServer/series-catalog-frontend:latest"
    }

    # Get or prompt for MongoDB connection string
    if (-not $MongoDbConnectionString) {
        Write-Info ""
        Write-Host "MongoDB Connection String is required" -ForegroundColor Yellow
        Write-Host "Example: mongodb+srv://user:pass@cluster.mongodb.net/db" -ForegroundColor Gray
        Write-Host ""
        $MongoDbConnectionString = Read-Host "Enter MongoDB connection string (or paste from Key Vault)"

        if (-not $MongoDbConnectionString) {
            Write-Error-Custom "MongoDB connection string is required"
            exit 1
        }
    }
    Write-Success "MongoDB connection string configured"

    # Get MongoDB database name
    if (-not $MongoDbDatabaseName) {
        $devSettingsPath = "src/apps/api-aspnet/appsettings.Development.json"
        if (Test-Path $devSettingsPath) {
            try {
                $devSettings = Get-Content $devSettingsPath -Raw | ConvertFrom-Json
                if ($devSettings.Mongo.DatabaseName) {
                    $MongoDbDatabaseName = [string]$devSettings.Mongo.DatabaseName
                    Write-Info "Using MongoDB database name from appsettings.Development.json: $MongoDbDatabaseName"
                }
            }
            catch {
                Write-Warning-Custom "Unable to read Mongo database name from $devSettingsPath"
            }
        }
    }

    if (-not $MongoDbDatabaseName) {
        $MongoDbDatabaseName = "series_catalog"
        Write-Info "Using default MongoDB database name: $MongoDbDatabaseName"
    }

    Write-Success "MongoDB database name configured: $MongoDbDatabaseName"

    # Get or prompt for JWT signing key
    if (-not $JwtSigningKey) {
        if ($env:JWT_SIGNING_KEY) {
            $JwtSigningKey = $env:JWT_SIGNING_KEY
            Write-Info "Using JWT signing key from JWT_SIGNING_KEY environment variable"
        }
    }

    if (-not $JwtSigningKey) {
        Write-Info ""
        Write-Host "JWT signing key is required for production auth" -ForegroundColor Yellow
        Write-Host "Use a random secret at least 32 characters long" -ForegroundColor Gray
        Write-Host ""
        $JwtSigningKey = Read-Host "Enter JWT signing key"
    }

    if (-not $JwtSigningKey) {
        Write-Error-Custom "JWT signing key is required"
        exit 1
    }

    if ($JwtSigningKey.Length -lt 32) {
        Write-Error-Custom "JWT signing key must be at least 32 characters"
        exit 1
    }

    Write-Success "JWT signing key configured"

    if ($DataProtectionKeyRingPath) {
        Write-Info "Frontend Data Protection key-ring path: $DataProtectionKeyRingPath"
    }

    $deploymentParameters = @(
        "location=$Location",
        "acrLoginServer=$deployRegistryServer",
        "acrUsername=$deployRegistryUsername",
        "acrPassword=$deployRegistryPassword",
        "mongoDbConnectionString=$MongoDbConnectionString",
        "mongoDbDatabaseName=$MongoDbDatabaseName",
        "jwtSigningKey=$JwtSigningKey",
        "apiImage=$deployApiImage",
        "frontendImage=$deployFrontendImage",
        "useRegistryCredentials=$useRegistryCredentials",
        "registryServer=$deployRegistryServer",
        "registryUsername=$deployRegistryUsername",
        "registryPassword=$deployRegistryPassword"
    )

    if ($DataProtectionKeyRingPath) {
        $deploymentParameters += "dataProtectionKeyRingPath=$DataProtectionKeyRingPath"
    }

    # ========================================================================
    # VALIDATE DEPLOYMENT (what-if)
    # ========================================================================
    if (-not $SkipValidation) {
        Write-Section "VALIDATING DEPLOYMENT (what-if)"

        Write-Info "Running what-if to preview changes..."
        Write-Info "This shows what will be created/modified without making changes"
        Write-Info ""

        $whatIfResult = az deployment group what-if `
            --resource-group $ResourceGroup `
            --template-file $TemplateFile `
            --parameters $deploymentParameters `
            2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Validation passed"
            Write-Info ""
            Write-Host $whatIfResult
            Write-Info ""
        }
        else {
            Write-Warning-Custom "Validation encountered issues (may be non-critical)"
            Write-Host $whatIfResult
        }

        # Ask for confirmation
        Write-Info ""
        $confirm = Read-Host "Proceed with deployment? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Warning-Custom "Deployment cancelled by user"
            exit 0
        }
    }

    # ========================================================================
    # DEPLOY
    # ========================================================================
    Write-Section "DEPLOYING TO AZURE CONTAINER APPS"

    Write-Info "Starting deployment (this may take 2-5 minutes)..."
    Write-Info "Deployment Name: container-apps-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Info ""

    $deploymentName = "container-apps-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    $deployment = az deployment group create `
        --resource-group $ResourceGroup `
        --name $deploymentName `
        --template-file $TemplateFile `
        --parameters $deploymentParameters `
        2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Deployment failed"
        Write-Host $deployment
        exit 1
    }

    Write-Success "Deployment completed"

    # ========================================================================
    # DISPLAY OUTPUTS
    # ========================================================================
    Write-Section "DEPLOYMENT OUTPUTS"

    $frontendUrl = $null
    $apiUrl = $null
    $logWorkspaceId = $null

    $deploymentObj = az deployment group show `
        --resource-group $ResourceGroup `
        --name $deploymentName `
        --query properties.outputs `
        --output json 2>$null | ConvertFrom-Json

    if ($deploymentObj.frontendPublicUrl) {
        $frontendUrl = $deploymentObj.frontendPublicUrl.value
        Write-Success "Frontend URL: $frontendUrl"
    }

    if ($deploymentObj.apiInternalFqdn) {
        $apiUrl = $deploymentObj.apiInternalFqdn.value
        Write-Success "API Internal FQDN: $apiUrl"
    }

    if ($deploymentObj.logAnalyticsWorkspaceId) {
        $logWorkspaceId = $deploymentObj.logAnalyticsWorkspaceId.value
        Write-Success "Log Analytics Workspace: $logWorkspaceId"
    }

    # ========================================================================
    # POST-DEPLOYMENT STEPS
    # ========================================================================
    Write-Section "NEXT STEPS"

    Write-Host ""
    Write-Host "1. VERIFY DEPLOYMENT" -ForegroundColor Green
    Write-Host "   Check container status and logs:"
    Write-Host "   az containerapp logs show --name ca-api --resource-group $ResourceGroup --container-name api"
    Write-Host ""

    Write-Host "2. TEST FRONTEND" -ForegroundColor Green
    Write-Host "   Open in browser (wait 1-2 minutes for containers to start):"
    Write-Host "   $frontendUrl"
    Write-Host ""

    Write-Host "3. CHECK HEALTH ENDPOINTS" -ForegroundColor Green
    Write-Host "   curl $frontendUrl"
    Write-Host ""

    Write-Host "4. VIEW LOGS" -ForegroundColor Green
    Write-Host "   Query Log Analytics workspace: "
    Write-Host "   az monitor log-analytics query --workspace $logWorkspaceId --analytics-query 'ContainerAppConsoleLogs_CL | limit 50'"
    Write-Host ""

    Write-Host "5. SCALE APPLICATION" -ForegroundColor Green
    Write-Host "   Adjust replica counts for auto-scaling:"
    Write-Host "   az containerapp update --name ca-api --resource-group $ResourceGroup --min-replicas 2 --max-replicas 5"
    Write-Host ""

    Write-Host "6. MONITOR PERFORMANCE" -ForegroundColor Green
    Write-Host "   View metrics in Azure Portal:"
    Write-Host "   https://portal.azure.com/#resource/subscriptions/$($accountInfo.id)/resourceGroups/$ResourceGroup/overview"
    Write-Host ""

    # ========================================================================
    # SUMMARY
    # ========================================================================
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✓ DEPLOYMENT COMPLETE" -ForegroundColor Green
    Write-Host "════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deployment Details:" -ForegroundColor Cyan
    Write-Host "  Resource Group: $ResourceGroup"
    if ($useExternalImages) {
        Write-Host "  Registry Mode: External"
    }
    else {
        Write-Host "  Container Registry: $AcrName"
    }
    Write-Host "  Location: $Location"
    Write-Host "  Deployment Name: $deploymentName"
    Write-Host ""

    if ($frontendUrl) {
        Write-Host "Application URLs:" -ForegroundColor Cyan
        Write-Host "  Frontend: $frontendUrl"
        Write-Host "  API: https://$apiUrl"
        Write-Host ""
    }

    Write-Host "⏱️  Note: Containers may take 1-2 minutes to start. Check logs if you see loading screens."
    Write-Host ""

}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}
