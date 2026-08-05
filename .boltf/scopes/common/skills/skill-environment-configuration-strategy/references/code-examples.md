# Environment Configuration Strategy - Code Examples

> **Progressive Disclosure**: These examples demonstrate configuration patterns for local development, cloud deployments, and CI/CD pipelines.

---

## 1. Configuration Hierarchy - ASP.NET Core appsettings.json

**Scenario**: Layered configuration with environment-specific overrides and safe defaults.

**File: appsettings.json (Base)**

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": ""
  },
  "AppSettings": {
    "ApiBaseUrl": "https://api.example.com",
    "CacheExpirationMinutes": 60,
    "MaxRetryAttempts": 3,
    "EnableFeatureX": false
  },
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "",
    "TenantId": "",
    "ClientId": ""
  }
}
```

**File: appsettings.Development.json (Local Overrides)**

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=MyAppDev;Trusted_Connection=True;"
  },
  "AppSettings": {
    "ApiBaseUrl": "https://localhost:7001",
    "EnableFeatureX": true
  },
  "AzureAd": {
    "Domain": "localhost",
    "TenantId": "common",
    "ClientId": "local-dev-client-id"
  }
}
```

**File: appsettings.Production.json (Production Overrides)**

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error"
    }
  },
  "AppSettings": {
    "CacheExpirationMinutes": 120,
    "MaxRetryAttempts": 5
  }
}
```

**File: Program.cs (Configuration Loading)**

```csharp
var builder = WebApplication.CreateBuilder(args);

// Configuration sources (order matters - last wins):
// 1. appsettings.json (base)
// 2. appsettings.{Environment}.json (environment-specific)
// 3. User Secrets (Development only, via builder.Configuration)
// 4. Environment variables (overrides all file-based)
// 5. Command-line arguments (highest priority)

// Configuration automatically loaded by WebApplicationBuilder
// Custom: Add Azure App Configuration or Key Vault here

var app = builder.Build();

// Access configuration
var apiUrl = builder.Configuration["AppSettings:ApiBaseUrl"];
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

app.MapGet("/config-demo", (IConfiguration config) =>
{
    return new
    {
        Environment = builder.Environment.EnvironmentName,
        ApiBaseUrl = config["AppSettings:ApiBaseUrl"],
        CacheExpiration = config.GetValue<int>("AppSettings:CacheExpirationMinutes"),
        FeatureXEnabled = config.GetValue<bool>("AppSettings:EnableFeatureX")
    };
});

app.Run();
```

**Configuration Hierarchy (Priority Order):**

1. appsettings.json (lowest priority, defaults)
2. appsettings.{Environment}.json (environment-specific)
3. User Secrets (`dotnet user-secrets set`)
4. Environment variables
5. Command-line arguments (highest priority)

---

## 2. Environment Variables - Configuration Override

**Scenario**: Override configuration values via environment variables without modifying files.

**File: Program.cs (.NET)**

```csharp
var builder = WebApplication.CreateBuilder(args);

// Environment variables automatically  loaded
// Syntax: SectionName__NestedKey (double underscore)
// Example: AppSettings__ApiBaseUrl

var app = builder.Build();

app.MapGet("/env-demo", (IConfiguration config) =>
{
    // These can be overridden via environment variables:
    // - AppSettings__ApiBaseUrl
    // - ConnectionStrings__DefaultConnection
    // - AzureAd__TenantId

    return new
    {
        ApiBaseUrl = config["AppSettings:ApiBaseUrl"],
        ConnectionString = config.GetConnectionString("DefaultConnection"),
        TenantId = config["AzureAd:TenantId"],
        FromEnvVar = Environment.GetEnvironmentVariable("MY_CUSTOM_VAR")
    };
});

app.Run();
```

**Setting Environment Variables:**

```bash
# Linux/macOS
export AppSettings__ApiBaseUrl="https://prod-api.example.com"
export ConnectionStrings__DefaultConnection="Server=prod-server;Database=MyApp;"
export ASPNETCORE_ENVIRONMENT="Production"

