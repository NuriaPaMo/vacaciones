# Security Policies Azure - Code Examples

Complete examples demonstrating Managed Identity authentication, Key Vault secret management, Azure Policy enforcement, RBAC role assignments, Microsoft Defender for Cloud configuration, and security headers for Azure applications.

---

## Example 1: Managed Identity Authentication (Passwordless)

**Pattern**: Use Azure Managed Identity with `DefaultAzureCredential` for passwordless authentication to Azure services (Key Vault, Cosmos DB, Storage, Service Bus).

**When to Use**: Any Azure application (App Service, Container Apps, Azure Functions, VMs) accessing Azure resources—eliminates secrets/connection strings in code or configuration.

```csharp
// Program.cs (.NET 8 Web API)
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Storage.Blobs;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

// DefaultAzureCredential chain: Managed Identity → Visual Studio → Azure CLI → ...
var credential = new DefaultAzureCredential();

// Configure Key Vault client with Managed Identity
var keyVaultUrl = builder.Configuration["KeyVault:Url"]; // https://kv-myapp-prod.vault.azure.net/
var secretClient = new SecretClient(new Uri(keyVaultUrl), credential);
builder.Services.AddSingleton(secretClient);

// Configure Blob Storage client with Managed Identity
var storageAccountUrl = builder.Configuration["Storage:AccountUrl"]; // https://stmyappprod.blob.core.windows.net/
var blobServiceClient = new BlobServiceClient(new Uri(storageAccountUrl), credential);
builder.Services.AddSingleton(blobServiceClient);

// Configure SQL Server connection with Managed Identity
var sqlConnectionString = builder.Configuration["Sql:ConnectionString"] + ";Authentication=Active Directory Default;";
builder.Services.AddScoped<SqlConnection>(_ => new SqlConnection(sqlConnectionString));

builder.Services.AddControllers();

var app = builder.Build();

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();

// Controllers/SecretsController.cs
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class SecretsController : ControllerBase
{
    private readonly SecretClient _secretClient;
    private readonly ILogger<SecretsController> _logger;

    public SecretsController(SecretClient secretClient, ILogger<SecretsController> logger)
    {
        _secretClient = secretClient;
        _logger = logger;
    }

    [HttpGet("{secretName}")]
    public async Task<IActionResult> GetSecret(string secretName)
    {
        try
        {
            // Retrieve secret from Key Vault using Managed Identity (no connection string!)
            KeyVaultSecret secret = await _secretClient.GetSecretAsync(secretName);

            _logger.LogInformation("Retrieved secret {SecretName} from Key Vault", secretName);

            // Return secret value (in practice, use secret internally, don't expose via API)
            return Ok(new { Name = secret.Name, Value = secret.Value });
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 403)
        {
            _logger.LogError("Access denied to secret {SecretName}. Check Managed Identity RBAC permissions.", secretName);
            return StatusCode(403, "Access denied to Key Vault secret");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve secret {SecretName}", secretName);
            return StatusCode(500, "Failed to retrieve secret");
        }
    }
}

// Controllers/FilesController.cs
using Azure.Storage.Blobs;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    private readonly BlobServiceClient _blobServiceClient;

    public FilesController(BlobServiceClient blobServiceClient)
    {
        _blobServiceClient = blobServiceClient;
    }

    [HttpGet("{containerName}/{blobName}")]
    public async Task<IActionResult> DownloadFile(string containerName, string blobName)
    {
        try
        {
            // Access Blob Storage using Managed Identity
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobName);

            // Check blob exists
            if (!await blobClient.ExistsAsync())
            {
                return NotFound($"Blob {blobName} not found in container {containerName}");
            }

            // Download blob content
            var download = await blobClient.DownloadContentAsync();
            var content = download.Value.Content.ToArray();

            return File(content, "application/octet-stream", blobName);
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 403)
        {
            return StatusCode(403, "Access denied to Blob Storage. Check Managed Identity RBAC permissions.");
        }
    }
}
```

