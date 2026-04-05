# Blazor Server to Azure Container Apps: Complete Deployment Guide

## Overview

This guide covers deploying your Series Catalog application to Azure Container Apps with two containers: frontend (Blazor Server) and API (ASP.NET Core).

**Key capabilities:**
- 🔒 **Managed HTTPS** - automatic certs
- 🌐 **Service-to-service** - internal networking via FQDN  
- 📊 **Observability** - built-in with Log Analytics
- 🔧 **Auto-scaling** - respond to demand
- 💰 **Cost-effective** - pay only for what you use

---

## 1. Dockerfile Optimization

### API Dockerfile (`deploy/docker/api/Dockerfile`)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files only first (for better layer caching)
COPY src/apps/api-aspnet/SeriesCatalog.WebApi.csproj src/apps/api-aspnet/
COPY src/infrastructure/data-mongodb/SeriesCatalog.Infrastructure.MongoDb.csproj src/infrastructure/data-mongodb/
RUN dotnet restore src/apps/api-aspnet/SeriesCatalog.WebApi.csproj

# Copy source and build
COPY src/apps/api-aspnet/ src/apps/api-aspnet/
COPY src/infrastructure/data-mongodb/ src/infrastructure/data-mongodb/
RUN dotnet publish src/apps/api-aspnet/SeriesCatalog.WebApi.csproj \
    -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage - smaller image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

COPY --from=build /app/publish .

# Container Apps auto-injects these, but being explicit is good
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

ENTRYPOINT ["dotnet", "SeriesCatalog.WebApi.dll"]
```

### Frontend Dockerfile (`deploy/docker/frontend/Dockerfile`)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj src/apps/frontend-blazor/
RUN dotnet restore src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj

COPY src/apps/frontend-blazor/ src/apps/frontend-blazor/
RUN dotnet publish src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj \
    -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

ENTRYPOINT ["dotnet", "SeriesCatalog.Frontend.dll"]
```

### Key Points

- ✅ Both listen on port 8080 (Container Apps default)
- ✅ Multi-stage builds keep images slim
- ✅ Health checks for Container Apps orchestration
- ✅ Production environment configuration

---

## 2. Build & Push to Azure Container Registry

### Option A: Using Azure CLI (Recommended for CI/CD)

Create `deploy-to-acr.ps1`:

```powershell
# Set variables
$resourceGroup = "your-rg"
$acrName = "youracrname"  # Must be globally unique, no dashes
$location = "eastus"

# Create ACR if needed
az acr create --resource-group $resourceGroup `
              --name $acrName `
              --sku Standard `
              --location $location

# Get ACR login server
$acrLoginServer = az acr show --name $acrName --query loginServer -o tsv

# Build and push API
Write-Host "Building and pushing API..."
az acr build --registry $acrName `
             --image "series-catalog-api:latest" `
             --file deploy/docker/api/Dockerfile `
             .

# Build and push Frontend
Write-Host "Building and pushing Frontend..."
az acr build --registry $acrName `
             --image "series-catalog-frontend:latest" `
             --file deploy/docker/frontend/Dockerfile `
             .

# Log ACR URLs
Write-Host "✓ API image: $acrLoginServer/series-catalog-api:latest"
Write-Host "✓ Frontend image: $acrLoginServer/series-catalog-frontend:latest"
```

### Option B: Using Docker Locally (Recommended for Testing)

```powershell
# Build locally
docker build -f deploy/docker/api/Dockerfile -t series-catalog-api:latest .
docker build -f deploy/docker/frontend/Dockerfile -t series-catalog-frontend:latest .

# Get ACR login server
$acrName = "youracrname"
$acrLoginServer = az acr show --name $acrName --query loginServer -o tsv

# Tag for ACR
docker tag series-catalog-api:latest $acrLoginServer/series-catalog-api:latest
docker tag series-catalog-frontend:latest $acrLoginServer/series-catalog-frontend:latest

# Login to ACR
az acr login --name $acrName