# Windows PowerShell
$env:AppSettings__ApiBaseUrl = "https://prod-api.example.com"
$env:ConnectionStrings__DefaultConnection = "Server=prod-server;Database=MyApp;"
$env:ASPNETCORE_ENVIRONMENT = "Production"

# Azure App Service Application Settings (set via Azure Portal or CLI)
# Automatically converted to environment variables
az webapp config appsettings set \
  --resource-group rg-myapp \
  --name myapp \
  --settings AppSettings__ApiBaseUrl="https://prod-api.example.com"
```

**Docker Compose Example:**

```yaml
version: '3.8'
services:
  api:
    image: myapp:latest
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - AppSettings__ApiBaseUrl=https://prod-api.example.com
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=MyApp;User Id=sa;Password=${SA_PASSWORD};
      - AzureAd__TenantId=${AZURE_TENANT_ID}
    env_file:
      - .env.production
```

---

## 3. Azure App Configuration Integration

**Scenario**: Centralized configuration service for dynamic settings across multiple applications.

**File: Program.cs**

```csharp
using Azure.Identity;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;

var builder = WebApplication.CreateBuilder(args);

// Add Azure App Configuration
builder.Configuration.AddAzureAppConfiguration(options =>
{
    var appConfigEndpoint = builder.Configuration["AppConfigEndpoint"];

    options
        .Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential())
        .Select(KeyFilter.Any, LabelFilter.Null) // Load keys with no label
        .Select(KeyFilter.Any, builder.Environment.EnvironmentName) // Load environment-specific keys
        .ConfigureRefresh(refresh =>
        {
            // Watch for changes to sentinel key
            refresh.Register("Sentinel", refreshAll: true)
                   .SetCacheExpiration(TimeSpan.FromMinutes(5));
        })
        .UseFeatureFlags(featureFlags =>
        {
            featureFlags.CacheExpirationInterval = TimeSpan.FromMinutes(5);
        });
});

// Register refresh middleware
builder.Services.AddAzureAppConfiguration();

var app = builder.Build();

// Enable configuration refresh via middleware
app.UseAzureAppConfiguration();

app.MapGet("/config", (IConfiguration config) =>
{
    return new
    {
        ApiBaseUrl = config["AppSettings:ApiBaseUrl"],
        CacheExpiration = config["AppSettings:CacheExpirationMinutes"],
        RefreshMessage = "Configuration can be updated in Azure App Configuration"
    };
});

app.Run();
```

**Azure CLI Setup:**

```bash
# Create App Configuration store
az appconfig create \
  --name myapp-appconfig \
  --resource-group rg-myapp \
  --location eastus \
  --sku standard

# Set configuration values
az appconfig kv set \
  --name myapp-appconfig \
  --key "AppSettings:ApiBaseUrl" \
  --value "https://api.example.com" \
  --label "Production" \
  --yes

az appconfig kv set \
  --name myapp-appconfig \
  --key "AppSettings:CacheExpirationMinutes" \
  --value "120" \
  --label "Production" \
  --yes

# Set sentinel key for refresh
az appconfig kv set \
  --name myapp-appconfig \
  --key "Sentinel" \
  --value "1" \
  --yes
```

**NuGet Packages:**

- Microsoft.Extensions.Configuration.AzureAppConfiguration (7.0+)
- Azure.Identity (1.11+)

---

## 4. Azure Key Vault Integration - Secret Management

**Scenario**: Store sensitive configuration (connection strings, API keys) securely in Key Vault.

**File: Program.cs**

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add Azure Key Vault
var keyVaultEndpoint = builder.Configuration["KeyVaultEndpoint"];
if (!string.IsNullOrEmpty(keyVaultEndpoint))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultEndpoint),
        new DefaultAzureCredential());
}

// Register Key Vault client for runtime secret access
builder.Services.AddSingleton<SecretClient>(sp =>
{
    var endpoint = builder.Configuration["KeyVaultEndpoint"];
    return new SecretClient(new Uri(endpoint), new DefaultAzureCredential());
});

var app = builder.Build();

app.MapGet("/secret-demo", async (IConfiguration config, SecretClient secretClient) =>
{
    // Secrets loaded as configuration (hyphens become colons)
    // Key Vault secret: "ConnectionStrings--DefaultConnection"
    // Accessed as: config["ConnectionStrings:DefaultConnection"]

    var connectionString = config["ConnectionStrings:DefaultConnection"];

    // Or fetch secret directly at runtime
    KeyVaultSecret secret = await secretClient.GetSecretAsync("ApiKey");

    return new
    {
        HasConnectionString = !string.IsNullOrEmpty(connectionString),
        SecretVersion = secret.Properties.Version,
        Message = "Sensitive values loaded from Key Vault"
    };
});

app.Run();
```

