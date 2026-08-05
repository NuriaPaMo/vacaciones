# IaC Tool Selection - Code Examples

> **Progressive Disclosure**: These examples demonstrate complete infrastructure deployments across Bicep, Terraform, ARM Templates, and Pulumi.

---

## 1. Bicep - Azure App Service with SQL Database

**Scenario**: Web application with managed database using Azure's native declarative language.

**File: main.bicep**

```bicep
@description('The base name for resources')
param baseName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('The administrator username for SQL Server')
@secure()
param sqlAdminUsername string

@description('The administrator password for SQL Server')
@secure()
param sqlAdminPassword string

@description('App Service SKU')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
  'P1v3'
])
param appServiceSku string = 'B1'

var appServicePlanName = '${baseName}-plan'
var webAppName = '${baseName}-app'
var sqlServerName = '${baseName}-sql'
var sqlDatabaseName = '${baseName}-db'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServiceSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
    }
    httpsOnly: true
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
  }
}

// Firewall rule to allow Azure services
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// App Settings with connection string
resource webAppSettings 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    ASPNETCORE_ENVIRONMENT: 'Production'
    ConnectionStrings__DefaultConnection: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Authentication=Active Directory Default;Encrypt=True;'
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppManagedIdentityPrincipalId string = webApp.identity.principalId
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
```

**File: main.bicepparam**

```bicep
using './main.bicep'

param baseName = 'myapp'
param location = 'eastus'
param sqlAdminUsername = 'sqladmin'
param appServiceSku = 'B1'
```

**Deployment:**

```bash
# Create resource group
az group create --name rg-myapp --location eastus

# Deploy with parameter file
az deployment group create \
  --resource-group rg-myapp \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters sqlAdminPassword='YourSecureP@ssw0rd!'
```

---

## 2. Terraform - Azure Container Apps with Cosmos DB

**Scenario**: Containerized microservices with NoSQL database using multi-cloud IaC tool.

