// Azure Container Apps Deployment for Series Catalog Application
// Deploys API and Frontend with shared environment, logging, and networking

param location string = resourceGroup().location
param containerAppsEnvironmentName string = 'cae-series-catalog'
param apiContainerAppName string = 'ca-api'
param frontendContainerAppName string = 'ca-frontend'
param acrLoginServer string
param acrUsername string

@secure()
param acrPassword string

// MongoDB settings - Use Azure Cosmos DB or MongoDB Atlas connection string
@secure()
param mongoDbConnectionString string

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
        sharedKey: listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
      }
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
      registries: [
        {
          server: acrLoginServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      
      // Secrets - Referenced by environment variables
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
          
          // Environment variables injected into container
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'MongoDb__ConnectionString'
              secretRef: 'mongodb-connection' // Reference to secret
            }
            {
              name: 'MongoDb__DatabaseName'
              value: 'series_catalog'
            }
          ]
          
          // Resource allocation
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      
      // Auto-scaling configuration
      scale: {
        minReplicas: 1
        maxReplicas: 3
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
      registries: [
        {
          server: acrLoginServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      
      // Secrets
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
          
          // Environment variables - Configured for API communication
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
          
          // Resource allocation
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      
      // Auto-scaling configuration
      scale: {
        minReplicas: 1
        maxReplicas: 3
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