**Azure CLI Setup:**

```bash
# Create Key Vault
az keyvault create \
  --name myapp-kv \
  --resource-group rg-myapp \
  --location eastus \
  --enable-rbac-authorization false

# Store secrets (hyphens map to configuration hierarchy)
az keyvault secret set \
  --vault-name myapp-kv \
  --name "ConnectionStrings--DefaultConnection" \
  --value "Server=prod-sql.database.windows.net;Database=MyApp;User Id=appuser;Password=SecureP@ssw0rd;"

az keyvault secret set \
  --vault-name myapp-kv \
  --name "ApiKey" \
  --value "super-secret-api-key-12345"

# Grant App Service managed identity access
az keyvault set-policy \
  --name myapp-kv \
  --object-id <app-service-managed-identity-id> \
  --secret-permissions get list
```

**NuGet Packages:**

- Azure.Extensions.AspNetCore.Configuration.Secrets (1.3+)
- Azure.Security.KeyVault.Secrets (4.5+)
- Azure.Identity (1.11+)

---

## 5. Feature Flags - Azure App Configuration

**Scenario**: Toggle features dynamically without redeployment using feature management.

**File: Program.cs**

```csharp
using Microsoft.FeatureManagement;

var builder = WebApplication.CreateBuilder(args);

// Add Azure App Configuration with Feature Management
builder.Configuration.AddAzureAppConfiguration(options =>
{
    options
        .Connect(new Uri(builder.Configuration["AppConfigEndpoint"]), new DefaultAzureCredential())
        .UseFeatureFlags();
});

builder.Services.AddFeatureManagement();

var app = builder.Build();

app.MapGet("/feature-demo", async (IFeatureManager featureManager) =>
{
    var isBetaEnabled = await featureManager.IsEnabledAsync("BetaFeatures");
    var isPremiumEnabled = await featureManager.IsEnabledAsync("PremiumFeatures");

    return new
    {
        BetaFeatures = isBetaEnabled ? "Enabled" : "Disabled",
        PremiumFeatures = isPremiumEnabled ? "Enabled" : "Disabled"
    };
});

app.MapGet("/api/data", async (IFeatureManager featureManager) =>
{
    var data = new List<string> { "item1", "item2", "item3" };

    if (await featureManager.IsEnabledAsync("BetaFeatures"))
    {
        data.Add("beta-item");
    }

    return data;
});

app.Run();
```

**Feature Flag Configuration (appsettings.json for local dev):**

```json
{
  "FeatureManagement": {
    "BetaFeatures": false,
    "PremiumFeatures": true,
    "NewDashboard": {
      "EnabledFor": [
        {
          "Name": "Percentage",
          "Parameters": {
            "Value": 50
          }
        }
      ]
    }
  }
}
```

**Azure CLI Feature Flag Setup:**

```bash
# Create feature flag in App Configuration
az appconfig feature set \
  --name myapp-appconfig \
  --feature "BetaFeatures" \
  --label "Production" \
  --yes

# Enable feature flag
az appconfig feature enable \
  --name myapp-appconfig \
  --feature "BetaFeatures" \
  --label "Production" \
  --yes

# Set percentage-based feature (A/B testing)
az appconfig feature filter add \
  --name myapp-appconfig \
  --feature "NewDashboard" \
  --filter-name "Microsoft.Percentage" \
  --filter-parameters "Value=50" \
  --label "Production" \
  --yes
```

