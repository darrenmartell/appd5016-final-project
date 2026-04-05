// Azure Container Apps Deployment for Series Catalog Application
// Deploys API and Frontend with shared environment, logging, and networking

param location string = resourceGroup().location
param containerAppsEnvironmentName string = 'cae-series-catalog'
param apiContainerAppName string = 'ca-api'
param frontendContainerAppName string = 'ca-frontend'
param acrLoginServer string = ''
param acrUsername string = ''

@secure()
param acrPassword string = ''

// Container image references. Defaults target ACR-based flow.
param apiImage string = '${acrLoginServer}/series-catalog-api:latest'
param frontendImage string = '${acrLoginServer}/series-catalog-frontend:latest'

// Registry authentication settings.
param useRegistryCredentials bool = true
param registryServer string = acrLoginServer
param registryUsername string = acrUsername

@secure()
param registryPassword string = acrPassword

// MongoDB settings - Use Azure Cosmos DB or MongoDB Atlas connection string
@secure()
param mongoDbConnectionString string

// MongoDB database name
param mongoDbDatabaseName string = 'series_catalog'

// JWT signing key for API token issuance/validation
@secure()
param jwtSigningKey string

// Optional Data Protection key-ring path inside the frontend container.
// Set this to a mounted persistent path to keep auth cookies valid across restarts.
param dataProtectionKeyRingPath string = ''

// ============================================================================
// Log Analytics Workspace - For Application Insights and Container App logs
// ============================================================================
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

// ============================================================================
// Static IP for Outbound Connections - For MongoDB whitelisting
// ============================================================================
resource staticIpPublic 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-series-catalog'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: 'nat-series-catalog'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: staticIpPublic.id
      }
    ]
  }
}

// ============================================================================
// Virtual Network - Required for NAT Gateway integration
// ============================================================================
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-series-catalog'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-container-apps'
        properties: {
          addressPrefix: '10.0.0.0/23'
          natGateway: {
            id: natGateway.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

// ============================================================================
// Container Apps Environment - Shared infrastructure for both containers
// ============================================================================
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: '${virtualNetwork.id}/subnets/subnet-container-apps'
    }
  }
}

// ============================================================================
// API Container App - Internal service, not publicly exposed
// ============================================================================
resource apiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: apiContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    
    configuration: {
      // Ingress configuration - Internal only
      ingress: {
        external: false // Not publicly accessible
        targetPort: 8080
        transport: 'auto' // Handles HTTP/HTTPS automatically
      }
      
      // Container registry credentials
      registries: useRegistryCredentials ? [
        {
          server: registryServer
          username: registryUsername
          passwordSecretRef: 'registry-password'
        }
      ] : []
      
      // Secrets - Referenced by environment variables
      secrets: concat([
        {
          name: 'mongodb-connection'
          value: mongoDbConnectionString
        }
        {
          name: 'jwt-signing-key'
          value: jwtSigningKey
        }
      ], useRegistryCredentials ? [
        {
          name: 'registry-password'
          value: registryPassword
        }
      ] : [])
    }
    
    template: {
      containers: [
        {
          name: 'api'
          image: apiImage
          
          // Environment variables injected into container
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'Mongo__ConnectionString'
              secretRef: 'mongodb-connection' // Reference to secret
            }
            {
              name: 'Mongo__DatabaseName'
              value: mongoDbDatabaseName
            }
            {
              name: 'Jwt__Key'
              secretRef: 'jwt-signing-key'
            }
          ]
          
          // Resource allocation
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      
      // Auto-scaling configuration
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

// ============================================================================
// Frontend Container App - Public-facing application
// ============================================================================
resource frontendContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: frontendContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    
    configuration: {
      // Ingress configuration - Publicly accessible
      ingress: {
        external: true // Public-facing
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false // HTTPS only
      }
      
      // Container registry credentials
      registries: useRegistryCredentials ? [
        {
          server: registryServer
          username: registryUsername
          passwordSecretRef: 'registry-password'
        }
      ] : []
      
      // Secrets
      secrets: useRegistryCredentials ? [
        {
          name: 'registry-password'
          value: registryPassword
        }
      ] : []
    }
    
    template: {
      containers: [
        {
          name: 'frontend'
          image: frontendImage
          
          // Environment variables - Configured for API communication
          env: concat([
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'Api__BaseUrl'
              value: 'https://${apiContainerApp.properties.configuration.ingress.fqdn}'
            }
          ], empty(dataProtectionKeyRingPath) ? [] : [
            {
              name: 'DataProtection__KeyRingPath'
              value: dataProtectionKeyRingPath
            }
          ])
          
          // Resource allocation
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      
      // Auto-scaling configuration
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

// ============================================================================
// Outputs - Connection details for accessing deployed applications
// ============================================================================

@description('Internal FQDN for API service - used for frontend to service communication')
output apiInternalFqdn string = apiContainerApp.properties.configuration.ingress.fqdn

@description('Public URL to access the frontend application')
output frontendPublicUrl string = 'https://${frontendContainerApp.properties.configuration.ingress.fqdn}'

@description('Log Analytics Workspace ID - for querying application logs')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Static outgoing IP address for Container Apps - whitelist this in MongoDB Cloud')
output staticOutboundIP string = staticIpPublic.properties.ipAddress

@description('NAT Gateway ID - manages outbound connections to external services')
output natGatewayId string = natGateway.id