# Push to ACR
docker push $acrLoginServer/series-catalog-api:latest
docker push $acrLoginServer/series-catalog-frontend:latest
```

### Why Use Option B (Local Docker Build) for Testing?

**Speed & Feedback Loop**
- ⚡ **Instant feedback**: Local builds run immediately vs. 2-5+ minutes for ACR remote build
- 🔍 **Fail fast**: Catch Dockerfile issues in seconds, not minutes
- 🔄 **Iterate quickly**: Build → test → fix → rebuild in minutes

**Debugging**
- 🛠️ **Full control**: See complete build output and inspect the image immediately
- ▶️ **Run locally**: Test with `docker run` before pushing to ACR
- ✓ **Validate configuration**: Confirm the app runs on port 8080 before production

**Cost Savings**
- 💰 **No ACR compute charges**: ACR builds are billable resources
- 📊 **Dev-friendly**: Don't burn ACR resources during iteration
- 🌐 **Network efficient**: Large layers upload only once, not repeatedly

**Risk Mitigation**
- 🗂️ **Clean registry**: Keep ACR clean—only push tested images
- 🐛 **Catch runtime issues**: Discover platform problems locally before production
- 📤 **Bandwidth efficiency**: Avoid re-uploading artifacts during iteration

### Recommended Workflow

```
Local Testing (Option B) → Validation → Push to ACR → Deploy to Container Apps (Bicep)
```

**Example Development Cycle**:
```powershell
# 1. Build locally and test (Option B)
.\deploy-to-acr.ps1 -AcrName myacr -BuildLocal -SkipPush

# 2. Test the image locally
docker run -p 8080:8080 series-catalog-api:latest
docker run -p 8081:8080 series-catalog-frontend:latest

# 3. Verify endpoints work (health checks, API responses)
curl http://localhost:8080/health

# 4. Once validated, push to ACR
$acrLoginServer = az acr show --name myacr --query loginServer -o tsv
docker tag series-catalog-api:latest $acrLoginServer/series-catalog-api:latest
docker push $acrLoginServer/series-catalog-api:latest
```

### General Best Practices

- Test images locally before pushing to ACR (saves 10-15 minutes per iteration)
- Use specific version tags in production (e.g., `v1.0.0` instead of just `latest`)
- Consider separate ACRs for dev/staging/production
- Enable soft delete on ACR for accidental image recovery
- For CI/CD pipelines, use Option A (ACR remote build) after local validation

---

## 3. Deploy to Azure Container Apps

### Bicep Infrastructure Template (`infra/container-apps.bicep`)

```bicep
param location string = resourceGroup().location
param containerAppsEnvironmentName string = 'cae-series-catalog'
param apiContainerAppName string = 'ca-api'
param frontendContainerAppName string = 'ca-frontend'
param acrLoginServer string
param acrUsername string
@secure()
param acrPassword string

// MongoDB settings (from Key Vault or params)
@secure()
param mongoDbConnectionString string

// Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
      }
    }
  }
}

