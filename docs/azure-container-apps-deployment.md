# Azure Container Apps Deployment Guide

## Overview

This repository deploys Series Catalog to Azure Container Apps using:

- API container: internal ingress only (`ca-api`)
- Frontend container: public ingress (`ca-frontend`)
- Shared Container Apps environment (`cae-series-catalog`)
- Log Analytics workspace (`law-series-catalog`)
- VNet + NAT gateway + static public IP for stable outbound connectivity

Deployment assets are in [deploy/azure](deploy/azure):

- `deploy/azure/setup-azure-prerequisites.ps1`
- `deploy/azure/deploy-to-acr.ps1`
- `deploy/azure/deploy-container-apps.ps1`
- `deploy/azure/teardown-container-apps.ps1`
- `deploy/azure/cleanup-containerapp-revisions.ps1`
- `deploy/azure/container-apps.bicep`

---

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Docker installed (required for local builds; optional when using ACR remote build; not required for external-image deploy mode)
- Access to an Azure subscription
- MongoDB connection string (Atlas/Cosmos DB Mongo API/other Mongo provider)
- JWT signing key (32+ characters)

---

## Quick Start (Recommended)

### 1) Provision Azure prerequisites

```powershell
.\deploy\azure\setup-azure-prerequisites.ps1
```

Optional:

```powershell
.\deploy\azure\setup-azure-prerequisites.ps1 `
  -ResourceGroup "my-rg" `
  -CreateAcr `
  -AcrName "myacrname" `
  -Location "eastus" `
  -AcrSku "Basic"
```

What this script does:

- Validates Azure CLI + authentication
- Creates/verifies resource group
- Creates/verifies ACR only when `-CreateAcr` is passed (or when `-AcrName` is explicitly provided)
- Enables ACR admin credentials only when ACR is configured
- Saves settings to `azure-config.json` at repo root

### 2) Build and push images

Use ACR build (default):

```powershell
.\deploy\azure\deploy-to-acr.ps1
```

Use local Docker builds and push:

```powershell
.\deploy\azure\deploy-to-acr.ps1 -BuildLocal
```

Build only (no push):

```powershell
.\deploy\azure\deploy-to-acr.ps1 -BuildLocal -SkipPush
```

### 3) Deploy Container Apps

```powershell
.\deploy\azure\deploy-container-apps.ps1
```

The default mode is ACR-based deployment (uses `AcrName` from parameter or `azure-config.json`).

Pass Mongo explicitly if you do not want prompt-based entry:

```powershell
.\deploy\azure\deploy-container-apps.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -MongoDbDatabaseName "harlan_coben" `
  -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters"
```

Deploy without ACR using public images:

```powershell
.\deploy\azure\deploy-container-apps.ps1 `
  -ResourceGroup "my-rg" `
  -ApiImage "ghcr.io/owner/series-catalog-api:latest" `
  -FrontendImage "ghcr.io/owner/series-catalog-frontend:latest" `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters"
```

Deploy without ACR using a private external registry:

```powershell
.\deploy\azure\deploy-container-apps.ps1 `
  -ResourceGroup "my-rg" `
  -ApiImage "my-registry.example.com/series-catalog-api:latest" `
  -FrontendImage "my-registry.example.com/series-catalog-frontend:latest" `
  -RegistryServer "my-registry.example.com" `
  -RegistryUsername "my-user" `
  -RegistryPassword "my-password-or-token" `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters"
```

Optional Data Protection key-ring path (recommended when you mount persistent storage):

```powershell
.\deploy\azure\deploy-container-apps.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -JwtSigningKey "replace-with-a-long-random-secret-at-least-32-characters" `
  -DataProtectionKeyRingPath "/mnt/dpkeys"
```

The deploy script runs a `what-if` preview by default and asks for confirmation.

---

## Script Behavior Notes

### `deploy/azure/deploy-to-acr.ps1`

- Reads `AcrName`, `ResourceGroup`, and `Location` from `azure-config.json` when not passed.
- Creates ACR if missing.
- Supports:
: `-BuildLocal` for local Docker build
: default remote build in ACR for CI/CD-friendly flow
- Pushes/creates:
: `series-catalog-api:latest`
: `series-catalog-frontend:latest`

### `deploy/azure/deploy-container-apps.ps1`

- Reads `AcrName`, `ResourceGroup`, and `Location` from `azure-config.json` when not passed.
- Default template path is:
: `deploy/azure/container-apps.bicep`
- Supports two deployment modes:
: ACR mode (default): uses `AcrName`, retrieves credentials automatically, deploys `series-catalog-api:latest` and `series-catalog-frontend:latest` from ACR.
: External image mode: provide both `-ApiImage` and `-FrontendImage` to skip ACR entirely.
- Optional external private registry auth:
: provide `-RegistryServer`, `-RegistryUsername`, and `-RegistryPassword` together.
- Requires Mongo connection string (parameter or prompt).
- Uses `MongoDbDatabaseName` from parameter when provided; otherwise tries `src/apps/api-aspnet/appsettings.Development.json`, then defaults to `series_catalog`.
- Requires JWT signing key (parameter, `JWT_SIGNING_KEY` env var, or prompt).
- Supports optional `DataProtectionKeyRingPath` forwarding to frontend container env.
- Runs `az deployment group what-if` unless `-SkipValidation` is provided.

