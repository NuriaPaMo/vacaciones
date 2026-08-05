---
name: skill-bolt-aspire-orchestration
description: .NET Aspire AppHost orchestration pattern for distributed multi-service .NET applications. Covers service discovery (https+http:// resolution), ServiceDefaults project (OpenTelemetry, health checks, resilience), observability dashboard, and multi-service coordination. Use when setting up Aspire, orchestrating microservices, configuring service discovery. Triggers => "Aspire orchestration", "AppHost", "distributed .NET", "Aspire project", "service discovery", "microservices .NET", "Aspire dashboard", "multi-service app".
---

# .NET Aspire Orchestration Skill

## Purpose

Guide development of distributed .NET applications using Aspire's AppHost pattern,
service discovery, and built-in observability.

## When to Use

- Multi-service architecture (2+ services)
- Need automatic service discovery between services
- Want built-in observability (OpenTelemetry dashboard)
- Deploying to Azure with unified approach (azd)

## When NOT to Use

- Single-service applications
- Non-.NET services (Aspire is .NET-specific)
- Learning/prototype projects without Docker

## Key Concepts

### 1. AppHost Project

**Purpose**: Orchestrates all services in your solution

**Structure**:

```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Define services
var cache = builder.AddRedis("cache");
var db = builder.AddPostgres("postgres");

var api = builder.AddProject<Projects.Api>("api")
    .WithReference(cache)
    .WithReference(db);

var frontend = builder.AddProject<Projects.Web>("frontend")
    .WithReference(api);

builder.Build().Run();
```

**Key patterns**:

- `AddProject<T>()` - Adds .NET project
- `WithReference()` - Injects service URL via config
- `AddRedis/AddPostgres/AddAzureStorage()` - Adds external resources

### 2. Service Discovery

Services auto-discover each other without hardcoded URLs:

```csharp
// In dependent service (frontend)
builder.Services.AddHttpClient<ApiClient>(client =>
{
    // "api" = service name from AppHost
    client.BaseAddress = new("https+http://api");
});
```

**How it works**:

- AppHost injects config: `"services__api__0": "https://localhost:7001"`
- .NET service discovery resolves `https+http://api` → actual URL
- No environment-specific config files needed

### 3. ServiceDefaults Project

**Purpose**: Shared configuration for all services

**Includes**:

- OpenTelemetry (traces, metrics, logs)
- Health checks (`/health`, `/alive`)
- Service discovery setup
- Resilience patterns (Polly)

**Usage in each service**:

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.AddServiceDefaults(); // Adds OpenTelemetry, health checks, etc.

var app = builder.Build();
app.MapDefaultEndpoints(); // Maps /health, /alive
```

### 4. Observability Dashboard

Access at `http://localhost:15888` when running AppHost:

- **Traces**: Distributed tracing across services
- **Metrics**: Request rates, durations, errors
- **Logs**: Structured logs from all services
- **Resources**: Status of Redis, PostgreSQL, etc.

## Workflows

### Creating AppHost

**When**: At project initialization if use-aspire: true

**Steps**:

1. Create `src/AppHost/AppHost.csproj` from template
2. Add references to all service projects
3. Define services in `Program.cs` using builder pattern
4. Run AppHost to launch all services

**Prompt**:

```text
Create Aspire AppHost project orchestrating:
- API project (backend)
- Web project (frontend)
- Redis cache
- PostgreSQL database
```

### Adding Service to AppHost

**When**: New service added to solution

**Steps**:

1. Add project reference to AppHost.csproj
2. Register in AppHost Program.cs with `AddProject<T>()`
3. Define `WithReference()` dependencies
4. Test with `dotnet run --project AppHost`

**Example**:

```csharp
var worker = builder.AddProject<Projects.BackgroundWorker>("worker")
    .WithReference(cache)
    .WithReference(db);
```

### Service Discovery Setup

**When**: Service needs to call another service

**Steps**:

1. Ensure calling service references ServiceDefaults
2. Use service name from AppHost in HttpClient base address
3. Use `https+http://` scheme for automatic HTTP/HTTPS resolution

**Pattern**:

```csharp
// AppHost defines service name
var api = builder.AddProject<Projects.Api>("api");

// Dependent service uses service name
builder.Services.AddHttpClient<IApiClient, ApiClient>(client =>
{
    client.BaseAddress = new("https+http://api");
});
```

### Deployment to Azure

**When**: Ready to deploy to Azure

**Steps**:

1. Install Azure Developer CLI (`azd`)
2. Run `azd init` from AppHost directory
3. Aspire generates Bicep templates automatically
4. Run `azd up` to provision + deploy

**Generated resources**:

- Azure Container Apps for each service
- Azure Container Registry
- Azure Redis/PostgreSQL if defined
- Application Insights for observability

## Common Patterns

### Adding Azure Resources

```csharp
var storage = builder.AddAzureStorage("storage")
    .AddBlobs("blobs");

var cosmos = builder.AddAzureCosmosDB("cosmos")
    .AddDatabase("maindb");

var servicebus = builder.AddAzureServiceBus("messaging");
```

### Environment-Specific Config

Use `.WithEnvironment()` for per-environment variables:

```csharp
var api = builder.AddProject<Projects.Api>("api")
    .WithEnvironment("ASPNETCORE_ENVIRONMENT", "Production")
    .WithEnvironment("LOG_LEVEL", "Warning");
```

### Waiting for Dependencies

Use `.WaitFor()` to ensure services start in order:

```csharp
var db = builder.AddPostgres("postgres");

var api = builder.AddProject<Projects.Api>("api")
    .WithReference(db)
    .WaitFor(db); // API waits for database to be ready
```

## Integration with Constitution

Aspire orchestration decision should be documented in **Article XX** of constitution:

- **Pattern chosen**: .NET Aspire with AppHost
- **Rationale**: Multi-service architecture benefits from auto-discovery
- **Trade-offs**: Requires Docker Desktop, additional AppHost project
- **Implementation**: AppHost at `src/AppHost/`, ServiceDefaults shared

## References

- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire/)
- [AppHost Overview](https://learn.microsoft.com/dotnet/aspire/fundamentals/app-host-overview)
- [Service Discovery](https://learn.microsoft.com/dotnet/aspire/service-discovery/overview)
- [Azure Deployment](https://learn.microsoft.com/dotnet/aspire/deployment/azure/aca-deployment)