**NuGet Packages:**

- Microsoft.FeatureManagement.AspNetCore (3.2+)

---

## 6. Configuration in Node.js - dotenv + Environment Variables

**Scenario**: Environment-based configuration for Node.js applications.

**File: .env (Development - DO NOT COMMIT)**

```env
NODE_ENV=development
PORT=3000
API_BASE_URL=http://localhost:3001
DATABASE_URL=postgresql://user:password@localhost:5432/myapp_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=local-dev-secret-key-change-in-production
AZURE_TENANT_ID=common
AZURE_CLIENT_ID=local-client-id
LOG_LEVEL=debug
ENABLE_FEATURE_X=true
```

**File: .env.production (Production Template - VALUES IN CI/CD)**

```env
NODE_ENV=production
PORT=8080
API_BASE_URL=https://api.example.com
DATABASE_URL=${DATABASE_URL}
REDIS_URL=${REDIS_URL}
JWT_SECRET=${JWT_SECRET}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
LOG_LEVEL=info
ENABLE_FEATURE_X=false
```

**File: config.js (Centralized Configuration with Validation)**

```javascript
require('dotenv').config(); // Load .env file

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,

  api: {
    baseUrl: process.env.API_BASE_URL || 'http://localhost:3001',
    timeout: parseInt(process.env.API_TIMEOUT, 10) || 30000,
  },

  database: {
    url: process.env.DATABASE_URL,
    poolMin: parseInt(process.env.DB_POOL_MIN, 10) || 2,
    poolMax: parseInt(process.env.DB_POOL_MAX, 10) || 10,
  },

  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    ttl: parseInt(process.env.REDIS_TTL, 10) || 3600,
  },

  auth: {
    jwtSecret: process.env.JWT_SECRET,
    azureTenantId: process.env.AZURE_TENANT_ID,
    azureClientId: process.env.AZURE_CLIENT_ID,
  },

  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },

  features: {
    enableFeatureX: process.env.ENABLE_FEATURE_X === 'true',
  },
};

// Validation: Ensure required variables are set
const requiredEnvVars = ['DATABASE_URL', 'JWT_SECRET'];

if (config.env === 'production') {
  requiredEnvVars.push('AZURE_TENANT_ID', 'AZURE_CLIENT_ID');
}

const missingVars = requiredEnvVars.filter((varName) => !process.env[varName]);
if (missingVars.length > 0) {
  throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
}

module.exports = config;
```

**File: server.js (Usage)**

```javascript
const express = require('express');
const config = require('./config');

const app = express();

app.get('/config', (req, res) => {
  res.json({
    environment: config.env,
    apiBaseUrl: config.api.baseUrl,
    features: config.features,
    // Never expose secrets in responses
    hasJwtSecret: !!config.auth.jwtSecret,
  });
});

app.listen(config.port, () => {
  console.log(`Server running on port ${config.port} in ${config.env} mode`);
});
```

**npm packages:**

- dotenv (^16.4.0)

---

## 7. Configuration Validation - .NET Options Pattern

**Scenario**: Strongly-typed configuration with validation at startup.

**File: AppSettings.cs (Options Class)**

```csharp
using System.ComponentModel.DataAnnotations;

public class AppSettings
{
    public const string SectionName = "AppSettings";

    [Required]
    [Url]
    public string ApiBaseUrl { get; set; } = string.Empty;

    [Range(1, 1440)]
    public int CacheExpirationMinutes { get; set; } = 60;

    [Range(1, 10)]
    public int MaxRetryAttempts { get; set; } = 3;

    public bool EnableFeatureX { get; set; } = false;
}

public class AzureAdSettings
{
    public const string SectionName = "AzureAd";

    [Required]
    public string Instance { get; set; } = string.Empty;

    [Required]
    public string TenantId { get; set; } = string.Empty;

    [Required]
    public string ClientId { get; set; } = string.Empty;

    public string? ClientSecret { get; set; }
}
```