**File: main.tf**

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "base_name" {
  description = "Base name for all resources"
  type        = string
  default     = "myapp"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

locals {
  resource_group_name = "rg-${var.base_name}-${var.environment}"
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# Log Analytics Workspace (required for Container Apps)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.base_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.base_name}-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${var.base_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = local.tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "db-${var.base_name}"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Cosmos DB Container
resource "azurerm_cosmosdb_sql_container" "main" {
  name                = "items"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/id"
}

# Container App
resource "azurerm_container_app" "api" {
  name                         = "ca-${var.base_name}-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "COSMOS_ENDPOINT"
        value = azurerm_cosmosdb_account.main.endpoint
      }

      env {
        name        = "COSMOS_KEY"
        secret_name = "cosmos-key"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = "cosmos-key"
    value = azurerm_cosmosdb_account.main.primary_key
  }

  tags = local.tags
}

output "container_app_url" {
  value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.main.endpoint
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
```

**File: terraform.tfvars**

```hcl
base_name   = "myapp"
location    = "East US"
environment = "dev"
```

**Deployment:**

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=deployment.tfplan

# Apply deployment
terraform apply deployment.tfplan

# Destroy resources
terraform destroy
```

---

## 3. ARM Templates - Azure Functions with Storage Account

**Scenario**: Serverless function app with blob storage using Azure's original JSON format.

**File: template.json**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "baseName": {
      "type": "string",
      "defaultValue": "myapp",
      "metadata": {
        "description": "Base name for resources"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for all resources"
      }
    },
    "functionRuntime": {
      "type": "string",
      "defaultValue": "dotnet-isolated",
      "allowedValues": ["dotnet-isolated", "node", "python"]
    }
  },
  "variables": {
    "storageAccountName": "[concat('st', parameters('baseName'), uniqueString(resourceGroup().id))]",
    "functionAppName": "[concat('func-', parameters('baseName'), '-', uniqueString(resourceGroup().id))]",
    "appServicePlanName": "[concat('plan-', parameters('baseName'))]",
    "applicationInsightsName": "[concat('appi-', parameters('baseName'))]"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-01-01",
      "name": "[variables('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2",
      "properties": {
        "supportsHttpsTrafficOnly": true,
        "minimumTlsVersion": "TLS1_2",
        "allowBlobPublicAccess": false
      }
    },
    {
      "type": "Microsoft.Insights/components",
      "apiVersion": "2020-02-02",
      "name": "[variables('applicationInsightsName')]",
      "location": "[parameters('location')]",
      "kind": "web",
      "properties": {
        "Application_Type": "web"
      }
    },
    {
      "type": "Microsoft.Web/serverfarms",
      "apiVersion": "2023-01-01",
      "name": "[variables('appServicePlanName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Y1",
        "tier": "Dynamic"
      },
      "properties": {
        "reserved": true
      }
    },
    {
      "type": "Microsoft.Web/sites",
      "apiVersion": "2023-01-01",
      "name": "[variables('functionAppName')]",
      "location": "[parameters('location')]",
      "kind": "functionapp,linux",
      "dependsOn": [
        "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]",
        "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]",
        "[resourceId('Microsoft.Insights/components', variables('applicationInsightsName'))]"
      ],
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]",
        "siteConfig": {
          "linuxFxVersion": "[concat('DOTNET-ISOLATED|8.0')]",
          "appSettings": [
            {
              "name": "AzureWebJobsStorage",
              "value": "[concat('DefaultEndpointsProtocol=https;AccountName=',variables('storageAccountName'),';AccountKey=',listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName')), '2023-01-01').keys[0].value,';EndpointSuffix=core.windows.net')]"
            },
            {
              "name": "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING",
              "value": "[concat('DefaultEndpointsProtocol=https;AccountName=',variables('storageAccountName'),';AccountKey=',listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName')), '2023-01-01').keys[0].value,';EndpointSuffix=core.windows.net')]"
            },
            {
              "name": "WEBSITE_CONTENTSHARE",
              "value": "[toLower(variables('functionAppName'))]"
            },
            {
              "name": "FUNCTIONS_EXTENSION_VERSION",
              "value": "~4"
            },
            {
              "name": "FUNCTIONS_WORKER_RUNTIME",
              "value": "[parameters('functionRuntime')]"
            },
            {
              "name": "APPLICATIONINSIGHTS_CONNECTION_STRING",
              "value": "[reference(resourceId('Microsoft.Insights/components', variables('applicationInsightsName'))).ConnectionString]"
            }
          ]
        },
        "httpsOnly": true
      }
    }
  ],
  "outputs": {
    "functionAppName": {
      "type": "string",
      "value": "[variables('functionAppName')]"
    },
    "functionAppUrl": {
      "type": "string",
      "value": "[concat('https://', reference(resourceId('Microsoft.Web/sites', variables('functionAppName'))).defaultHostName)]"
    },
    "storageAccountName": {
      "type": "string",
      "value": "[variables('storageAccountName')]"
    }
  }
}
```

**File: parameters.json**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "baseName": {
      "value": "myapp"
    },
    "functionRuntime": {
      "value": "dotnet-isolated"
    }
  }
}
```

**Deployment:**

```bash
# Deploy with Azure CLI
az deployment group create \
  --resource-group rg-myapp \
  --template-file template.json \
  --parameters parameters.json

# Deploy with PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-myapp `
  -TemplateFile template.json `
  -TemplateParameterFile parameters.json
```

---

## 4. Pulumi - Azure Kubernetes Service with Redis Cache

**Scenario**: Managed Kubernetes cluster with Redis cache using imperative TypeScript.

**File: index.ts**