// Log Analytics Workspace (for observability)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'law-series-catalog'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// API Container App
resource apiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: apiContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: false  // Internal only, frontend calls it
        targetPort: 8080
        transport: 'auto'
      }
      registries: [
        {
          server: acrLoginServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acrPassword
        }
        {
          name: 'mongodb-connection'
          value: mongoDbConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: '${acrLoginServer}/series-catalog-api:latest'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'MongoDb__ConnectionString'
              secretRef: 'mongodb-connection'
            }
            {
              name: 'MongoDb__DatabaseName'
              value: 'series_catalog'
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// Frontend Container App
resource frontendContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: frontendContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true  // Public-facing
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: acrLoginServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acrPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: '${acrLoginServer}/series-catalog-frontend:latest'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'Api__BaseUrl'
              value: 'https://${apiContainerApp.properties.configuration.ingress.fqdn}'
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

output apiInternalFqdn string = apiContainerApp.properties.configuration.ingress.fqdn
output frontendPublicUrl string = 'https://${frontendContainerApp.properties.configuration.ingress.fqdn}'
```

### Automated Deployment Script (Recommended) ⭐

Use the provided PowerShell script at `deploy/deploy-container-apps.ps1` for fully automated deployment with validation:

```powershell
# Option 1: Interactive (prompts for MongoDB connection string)
.\deploy/deploy-container-apps.ps1 `
  -ResourceGroup "my-rg" `
  -AcrName "myacr"

# Option 2: Non-interactive with all parameters
.\deploy/deploy-container-apps.ps1 `
  -ResourceGroup "my-rg" `
  -AcrName "myacr" `
  -MongoDbConnectionString "mongodb+srv://user:pass@host/db"

# Option 3: Skip what-if validation
.\deploy/deploy-container-apps.ps1 `
  -ResourceGroup "my-rg" `
  -AcrName "myacr" `
  -SkipValidation
```

**Script Features:**
- ✅ Pre-flight validation (Azure CLI, authentication, resources)
- ✅ Automatic credential retrieval from ACR
- ✅ What-if deployment preview (shows changes before applying)
- ✅ User confirmation before deployment
- ✅ Extracts and displays deployment outputs (URLs, workspace IDs)
- ✅ Post-deployment guidance (testing, logging, scaling)
- ✅ Complete error handling and colored output

**What the script does:**
1. Validates prerequisites and Azure connectivity
2. Verifies resource group and ACR exist
3. Retrieves ACR credentials automatically
4. Prompts for MongoDB connection string (if not provided)
5. Runs what-if validation and shows preview
6. Waits for user confirmation
7. Deploys Container Apps (2-5 minutes)
8. Displays frontend URL, API FQDN, and Log Analytics workspace ID
9. Provides next steps for verification and monitoring

### Manual Deployment (Alternative)

If you prefer manual control or need to integrate with CI/CD pipelines:

```powershell
$resourceGroup = "your-rg"
$location = "eastus"
$acrName = "youracrname"

# Retrieve ACR credentials
$acrLoginServer = az acr show --name $acrName --query loginServer -o tsv
$acrUsername = az acr credential show --name $acrName --query username -o tsv
$acrPassword = az acr credential show --name $acrName --query 'passwords[0].value' -o tsv
$mongoConnStr = "mongodb://your-user:your-pass@cosmos.mongo.cosmos.azure.com:10255/series_catalog?ssl=true&retryWrites=false&maxIdleTimeMS=120000"

# Validate deployment first (what-if)
az deployment group what-if `
  --resource-group $resourceGroup `
  --template-file deploy/container-apps.bicep `
  --parameters `
    location=$location `
    acrLoginServer=$acrLoginServer `
    acrUsername=$acrUsername `
    acrPassword=$acrPassword `
    mongoDbConnectionString=$mongoConnStr

# Deploy
az deployment group create `
  --resource-group $resourceGroup `
  --template-file deploy/container-apps.bicep `
  --parameters `
    location=$location `
    acrLoginServer=$acrLoginServer `
    acrUsername=$acrUsername `
    acrPassword=$acrPassword `
    mongoDbConnectionString=$mongoConnStr

# Get deployment outputs
az deployment group show `
  --resource-group $resourceGroup `
  --name MicrosoftResources `
  --query properties.outputs `
  --output table
```

### Verifying Deployment

After deployment completes (2-5 minutes for containers to start):

```powershell
# Check container app status
az containerapp show --name ca-api --resource-group $resourceGroup

# View API logs
az containerapp logs show --name ca-api --resource-group $resourceGroup --container-name api --tail 100

# View Frontend logs
az containerapp logs show --name ca-frontend --resource-group $resourceGroup --container-name frontend --tail 100

# Get frontend URL
$frontendUrl = az deployment group show --resource-group $resourceGroup --name MicrosoftResources --query properties.outputs.frontendPublicUrl.value -o tsv
echo "Frontend: $frontendUrl"

# Test health endpoint
curl "$frontendUrl/health"
```

---

## 4. Environment Variables & Configuration

### Environment Variable Naming Convention

**Pattern:** Colon `:` in JSON configuration → Double underscore `__` in environment variables

ASP.NET Core automatically converts hierarchical configuration:

Examples:
- `Api:BaseUrl` → `Api__BaseUrl`
- `MongoDb:ConnectionString` → `MongoDb__ConnectionString`
- `Logging:LogLevel:Default` → `Logging__LogLevel__Default`

---

### Development Configuration

#### Local Development (`src/apps/frontend-blazor/appsettings.Development.json`)

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  },
  "Api": {
    "BaseUrl": "http://localhost:5130"
  },
  "MongoDb": {
    "ConnectionString": "mongodb://localhost:27017",
    "DatabaseName": "series_catalog_dev"
  },
  "AllowedHosts": "*"
}
```

#### Local API Development (`src/apps/api-aspnet/appsettings.Development.json`)

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information",
      "Microsoft.AspNetCore.HttpLogging.HttpLoggingMiddleware": "Debug"
    }
  },
  "MongoDb": {
    "ConnectionString": "mongodb://localhost:27017",
    "DatabaseName": "series_catalog_dev"
  },
  "AllowedHosts": "*"
}
```

**Development-specific settings:**
- ✅ Debug logging for detailed troubleshooting
- ✅ Local MongoDB (container or local instance)
- ✅ HTTP URLs (no HTTPS overhead)
- ✅ Development database names for isolation
- ✅ Separate logging configurations

**Run locally:**
```powershell
# Terminal 1: API
cd src/apps/api-aspnet
dotnet run --configuration Development