### `deploy/azure/teardown-container-apps.ps1`

- Removes Container Apps resources in a resource group.
- Supports full RG deletion via `-DeleteResourceGroup`.
- Supports non-interactive confirmation bypass with `-Force`.

---

## Infrastructure Template Details

Template: `deploy/azure/container-apps.bicep`

Key parameters:

- `location`
- `acrLoginServer` (optional; primarily for ACR mode)
- `acrUsername` (optional; primarily for ACR mode)
- `acrPassword` (secure; optional; primarily for ACR mode)
- `apiImage`
- `frontendImage`
- `useRegistryCredentials`
- `registryServer`
- `registryUsername`
- `registryPassword` (secure)
- `mongoDbConnectionString` (secure)
- `mongoDbDatabaseName`
- `jwtSigningKey` (secure)
- `dataProtectionKeyRingPath` (optional)

Key outputs:

- `frontendPublicUrl`
- `apiInternalFqdn`
- `logAnalyticsWorkspaceId`
- `staticOutboundIP`
- `natGatewayId`

### Important configuration mapping

The API in this repo binds Mongo settings from section `Mongo`, so environment variable names must be:

- `Mongo__ConnectionString`
- `Mongo__DatabaseName`

The API JWT signing key is injected via:

- `Jwt__Key` (from a Container Apps secret)

These are already set correctly in `deploy/azure/container-apps.bicep`.

---

## Manual Deployment Commands

If you prefer manual deployment instead of the script:

### ACR mode

```powershell
$resourceGroup = "my-rg"
$location = "eastus"
$acrName = "myacrname"

$acrLoginServer = az acr show --name $acrName --resource-group $resourceGroup --query loginServer -o tsv
$acrUsername = az acr credential show --name $acrName --resource-group $resourceGroup --query username -o tsv
$acrPassword = az acr credential show --name $acrName --resource-group $resourceGroup --query 'passwords[0].value' -o tsv
$mongoConnStr = "mongodb+srv://user:pass@cluster.mongodb.net/db"
$mongoDbName = "harlan_coben"
$jwtSigningKey = "replace-with-a-long-random-secret-at-least-32-characters"

az deployment group what-if `
  --resource-group $resourceGroup `
  --template-file deploy/azure/container-apps.bicep `
  --parameters `
    location=$location `
    acrLoginServer=$acrLoginServer `
    acrUsername=$acrUsername `
    acrPassword=$acrPassword `
    mongoDbConnectionString=$mongoConnStr `
    mongoDbDatabaseName=$mongoDbName `
    jwtSigningKey=$jwtSigningKey

az deployment group create `
  --resource-group $resourceGroup `
  --template-file deploy/azure/container-apps.bicep `
  --parameters `
    location=$location `
    acrLoginServer=$acrLoginServer `
    acrUsername=$acrUsername `
    acrPassword=$acrPassword `
    mongoDbConnectionString=$mongoConnStr `
    mongoDbDatabaseName=$mongoDbName `
    jwtSigningKey=$jwtSigningKey
```

### External image mode (no ACR)

```powershell
$resourceGroup = "my-rg"
$location = "eastus"
$mongoConnStr = "mongodb+srv://user:pass@cluster.mongodb.net/db"
$mongoDbName = "harlan_coben"
$jwtSigningKey = "replace-with-a-long-random-secret-at-least-32-characters"
$apiImage = "ghcr.io/owner/series-catalog-api:latest"
$frontendImage = "ghcr.io/owner/series-catalog-frontend:latest"

az deployment group what-if `
  --resource-group $resourceGroup `
  --template-file deploy/azure/container-apps.bicep `
  --parameters `
    location=$location `
    apiImage=$apiImage `
    frontendImage=$frontendImage `
    useRegistryCredentials=false `
    mongoDbConnectionString=$mongoConnStr `
    mongoDbDatabaseName=$mongoDbName `
    jwtSigningKey=$jwtSigningKey

az deployment group create `
  --resource-group $resourceGroup `
  --template-file deploy/azure/container-apps.bicep `
  --parameters `
    location=$location `
    apiImage=$apiImage `
    frontendImage=$frontendImage `
    useRegistryCredentials=false `
    mongoDbConnectionString=$mongoConnStr `
    mongoDbDatabaseName=$mongoDbName `
    jwtSigningKey=$jwtSigningKey
```

  If login immediately fails with 401 after deployment, verify the deployed MongoDB database name matches the database where your users are stored.

---

## Validation and Troubleshooting

### Check deployment outputs

```powershell
$deploymentName = az deployment group list --resource-group $resourceGroup --query "[0].name" -o tsv
az deployment group show --resource-group $resourceGroup --name $deploymentName --query properties.outputs
```

### Check app status and logs