**Explanation**: `DefaultAzureCredential` automatically uses Managed Identity when running in Azure (App Service, Container Apps, Functions, VMs). No secrets in code—RBAC grants Managed Identity access to Key Vault, Storage, SQL. Works locally via Azure CLI or Visual Studio credentials. `Authentication=Active Directory Default` enables SQL Server Managed Identity authentication (Azure SQL Database).

---

## Example 2: Key Vault Secret Retrieval and Rotation

**Pattern**: Store secrets (connection strings, API keys, certificates) in Azure Key Vault, retrieve via Managed Identity with automatic rotation support.

**When to Use**: Any secret/credential needed by application—database passwords, third-party API keys, encryption keys, TLS certificates.

```bicep
// infra/keyvault.bicep
param location string = resourceGroup().location
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'
param appServiceName string
param tenantId string = subscription().tenantId

// Key Vault resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: tenantId
    enableRbacAuthorization: true // Use RBAC instead of access policies
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

// App Service resource (existing)
resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

// Grant App Service Managed Identity "Key Vault Secrets User" role
resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appService.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Secret: Database connection string
resource dbConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'DatabaseConnectionString'
  properties: {
    value: 'Server=tcp:sql-myapp-prod.database.windows.net,1433;Database=myapp;'
    contentType: 'text/plain'
    attributes: {
      enabled: true
      exp: dateTimeToEpoch(dateTimeAdd(utcNow(), 'P90D')) // Expires in 90 days (rotation reminder)
    }
  }
}

// Secret: Third-party API key
resource apiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'ThirdPartyApiKey'
  properties: {
    value: 'example_of_api_key'
    contentType: 'text/plain'
  }
}

output keyVaultName string = keyVault.name
output keyVaultUrl string = keyVault.properties.vaultUri
```

```csharp
// Services/ConfigurationService.cs (automatic Key Vault secret refresh)
using Azure.Security.KeyVault.Secrets;
using Microsoft.Extensions.Caching.Memory;

public class ConfigurationService
{
    private readonly SecretClient _secretClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ConfigurationService> _logger;

    public ConfigurationService(SecretClient secretClient, IMemoryCache cache, ILogger<ConfigurationService> logger)
    {
        _secretClient = secretClient;
        _cache = cache;
        _logger = logger;
    }

    public async Task<string> GetSecretAsync(string secretName)
    {
        // Check cache first (30-minute TTL)
        if (_cache.TryGetValue(secretName, out string? cachedValue))
        {
            return cachedValue!;
        }

        try
        {
            // Retrieve from Key Vault
            KeyVaultSecret secret = await _secretClient.GetSecretAsync(secretName);

            // Cache with 30-minute expiration (automatic rotation support)
            _cache.Set(secretName, secret.Value, TimeSpan.FromMinutes(30));

            _logger.LogInformation("Retrieved and cached secret {SecretName}", secretName);

            return secret.Value;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve secret {SecretName} from Key Vault", secretName);
            throw;
        }
    }

    public async Task<string> GetDatabaseConnectionStringAsync()
    {
        return await GetSecretAsync("DatabaseConnectionString");
    }

    public async Task<string> GetThirdPartyApiKeyAsync()
    {
        return await GetSecretAsync("ThirdPartyApiKey");
    }
}
```

**Explanation**: Key Vault stores secrets with attributes (enabled, expiration dates). RBAC role "Key Vault Secrets User" grants read-only access to Managed Identity. `enableSoftDelete` and `enablePurgeProtection` prevent accidental deletion. Caching secrets reduces Key Vault API calls (cost optimization), with 30-minute TTL enabling automatic rotation (updated secrets fetched after cache expiration). Secret rotation triggers: update secret in Key Vault → applications refresh cached value within 30 minutes.

---

## Example 3: Azure Policy Enforcement (HTTPS-Only, Allowed Locations)

**Pattern**: Use Azure Policy to enforce organization-wide security standards (HTTPS-only for App Services, allowed Azure regions, required tags, deny public network access).

**When to Use**: Governance and compliance requirements—prevent developers from deploying insecure resources, enforce cost controls (restrict regions), ensure proper tagging.