# Terminal 2: Frontend
cd src/apps/frontend-blazor
dotnet run --configuration Development

# Access at http://localhost:3000 (frontend default) or http://localhost:5214 (API default)
```

---

### Production Configuration

#### Production Defaults (`src/apps/frontend-blazor/appsettings.json`)

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "Api": {
    "BaseUrl": "https://ca-api.PLACEHOLDER.azurecontainerapps.io"
  },
  "MongoDb": {
    "DatabaseName": "series_catalog_prod"
  },
  "AllowedHosts": "*"
}
```

#### Production API Configuration (`src/apps/api-aspnet/appsettings.json`)

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "MongoDb": {
    "DatabaseName": "series_catalog_prod"
  },
  "AllowedHosts": "*"
}
```

**Production-specific settings:**
- ✅ Minimal logging (Information level only)
- ✅ Production database names
- ✅ Base URLs set via environment variables
- ✅ Encrypted connections (MongoDB Atlas, Cosmos DB)

---

### Container Apps Environment Variables (via Bicep)

Set via the deployment script or Bicep template:

```bicep
// Frontend environment variables
env: [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Production'
  }
  {
    name: 'Api__BaseUrl'
    value: 'https://${apiContainerApp.properties.configuration.ingress.fqdn}'
  }
]

// API environment variables
env: [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Production'
  }
  {
    name: 'MongoDb__ConnectionString'
    secretRef: 'mongodb-connection'
  }
  {
    name: 'MongoDb__DatabaseName'
    value: 'series_catalog_prod'
  }
]
```

**Priority order** (ASP.NET Core configuration):
1. Environment variables (container-level)
2. User Secrets (dev only)
3. appsettings.json
4. appsettings.{Environment}.json

---

### Secrets Management

#### ❌ DON'T Do This (Insecure)
```bicep
// NEVER hardcode secrets in code or Bicep
env: [
  {
    name: 'MongoDb__ConnectionString'
    value: 'mongodb+srv://username:password@cluster.mongodb.net/db'  // ❌ BAD
  }
]
```

#### ✅ DO This (Secure)

**Option 1: Azure Key Vault (Recommended for Production)**

Create and store secrets in Key Vault:

```powershell
# Create Key Vault
az keyvault create --name "kv-series-catalog" --resource-group $resourceGroup --location $location

# Store MongoDB connection string
az keyvault secret set --vault-name "kv-series-catalog" `
  --name "mongodb-connection-string" `
  --value "mongodb+srv://user:pass@cluster.mongodb.net/db"

# Store ACR password
az keyvault secret set --vault-name "kv-series-catalog" `
  --name "acr-password" `
  --value $acrPassword

# Grant Container App access (Managed Identity)
az keyvault set-policy --name "kv-series-catalog" `
  --object-id $containerAppPrincipalId `
  --secret-permissions get
```

Reference in Bicep with Managed Identity:

```bicep
@secure()
param keyVaultName string
@secure()
param mongoDbSecretName string

// Use Key Vault reference in secrets
secrets: [
  {
    name: 'mongodb-connection'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${mongoDbSecretName})'
  }
]
```

**Option 2: Environment Variables via Script**

Use the deployment script to inject secrets from environment:

```powershell
# Store in secure variable before deployment
$mongoDbConnectionString = "mongodb+srv://user:pass@cluster.mongodb.net/db"

# Pass to deployment script
.\deploy/deploy-container-apps.ps1 `
  -ResourceGroup $resourceGroup `
  -AcrName $acrName `
  -MongoDbConnectionString $mongoDbConnectionString
```

The script stores it in Container Apps secrets (encrypted at rest):

```bicep
secrets: [
  {
    name: 'mongodb-connection'
    value: mongoDbConnectionString  // ← Passed as secure parameter
  }
]
```

**Option 3: Local Development Secrets**

Use User Secrets for local development (never commit to git):