```typescript
import * as pulumi from '@pulumi/pulumi';
import * as azure from '@pulumi/azure-native';
import * as azuread from '@pulumi/azuread';

const config = new pulumi.Config();
const baseName = config.get('baseName') || 'myapp';
const location = config.get('location') || 'EastUS';

// Resource Group
const resourceGroup = new azure.resources.ResourceGroup('rg', {
  resourceGroupName: `rg-${baseName}`,
  location: location,
  tags: {
    Environment: 'Production',
    ManagedBy: 'Pulumi',
  },
});

// Azure AD Application for AKS (Service Principal)
const aksApp = new azuread.Application('aks-app', {
  displayName: `${baseName}-aks-sp`,
});

const aksSpPassword = new azuread.ApplicationPassword('aks-sp-password', {
  applicationObjectId: aksApp.objectId,
});

const aksSp = new azuread.ServicePrincipal('aks-sp', {
  applicationId: aksApp.applicationId,
});

// Virtual Network for AKS
const vnet = new azure.network.VirtualNetwork('vnet', {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  virtualNetworkName: `vnet-${baseName}`,
  addressSpace: {
    addressPrefixes: ['10.0.0.0/16'],
  },
});

const aksSubnet = new azure.network.Subnet('aks-subnet', {
  resourceGroupName: resourceGroup.name,
  virtualNetworkName: vnet.name,
  subnetName: 'aks-subnet',
  addressPrefix: '10.0.1.0/24',
});

// AKS Cluster
const aksCluster = new azure.containerservice.ManagedCluster('aks', {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  resourceName: `aks-${baseName}`,
  dnsPrefix: `aks-${baseName}`,
  identity: {
    type: azure.containerservice.ResourceIdentityType.SystemAssigned,
  },
  agentPoolProfiles: [
    {
      name: 'agentpool',
      count: 2,
      vmSize: 'Standard_DS2_v2',
      osType: azure.containerservice.OSType.Linux,
      mode: azure.containerservice.AgentPoolMode.System,
      vnetSubnetID: aksSubnet.id,
    },
  ],
  networkProfile: {
    networkPlugin: azure.containerservice.NetworkPlugin.Azure,
    serviceCidr: '10.1.0.0/16',
    dnsServiceIP: '10.1.0.10',
  },
  servicePrincipalProfile: {
    clientId: aksApp.applicationId,
    secret: aksSpPassword.value,
  },
  tags: {
    Environment: 'Production',
  },
});

// Redis Cache
const redisCache = new azure.cache.Redis('redis', {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  name: `redis-${baseName}`,
  sku: {
    name: azure.cache.SkuName.Basic,
    family: azure.cache.SkuFamily.C,
    capacity: 0,
  },
  enableNonSslPort: false,
  minimumTlsVersion: azure.cache.TlsVersion.TlsVersion_1_2,
  redisConfiguration: {
    maxmemoryPolicy: 'allkeys-lru',
  },
  tags: {
    Environment: 'Production',
  },
});

// Outputs
export const resourceGroupName = resourceGroup.name;
export const aksClusterName = aksCluster.name;
export const kubeconfig = pulumi
  .all([aksCluster.name, resourceGroup.name])
  .apply(([clusterName, rgName]) =>
    azure.containerservice
      .listManagedClusterUserCredentials({
        resourceGroupName: rgName,
        resourceName: clusterName,
      })
      .then((creds) => {
        const kubeconfig = Buffer.from(creds.kubeconfigs[0].value, 'base64').toString();
        return kubeconfig;
      })
  );
export const redisHostName = redisCache.hostName;
export const redisPrimaryKey = pulumi.secret(
  redisCache.accessKeys.apply((keys) => keys!.primaryKey)
);
```

**File: Pulumi.yaml**

```yaml
name: myapp-infrastructure
runtime: nodejs
description: Azure AKS with Redis Cache
```

**File: Pulumi.dev.yaml**

```yaml
config:
  myapp-infrastructure:baseName: myapp
  myapp-infrastructure:location: EastUS
```

**Deployment:**