```bicep
// infra/policies.bicep
param location string = 'eastus'

// Azure Policy: Require HTTPS for App Services
resource httpsOnlyPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'RequireHttpsForAppServices'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'App Services must use HTTPS only'
    description: 'Enforces HTTPS-only traffic for App Services to prevent unencrypted data transmission.'
    metadata: {
      category: 'Security'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Web/sites'
          }
          {
            field: 'Microsoft.Web/sites/httpsOnly'
            notEquals: 'true'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Azure Policy: Allowed locations for resources
resource allowedLocationsPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'AllowedLocations'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Allowed locations for resources'
    description: 'Restricts resources to specific Azure regions (eastus, westus, northeurope).'
    metadata: {
      category: 'Governance'
    }
    parameters: {
      allowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          description: 'List of allowed Azure regions'
        }
        defaultValue: ['eastus', 'westus', 'northeurope']
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'location'
            notIn: '[parameters(\'allowedLocations\')]'
          }
          {
            field: 'type'
            notEquals: 'Microsoft.Authorization/roleAssignments' // Exclude global resources
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Azure Policy: Require tags on resources
resource requireTagsPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'RequireTags'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Require tags on resources'
    description: 'Enforces presence of required tags (Environment, CostCenter, Owner).'
    metadata: {
      category: 'Governance'
    }
    parameters: {
      requiredTags: {
        type: 'Array'
        metadata: {
          displayName: 'Required tags'
          description: 'List of tag names that must be present'
        }
        defaultValue: ['Environment', 'CostCenter', 'Owner']
      }
    }
    policyRule: {
      if: {
        anyOf: [
          for tagName in '[parameters(\'requiredTags\')]': {
            field: 'tags[${tagName}]'
            exists: 'false'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Policy Assignment at Resource Group level
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'EnforceSecurityPolicies'
  properties: {
    displayName: 'Enforce Security Policies for Production'
    description: 'Assigns HTTPS-only and allowed locations policies to production resource group'
    policyDefinitionId: httpsOnlyPolicy.id
    enforcementMode: 'Default' // 'Default' = enforce, 'DoNotEnforce' = audit only
    parameters: {}
  }
}

// Azure Policy Initiative (Policy Set) - multiple policies grouped
resource policyInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'ProductionSecurityBaseline'
  properties: {
    policyType: 'Custom'
    displayName: 'Production Security Baseline'
    description: 'Security policies for production workloads (HTTPS, locations, tags).'
    metadata: {
      category: 'Security'
    }
    policyDefinitions: [
      {
        policyDefinitionId: httpsOnlyPolicy.id
        parameters: {}
      }
      {
        policyDefinitionId: allowedLocationsPolicy.id
        parameters: {
          allowedLocations: { value: ['eastus', 'westus'] }
        }
      }
      {
        policyDefinitionId: requireTagsPolicy.id
        parameters: {
          requiredTags: { value: ['Environment', 'CostCenter', 'Owner'] }
        }
      }
    ]
  }
}
```

**Explanation**: Azure Policy enforces rules at scope (Management Group, Subscription, Resource Group). `effect: 'deny'` blocks non-compliant resource creation. Policy Initiatives (Policy Sets) group multiple policies for easier management (e.g., "Production Security Baseline"). Compliance dashboard shows non-compliant resources. `enforcementMode: 'DoNotEnforce'` enables audit-only mode (identify violations without blocking deployments).

---

## Example 4: RBAC Role Assignments (Least Privilege)

**Pattern**: Use Azure Role-Based Access Control (RBAC) to grant fine-grained permissions to Managed Identities, users, or service principals using built-in or custom roles.

**When to Use**: Any resource access control—grant App Service read access to Key Vault, grant user admin access to Resource Group, grant CI/CD pipeline deployment permissions.