```powershell
# Initialize secrets storage for project
cd src/apps/frontend-blazor
dotnet user-secrets init

# Store API URL separately for local testing
dotnet user-secrets set "Api:BaseUrl" "http://localhost:5130"

# API project secrets
cd ../api-aspnet
dotnet user-secrets init
dotnet user-secrets set "MongoDb:ConnectionString" "mongodb://localhost:27017"
dotnet user-secrets set "MongoDb:DatabaseName" "series_catalog_dev"

# List stored secrets (values hidden for security)
dotnet user-secrets list
```

Secrets are stored in: `%APPDATA%\Microsoft\UserSecrets\<project-id>\secrets.json` (Windows)

---

### Development vs Production Comparison

| Setting | Development | Production |
|---------|-------------|-----------|
| **Environment** | `Development` | `Production` |
| **Logging Level** | Debug/Information | Information/Warning |
| **API URL** | `http://localhost:5130` | `https://ca-api.FQDN.azurecontainerapps.io` |
| **MongoDB** | Local/Docker container | Azure Cosmos DB or MongoDB Atlas |
| **Database** | `series_catalog_dev` | `series_catalog_prod` |
| **HTTPS** | Disabled | Enforced |
| **Secrets Storage** | User Secrets | Key Vault or Container App Secrets |
| **Config Source** | appsettings.Development.json | appsettings.json + Env Vars |

---

### Configuration Best Practices

**Security:**
- 🔒 Never commit secrets to git (add to `.gitignore`)
- 🔒 Use Azure Key Vault for production secrets
- 🔒 Use Managed Identity for Key Vault access (no connection strings)
- 🔒 Rotate secrets regularly
- 🔒 Use secure, complex passwords for databases

**Operational:**
- 📝 Document all required environment variables
- 📝 Use consistent naming (double underscores for hierarchy)
- 📝 Separate dev/staging/prod configurations
- 📝 Keep appsettings.json free of secrets
- 📝 Use feature flags for environment-specific behavior

**Troubleshooting:**
```powershell
# View all environment variables in running container
az containerapp exec --name ca-api --resource-group $resourceGroup --command "env"

# Check if secrets are properly referenced
az containerapp secrets show --resource-group $resourceGroup --name ca-api

# View application configuration (no secrets displayed)
az containerapp show --resource-group $resourceGroup --name ca-api --query properties.template.containers[0].env
```

---

## 5. HTTPS & TLS Configuration

### Container Apps Auto-HTTPS

Azure Container Apps provides automatic HTTPS for you:

✅ **Automatically provided:**
- Auto-generated self-signed certificate for `*.azurecontainerapps.io`
- HTTPS endpoint by default
- HTTP automatically redirects to HTTPS
- No additional configuration needed

### Custom Domain (Optional)

To use your own domain, add to Bicep configuration:

```bicep
configuration: {
  ingress: {
    customDomains: [
      {
        name: 'api.yourdomain.com'
        certificateId: '/subscriptions/.../providers/Microsoft.App/managedCertificates/your-cert'
      }
    ]
  }
}
```

### Application-Level HTTPS Configuration

Update your `Program.cs` to enforce HTTPS in production:

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApiApplication(builder.Configuration);
builder.Services.AddMongoPersistence(builder.Configuration);

var app = builder.Build();

// Enforce HTTPS in production only
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseHsts();
app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors(ApiPolicies.CorsPolicyName);
app.UseAuthentication();
app.UseAuthorization();

// ... rest of configuration
```

### Certificate Pinning (Optional for Extra Security)

For highly sensitive applications, implement certificate pinning in your frontend HttpClient configuration.

---

## 6. Wiring Up Backend API

### Frontend Configuration

Update `src/apps/frontend-blazor/appsettings.json`:

```json
{
  "Api": {
    "BaseUrl": "https://ca-api.xyz.eastus.azurecontainerapps.io"
  }
}
```

### Frontend HttpClient Setup (`Program.cs`)

```csharp
var builder = WebApplicationBuilder.CreateBuilder(args);

// Read API base URL from configuration
var apiBaseUrl = builder.Configuration["Api:BaseUrl"] 
                 ?? "http://localhost:5130";

