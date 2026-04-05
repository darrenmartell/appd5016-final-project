#requires -Version 7.0

<#
.SYNOPSIS
    Deploy Series Catalog to Azure Container Apps

.DESCRIPTION
    Deploys API and Frontend containers to Azure Container Apps using Bicep template.
    Handles validation, credential retrieval, and deployment with what-if preview.

.PARAMETER ResourceGroup
    Azure resource group name (where Container Apps will be deployed)

.PARAMETER AcrName
    Azure Container Registry name (where images are stored)

.PARAMETER Location
    Azure region (default: eastus)

.PARAMETER MongoDbConnectionString
    MongoDB connection string for the application
    If not provided, will prompt for it

.PARAMETER SkipValidation
    If true, skips the what-if validation step

.PARAMETER TemplateFile
    Path to the Bicep template file (default: deploy/container-apps.bicep)

.EXAMPLE
    # Interactive deployment
    .\deploy-container-apps.ps1 -ResourceGroup "my-rg" -AcrName "myacr"

.EXAMPLE
    # Non-interactive with MongoDB connection
    .\deploy-container-apps.ps1 `
      -ResourceGroup "my-rg" `
      -AcrName "myacr" `
      -MongoDbConnectionString "mongodb+srv://user:pass@host/db"

.EXAMPLE
    # Deploy with custom template location
    .\deploy-container-apps.ps1 `
      -ResourceGroup "my-rg" `
      -AcrName "myacr" `
      -TemplateFile "./infra/container-apps.bicep"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$AcrName,

    [string]$Location = "eastus",

    [string]$MongoDbConnectionString,

    [switch]$SkipValidation = $false,

    [string]$TemplateFile = "deploy/container-apps.bicep"
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
    $apiImage = az acr repository show --name $AcrName --repository "series-catalog-api" 2>$null
    $frontendImage = az acr repository show --name $AcrName --repository "series-catalog-frontend" 2>$null

    if (-not $apiImage) {
        Write-Warning-Custom "API image not found in ACR. Run deploy script first."
    }
    else {
        Write-Success "API image found"
    }

    if (-not $frontendImage) {
        Write-Warning-Custom "Frontend image not found in ACR. Run deploy script first."
    }
    else {
        Write-Success "Frontend image found"
    }

    # ========================================================================
    # GATHER CREDENTIALS
    # ========================================================================
    Write-Section "GATHERING CREDENTIALS"

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
            --parameters `
                location=$Location `
                acrLoginServer=$acrLoginServer `
                acrUsername=$acrUsername `
                acrPassword=$acrPassword `
                mongoDbConnectionString=$MongoDbConnectionString `
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
        --parameters `
            location=$Location `
            acrLoginServer=$acrLoginServer `
            acrUsername=$acrUsername `
            acrPassword=$acrPassword `
            mongoDbConnectionString=$MongoDbConnectionString `
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
    Write-Host "   curl $frontendUrl/health"
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
    Write-Host "  Container Registry: $AcrName"
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