```bicep
// infra/rbac.bicep
param location string = resourceGroup().location
param appServiceName string
param keyVaultName string
param storageAccountName string
param sqlServerName string
param storageContainerName string = 'uploads'

// Existing resources
resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' existing = {
  name: sqlServerName
}

// RBAC: Key Vault Secrets User (read secrets only)
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appService.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: Storage Blob Data Contributor (read/write blobs)
resource storageBlobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, appService.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: SQL Server Contributor (SQL authentication requires additional setup)
// Note: For SQL Managed Identity auth, add Managed Identity as SQL user via T-SQL
resource sqlContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlServer.id, appService.id, 'SQL DB Contributor')
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec') // SQL DB Contributor (manage databases, not data access)
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Custom RBAC Role: Read-Only Container Viewer
resource customReadOnlyRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'CustomReadOnlyContainerViewer')
  properties: {
    roleName: 'Custom Read-Only Container Viewer'
    description: 'Can list and view containers but not modify or delete'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Storage/storageAccounts/listKeys/action'
          'Microsoft.Storage/storageAccounts/read'
        ]
        notActions: []
        dataActions: [
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
        ]
        notDataActions: []
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

// Assign custom role to App Service
resource customRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, appService.id, customReadOnlyRole.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: customReadOnlyRole.id
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

**SQL T-SQL Setup for Managed Identity**:

```sql
-- Connect to Azure SQL Database with admin account
-- Add Managed Identity as SQL user (enables DefaultAzureCredential authentication)

CREATE USER [app-myapi-prod] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [app-myapi-prod];
ALTER ROLE db_datawriter ADD MEMBER [app-myapi-prod];
GO
```

**Explanation**: RBAC grants fine-grained permissions at specific scopes (subscription, resource group, individual resource). Built-in roles (Key Vault Secrets User, Storage Blob Data Contributor) follow least privilege principle. Custom roles define precise permissions (actions, dataActions). `principalType: 'ServicePrincipal'` for Managed Identities. SQL Server Managed Identity requires both RBAC role assignment AND T-SQL user creation (`CREATE USER FROM EXTERNAL PROVIDER`).

---

## Example 5: Microsoft Defender for Cloud Configuration

**Pattern**: Enable Microsoft Defender for Cloud (formerly Azure Security Center) for threat detection, vulnerability assessment, security recommendations, and compliance dashboards.

**When to Use**: Production environments requiring security monitoring, compliance reporting (SOC 2, ISO 27001, NIST), automated security assessments.

```bicep
// infra/defender.bicep
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = 'log-defender-${uniqueString(resourceGroup().id)}'

// Log Analytics Workspace (required for Defender for Cloud)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

// Enable Microsoft Defender for Cloud (subscription-level, typically via Azure CLI or Portal)
// Bicep doesn't directly support subscription-level Defender enablement, but can configure workspace

// Azure Policy: Auto-provision Log Analytics agent
resource autoProvisionPolicy 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'AutoProvisionLogAnalyticsAgent'
  properties: {
    displayName: 'Auto-provision Log Analytics Agent'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/98d0b9f8-fd90-49c9-88e2-d3baf3b0dd86' // Built-in policy: "Configure Log Analytics extension to be enabled on virtual machines"
    parameters: {
      logAnalyticsWorkspaceId: {
        value: logAnalyticsWorkspace.id
      }
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
```

**Azure CLI Commands to Enable Defender Plans**:

```bash
# Enable Defender for Cloud Standard tier (paid, advanced features)
az security pricing create --name VirtualMachines --tier Standard
az security pricing create --name AppServices --tier Standard
az security pricing create --name SqlServers --tier Standard
az security pricing create --name StorageAccounts --tier Standard
az security pricing create --name ContainerRegistry --tier Standard
az security pricing create --name KeyVaults --tier Standard

# Enable Defender for Containers (Kubernetes)
az security pricing create --name Containers --tier Standard

# Configure Log Analytics workspace for Defender
az security workspace-setting create \
  --name default \
  --target-workspace "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}"

# Enable vulnerability assessment for VMs
az security auto-provisioning-setting update \
  --auto-provision On \
  --name default

# Continuous export to Log Analytics (security alerts, recommendations)
az security automation create \
  --name ExportSecurityAlertsToLogAnalytics \
  --location eastus \
  --resource-group rg-security \
  --actions '[{
    "actionType": "Workspace",
    "workspaceResourceId": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}"
  }]' \
  --scopes '[{
    "scopePath": "/subscriptions/{subscription-id}"
  }]' \
  --sources '[{
    "eventSource": "Alerts",
    "ruleSets": []
  }]'