// Register HttpClient with resilience policies
builder.Services.AddHttpClient("SeriesCatalogApi", client =>
{
    client.BaseAddress = new Uri(apiBaseUrl);
    client.DefaultRequestHeaders.Add("User-Agent", "SeriesCatalog-Frontend");
})
.AddTransientHttpErrorPolicy(p => 
    p.WaitAndRetryAsync(3, _ => TimeSpan.FromSeconds(2)))
.AddPolicyHandler(GetRetryPolicy());

var app = builder.Build();
// ... rest of configuration
```

### API CORS Configuration

Update `src/apps/api-aspnet/Program.cs` to allow frontend calls:

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(
            "https://ca-frontend.xyz.eastus.azurecontainerapps.io",  // Production
            "http://localhost:3000",  // Local development
            "http://localhost:3001"   // Alternate local port
        )
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });
});

// ... rest of configuration

var app = builder.Build();

app.UseCors("AllowFrontend");
app.UseExceptionHandler();
app.UseStatusCodePages();
// ... rest of middleware
```

### Service-to-Service Communication

Container Apps provides automatic internal networking:

```csharp
// Frontend can call API by internal FQDN
// Example: https://ca-api.internal.eastus.azurecontainerapps.io
var apiBaseUrl = "https://ca-api.internal.eastus.azurecontainerapps.io";
```

**Benefits of internal FQDN:**
- 🔒 Encrypted internal communication
- 🔐 Bypasses public internet
- ⚡ Lower latency
- 💰 No egress charges

---

## 7. Deployment Checklist

### Pre-Deployment

- [ ] Test Dockerfiles locally
  ```powershell
  docker build -f deploy/docker/api/Dockerfile -t test-api .
  docker build -f deploy/docker/frontend/Dockerfile -t test-frontend .
  ```

- [ ] Verify port configuration (8080)
- [ ] Validate environment variables in `appsettings.json`
- [ ] Confirm MongoDB connection string
- [ ] Create/verify Azure resource group

### Build & Push

```powershell
# 1. Build and push API
az acr build --registry $acrName --image series-catalog-api:latest --file deploy/docker/api/Dockerfile .

# 2. Build and push Frontend
az acr build --registry $acrName --image series-catalog-frontend:latest --file deploy/docker/frontend/Dockerfile .

# 3. Verify images in ACR
az acr repository list --name $acrName.azurecr.io
```

### Deploy Infrastructure

**Recommended: Use the automated deployment script:**

```powershell
.\\deploy/deploy-container-apps.ps1 -ResourceGroup "my-rg" -AcrName "myacr"
```

**Alternative: Manual deployment (for CI/CD integration):**

```powershell
# 1. Validate deployment first
az deployment group what-if --resource-group $rg --template-file deploy/container-apps.bicep `
  --parameters location=$location acrLoginServer=$acrLoginServer acrUsername=$acrUsername `
               acrPassword=$acrPassword mongoDbConnectionString=$mongoConnStr

# 2. Deploy (if validation looks good)
az deployment group create --resource-group $rg --template-file deploy/container-apps.bicep `
  --parameters location=$location acrLoginServer=$acrLoginServer acrUsername=$acrUsername `
               acrPassword=$acrPassword mongoDbConnectionString=$mongoConnStr
```

### Post-Deployment

- [ ] Get deployment outputs
  ```powershell
  $frontendUrl = az deployment group show --name MicrosoftResources --resource-group $rg `
    --query properties.outputs.frontendPublicUrl.value -o tsv
  ```

- [ ] Test application
  ```powershell
  Start-Process $frontendUrl
  ```

- [ ] Verify frontend can reach API
- [ ] Check container logs
  ```powershell
  az containerapp logs show --name ca-api --resource-group $rg --container-name api
  az containerapp logs show --name ca-frontend --resource-group $rg --container-name frontend
  ```

- [ ] Monitor application performance
  ```powershell
  az monitor metrics list --resource /subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.App/containerApps/ca-api
  ```

---

## 8. Monitoring & Troubleshooting

### View Container Logs

```powershell
# API logs
az containerapp logs show --name ca-api --resource-group $rg --container-name api --tail 50

# Frontend logs
az containerapp logs show --name ca-frontend --resource-group $rg --container-name frontend --tail 50
```

### Check Application Health

```powershell
# Get container app details
az containerapp show --name ca-api --resource-group $rg