```bash
# Install dependencies
npm install @pulumi/pulumi @pulumi/azure-native @pulumi/azuread

# Login (Azure CLI auth)
pulumi login
az login

# Select/create stack
pulumi stack select dev

# Preview deployment
pulumi preview

# Deploy infrastructure
pulumi up

# Export kubeconfig
pulumi stack output kubeconfig --show-secrets > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# Destroy infrastructure
pulumi destroy
```

---

## 5. Bicep Modules - Reusable Components

**File: modules/app-service.bicep**

```bicep
@description('Base name for the app service and plan')
param baseName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
param sku string = 'B1'

@description('Runtime stack')
param linuxFxVersion string = 'DOTNETCORE|8.0'

@description('App settings as object')
param appSettings object = {}

var appServicePlanName = '${baseName}-plan'
var webAppName = '${baseName}-app'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: sku != 'F1' && sku != 'D1'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
    }
    httpsOnly: true
  }
}

resource webAppSettings 'Microsoft.Web/sites/config@2023-01-01' = if (!empty(appSettings)) {
  parent: webApp
  name: 'appsettings'
  properties: appSettings
}

output appServicePlanId string = appServicePlan.id
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output managedIdentityPrincipalId string = webApp.identity.principalId
```

**Usage in main.bicep:**

```bicep
module appService 'modules/app-service.bicep' = {
  name: 'appServiceDeployment'
  params: {
    baseName: 'myapp'
    location: location
    sku: 'B1'
    linuxFxVersion: 'DOTNETCORE|8.0'
    appSettings: {
      ASPNETCORE_ENVIRONMENT: 'Production'
      ApplicationInsights__ConnectionString: appInsights.outputs.connectionString
    }
  }
}
```

---

## 6. Terraform Modules - Modular Infrastructure

**File: modules/container-app/main.tf**

```hcl
variable "name" {
  description = "Container app name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "container_app_environment_id" {
  description = "Container Apps Environment ID"
  type        = string
}

variable "container_image" {
  description = "Container image"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "CPU allocation"
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "0.5Gi"
}

resource "azurerm_container_app" "main" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = var.name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

output "fqdn" {
  value = azurerm_container_app.main.ingress[0].fqdn
}

output "managed_identity_principal_id" {
  value = azurerm_container_app.main.identity[0].principal_id
}
```

**Usage:**

```hcl
module "api_container_app" {
  source = "./modules/container-app"

  name                         = "api"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  container_image              = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

  environment_variables = {
    API_KEY         = "your-api-key"
    DATABASE_URL    = "your-connection-string"
  }

  cpu    = 0.5
  memory = "1.0Gi"
}
```

---

## 7. Terraform State Management - Remote Backend

**File: backend.tf**

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatemyapp"
    container_name       = "tfstate"
    key                  = "production.tfstate"
  }
}
```

**Setup Script: setup-backend.sh**

```bash
#!/bin/bash

RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="sttfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

echo "Terraform backend created:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
```

---

## 8. CI/CD Integration - GitHub Actions with Terraform

**File: .github/workflows/terraform-deploy.yml**

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  terraform:
    name: Terraform Plan and Apply
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan

      - name: Output Infrastructure Details
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform output -json > infrastructure-outputs.json

      - name: Upload Outputs
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        uses: actions/upload-artifact@v4
        with:
          name: infrastructure-outputs
          path: infrastructure-outputs.json
```

---

## Summary

These examples demonstrate:

1. **Bicep** - Azure-native declarative language with strong typing
2. **Terraform** - Multi-cloud imperative HCL with state management
3. **ARM Templates** - Original Azure JSON format (legacy but still supported)
4. **Pulumi** - Imperative infrastructure using real programming languages
5. **Bicep Modules** - Reusable components for Bicep
6. **Terraform Modules** - Modular infrastructure patterns
7. **State Management** - Remote backend configuration for Terraform
8. **CI/CD** - Automated deployment workflows

All examples follow Azure best practices for security (HTTPS, managed identities, minimal TLS 1.2) and observability.