**File: Program.cs (Options Registration with Validation)**

```csharp
var builder = WebApplication.CreateBuilder(args);

// Register strongly-typed configuration with validation
builder.Services.AddOptions<AppSettings>()
    .Bind(builder.Configuration.GetSection(AppSettings.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart(); // Fail fast on startup if invalid

builder.Services.AddOptions<AzureAdSettings>()
    .Bind(builder.Configuration.GetSection(AzureAdSettings.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

var app = builder.Build();

app.MapGet("/typed-config", (IOptions<AppSettings> appSettings, IOptions<AzureAdSettings> azureAd) =>
{
    var settings = appSettings.Value;
    var azure = azureAd.Value;

    return new
    {
        ApiBaseUrl = settings.ApiBaseUrl,
        CacheExpiration = settings.CacheExpirationMinutes,
        RetryAttempts = settings.MaxRetryAttempts,
        FeatureX = settings.EnableFeatureX,
        TenantId = azure.TenantId
    };
});

app.Run();
```

**Benefits:**

- Compile-time type safety
- Validation at startup (fail fast)
- IntelliSense support
- Testable (inject IOptions<T> mock)

**NuGet Packages:**

- Microsoft.Extensions.Options.DataAnnotations

---

## 8. CI/CD Configuration Injection - GitHub Actions

**Scenario**: Inject configuration values securely in deployment pipeline.

**File: .github/workflows/deploy.yml**

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

env:
  AZURE_WEBAPP_NAME: myapp-prod
  DOTNET_VERSION: '8.0.x'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Publish
        run: dotnet publish --configuration Release --no-build --output ./publish

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Set App Settings in Azure App Service
        uses: azure/appservice-settings@v1
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }}
          app-settings-json: |
            [
              {
                "name": "ASPNETCORE_ENVIRONMENT",
                "value": "Production",
                "slotSetting": false
              },
              {
                "name": "AppSettings__ApiBaseUrl",
                "value": "${{ secrets.API_BASE_URL }}",
                "slotSetting": false
              },
              {
                "name": "AppSettings__CacheExpirationMinutes",
                "value": "120",
                "slotSetting": false
              },
              {
                "name": "ConnectionStrings__DefaultConnection",
                "value": "${{ secrets.SQL_CONNECTION_STRING }}",
                "slotSetting": false
              },
              {
                "name": "AzureAd__TenantId",
                "value": "${{ secrets.AZURE_TENANT_ID }}",
                "slotSetting": false
              },
              {
                "name": "AzureAd__ClientId",
                "value": "${{ secrets.AZURE_CLIENT_ID }}",
                "slotSetting": false
              },
              {
                "name": "KeyVaultEndpoint",
                "value": "${{ secrets.KEY_VAULT_ENDPOINT }}",
                "slotSetting": false
              }
            ]

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }}
          package: ./publish
```

**GitHub Secrets (Repository Settings > Secrets and variables > Actions):**

- `AZURE_CREDENTIALS` - Service principal JSON
- `API_BASE_URL` - Production API endpoint
- `SQL_CONNECTION_STRING` - Production database connection
- `AZURE_TENANT_ID` - Entra ID tenant
- `AZURE_CLIENT_ID` - Application client ID
- `KEY_VAULT_ENDPOINT` - Key Vault URL

---

## Summary

These examples demonstrate:

1. **Configuration Hierarchy** - layered appsettings.json with environment-specific overrides
2. **Environment Variables** - runtime configuration override pattern
3. **Azure App Configuration** - centralized, dynamic configuration service
4. **Azure Key Vault** - secure secret storage and retrieval
5. **Feature Flags** - dynamic feature toggles without redeployment
6. **Node.js Configuration** - dotenv pattern with validation
7. **Options Pattern** - strongly-typed, validated configuration in .NET
8. **CI/CD Injection** - secure configuration deployment via GitHub Actions

All examples follow 12-factor app principles with secrets externalized from code.