```powershell
az containerapp show --name ca-api --resource-group $resourceGroup
az containerapp show --name ca-frontend --resource-group $resourceGroup

az containerapp logs show --name ca-api --resource-group $resourceGroup --container-name api --tail 100
az containerapp logs show --name ca-frontend --resource-group $resourceGroup --container-name frontend --tail 100
```

### Open frontend URL

```powershell
$deploymentName = az deployment group list --resource-group $resourceGroup --query "[0].name" -o tsv
$frontendUrl = az deployment group show --resource-group $resourceGroup --name $deploymentName --query properties.outputs.frontendPublicUrl.value -o tsv
Start-Process $frontendUrl
```

### Common issues

- ACR not found:
: verify `AcrName` and `ResourceGroup`, then run setup script again (ACR mode only).
- External private registry image pull fails:
: verify `RegistryServer`, `RegistryUsername`, `RegistryPassword`, and image path/tag.
- Mongo connection failures:
: verify the connection string and remote access/network allow-list.
- Frontend cannot call API:
: verify `Api__BaseUrl` in frontend container environment and API container health.
- First request returns transient 502/503:
: wait for revision readiness, then retry.

---

## Teardown

Remove Container Apps resources only:

```powershell
.\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg"
```

Delete entire resource group:

```powershell
.\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg" -DeleteResourceGroup
```

Force mode (skip prompt):

```powershell
.\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg" -DeleteResourceGroup -Force
```

---

## Redeploy Workflows

Use one of the following depending on how much you want to reset.

### 1) Fast redeploy (keep existing infrastructure)

```powershell
# Set JWT key for this session
$env:JWT_SIGNING_KEY = "put-a-long-random-32+-char-key-here"

# Redeploy container apps
.\deploy\azure\deploy-container-apps.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net" `
  -MongoDbDatabaseName "harlan_coben"
```

Fast redeploy updates existing app resources in place. It does not create duplicate `ca-api` or `ca-frontend` apps, but it can leave older inactive revisions.

To keep only the latest active revision for each app:

```powershell
$cfg = Get-Content azure-config.json -Raw | ConvertFrom-Json
$rg = $cfg.resourceGroup

# Review revisions first
az containerapp revision list --name ca-api --resource-group $rg -o table
az containerapp revision list --name ca-frontend --resource-group $rg -o table

# Deactivate all inactive API revisions (safe: keeps active revision)
az containerapp revision list --name ca-api --resource-group $rg --query "[?properties.active==\`false\`].name" -o tsv |
  ForEach-Object { az containerapp revision deactivate --name ca-api --resource-group $rg --revision $_ }

# Deactivate all inactive Frontend revisions (safe: keeps active revision)
az containerapp revision list --name ca-frontend --resource-group $rg --query "[?properties.active==\`false\`].name" -o tsv |
  ForEach-Object { az containerapp revision deactivate --name ca-frontend --resource-group $rg --revision $_ }
```

Equivalent script-based cleanup:

```powershell
# Preview only
.\deploy\azure\cleanup-containerapp-revisions.ps1 -Preview

# Apply cleanup for default apps (ca-api and ca-frontend)
.\deploy\azure\cleanup-containerapp-revisions.ps1

# Apply cleanup for a specific app
.\deploy\azure\cleanup-containerapp-revisions.ps1 -ContainerApps "ca-api"
```

Note: ARM deployment history records are retained by Azure Resource Manager. This cleanup targets Container Apps revision clutter only.

### 2) Clean redeploy (remove app infra, keep resource group)

```powershell
# Remove Container Apps resources only (keeps resource group)
.\deploy\azure\teardown-container-apps.ps1 -ResourceGroup "series-catalog-rg" -Force

# Set JWT key for this session
$env:JWT_SIGNING_KEY = "put-a-long-random-32+-char-key-here"

# Deploy again
.\deploy\azure\deploy-container-apps.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net" `
  -MongoDbDatabaseName "harlan_coben"
```

### 3) Full rebuild from scratch (delete entire resource group)

```powershell
# Delete everything in resource group
.\deploy\azure\teardown-container-apps.ps1 `
  -ResourceGroup "series-catalog-rg" `
  -DeleteResourceGroup `
  -Force

# Recreate Azure prerequisites and ACR
.\deploy\azure\setup-azure-prerequisites.ps1 -ResourceGroup "series-catalog-rg" -CreateAcr

# Rebuild/push images to ACR
.\deploy\azure\deploy-to-acr.ps1

# Set JWT key for this session
$env:JWT_SIGNING_KEY = "put-a-long-random-32+-char-key-here"

# Deploy apps
.\deploy\azure\deploy-container-apps.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net" `
  -MongoDbDatabaseName "harlan_coben"
```

Notes:

- If you run the full rebuild flow, ACR and images are deleted with the resource group. Running `deploy-to-acr.ps1` is required before `deploy-container-apps.ps1`.
- Keep JWT keys out of source control; use environment variables or Key Vault.

---

## Current Azure Deployment File Layout

```text
deploy/
  azure/
    container-apps.bicep
    setup-azure-prerequisites.ps1
    deploy-to-acr.ps1
    deploy-container-apps.ps1
    cleanup-containerapp-revisions.ps1
    teardown-container-apps.ps1
```