# Check replica status
az containerapp replica list --name ca-api --resource-group $rg
```

### Common Issues

**Issue:** Frontend cannot reach API
- Solution: Verify CORS policy includes frontend FQDN
- Check: API service BaseUrl configuration
- Test: Call API directly from browser

**Issue:** Application fails to start
- Check: Container logs for startup errors
- Verify: Environment variables are set correctly
- Validate: MongoDB connection string

**Issue:** High CPU/Memory usage
- Check: Application logs for bottlenecks
- Review: Replica scaling configuration
- Monitor: Real-time metrics in Azure Portal

---

## 9. Complete File Structure

After implementing this guide, your project will have the following deployment structure:

```
appd5016-final-project/
├── docs/
│   └── azure-container-apps-deployment.md        ← This guide
├── deploy/                                       ← Deployment artifacts
│   ├── docker/
│   │   ├── api/Dockerfile
│   │   └── frontend/Dockerfile
│   ├── container-apps.bicep                      ← Bicep IaC template
│   ├── deploy-to-acr.ps1                         ← Build & push images
│   ├── deploy-container-apps.ps1                 ← Deploy to Azure ⭐
│   └── k8s/                                      ← (Optional: Kubernetes)
├── src/
│   ├── apps/
│   │   ├── api-aspnet/
│   │   │   ├── Program.cs                        ← UPDATE: Add CORS
│   │   │   ├── appsettings.json                  ← UPDATE: Production config
│   │   │   └── appsettings.Development.json      ← UPDATE: Dev config
│   │   └── frontend-blazor/
│   │       ├── Program.cs                        ← UPDATE: Add HttpClient
│   │       ├── appsettings.json                  ← UPDATE: Production config
│   │       └── appsettings.Development.json      ← UPDATE: Dev config
│   └── infrastructure/
└── appd5016-final-project.sln
```

---

## 10. Quick Start Workflow

### Phase 1: Local Testing
```powershell
# Build images locally to validate Dockerfiles
.\\deploy/deploy-to-acr.ps1 -AcrName myacr -BuildLocal -SkipPush

# Test images locally
docker run -p 8080:8080 series-catalog-api:latest
docker run -p 8081:8080 series-catalog-frontend:latest

# Verify endpoints respond
curl http://localhost:8080/health
curl http://localhost:8081/health
```

### Phase 2: Push to Azure Container Registry
```powershell
# Push validated images to ACR
.\\deploy/deploy-to-acr.ps1 -AcrName myacr

# Verify images in ACR
az acr repository list --name myacr --output table
```

### Phase 3: Deploy to Container Apps
```powershell
# Deploy infrastructure with one command
.\\deploy/deploy-container-apps.ps1 `
  -ResourceGroup "my-rg" `
  -AcrName "myacr" `
  -MongoDbConnectionString "mongodb+srv://..."

# (Script handles: validation, credentials, deployment, outputs)
```

### Phase 4: Verify & Monitor
```powershell
# Check deployment status
az containerapp show --name ca-frontend --resource-group my-rg

# View container logs
az containerapp logs show --name ca-api --resource-group my-rg --container-name api --tail 50

# Get frontend URL (wait 2-5 minutes for startup)
$url = az deployment group show --resource-group my-rg `
  --query properties.outputs.frontendPublicUrl.value -o tsv
Start-Process $url
```

---

## Troubleshooting Quick Reference

| Problem | Cause | Solution |
|---------|-------|----------|
| Dockerfile build fails | Syntax error or missing files | Check Docker logs; verify file paths in COPY commands |
| Port already in use | Another process on 8080 | Use different port locally: `docker run -p 9090:8080 ...` |
| Container won't start | App crash or missing dependency | Check logs: `az containerapp logs show --name ca-api --tail 100` |
| Frontend can't reach API | CORS or URL mismatch | Verify CORS policy; check `Api__BaseUrl` environment variable |
| 503 Service Unavailable | Containers still starting | Wait 2-5 minutes; check replica status |
| Secrets not loading | Bicep reference error | Verify secret names match between definition and `secretRef` |
| High latency | Resource constraints | Check Container Apps CPU/memory; enable auto-scaling |

---

## References

- 📚 [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- 📚 [Bicep Language Reference](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- 📚 [Azure Container Registry Best Practices](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-best-practices)
- 📚 [ASP.NET Core Configuration](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- 📚 [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- 📚 [Azure CLI Container Apps](https://learn.microsoft.com/en-us/cli/azure/containerapp/)