```

**Explanation**: Microsoft Defender for Cloud provides threat protection for VMs, App Services, SQL, Storage, Key Vault, Containers. Standard tier (paid) enables advanced features (vulnerability assessment, JIT VM access, adaptive application controls). Defender alerts exported to Log Analytics for centralized monitoring. Compliance dashboard shows adherence to regulatory standards (PCI-DSS, HIPAA, ISO 27001). Security recommendations prioritized by severity (high, medium, low).

---

## Example 6: Security Headers (Content-Security-Policy, HSTS, X-Frame-Options)

**Pattern**: Configure HTTP security headers to mitigate common web vulnerabilities (XSS, clickjacking, man-in-the-middle attacks).

**When to Use**: Any web application (SPAs, APIs with CORS) exposed to internet—prevents XSS, clickjacking, MIME-sniffing attacks.

```csharp
// Program.cs (ASP.NET Core middleware)
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

// Trust forwarded headers (when behind Azure Front Door, App Gateway, or Load Balancer)
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();

// Security headers middleware
app.Use(async (context, next) =>
{
    // HSTS (HTTP Strict Transport Security) - force HTTPS for 1 year
    context.Response.Headers.Append("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");

    // Content-Security-Policy - prevent XSS by restricting resource sources
    context.Response.Headers.Append("Content-Security-Policy",
        "default-src 'self'; " +
        "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
        "font-src 'self' https://fonts.gstatic.com; " +
        "img-src 'self' data: https:; " +
        "connect-src 'self' https://api.example.com; " +
        "frame-ancestors 'none'; " +
        "base-uri 'self'; " +
        "form-action 'self';"
    );

    // X-Content-Type-Options - prevent MIME-sniffing
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");

    // X-Frame-Options - prevent clickjacking
    context.Response.Headers.Append("X-Frame-Options", "DENY");

    // Referrer-Policy - control referrer header
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");

    // Permissions-Policy (formerly Feature-Policy) - disable unused browser features
    context.Response.Headers.Append("Permissions-Policy",
        "geolocation=(), " +
        "microphone=(), " +
        "camera=(), " +
        "payment=(), " +
        "usb=()");

    // Remove server header (don't advertise ASP.NET Core version)
    context.Response.Headers.Remove("Server");

    await next();
});

app.UseForwardedHeaders();

app.UseHttpsRedirection(); // Redirect HTTP to HTTPS

app.UseAuthorization();

app.MapControllers();

app.Run();
```

**Azure App Service Configuration (web.config for IIS)**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <httpProtocol>
      <customHeaders>
        <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains; preload" />
        <add name="Content-Security-Policy" value="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;" />
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="DENY" />
        <add name="Referrer-Policy" value="strict-origin-when-cross-origin" />
        <remove name="X-Powered-By" />
      </customHeaders>
    </httpProtocol>
    <rewrite>
      <outboundRules>
        <rule name="Remove Server Header">
          <match serverVariable="RESPONSE_Server" pattern=".+" />
          <action type="Rewrite" value="" />
        </rule>
      </outboundRules>
    </rewrite>
  </system.webServer>
</configuration>
```

**Explanation**: Security headers mitigate OWASP Top 10 vulnerabilities. HSTS forces HTTPS for specified duration (browsers remember, prevent downgrade attacks). Content-Security-Policy (CSP) restricts script/style sources (prevents XSS by blocking inline scripts unless whitelisted). X-Frame-Options prevents clickjacking (embedding site in iframe). X-Content-Type-Options prevents MIME-sniffing (browser honors Content-Type header). Remove Server header to avoid disclosing technology stack.

---

**Note**: All examples integrate with Azure Managed Identity for passwordless authentication, Azure Policy for governance enforcement, and Azure RBAC for fine-grained access control. Adjust resource names, policy definitions, and RBAC roles for your organization's security baseline.
