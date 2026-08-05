# .NET Aspire Orchestration - Code Examples

> **Progressive Disclosure**: These examples demonstrate .NET Aspire orchestration patterns for building cloud-native distributed applications with service discovery, resource management, and Azure integrations.

---

## Example 1: Basic Aspire AppHost Project

**.NET Aspire AppHost** orchestrates distributed applications by defining projects, resources, and dependencies. The AppHost project references application projects and configures service discovery.

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

// Add API project
var apiService = builder.AddProject<Projects.ApiService>("apiservice");

// Add Web frontend project, referencing API
builder.AddProject<Projects.Web>("webfrontend")
    .WithReference(apiService);

builder.Build().Run();
```

**Key Points**:

- `DistributedApplication.CreateBuilder()` initializes Aspire orchestration
- `AddProject<T>()` registers project references with service discovery
- `WithReference()` configures service-to-service communication via service discovery
- AppHost runs locally with dashboard at `http://localhost:15888` (default)

---

## Example 2: Aspire Service Defaults Configuration

**Aspire Service Defaults** provide consistent observability, health checks, and service discovery configuration across all projects in the application.

```csharp
// ServiceDefaults/Extensions.cs
public static class Extensions
{
    public static IHostApplicationBuilder AddServiceDefaults(this IHostApplicationBuilder builder)
    {
        builder.ConfigureOpenTelemetry();
        builder.AddDefaultHealthChecks();
        builder.Services.AddServiceDiscovery();
        builder.Services.ConfigureHttpClientDefaults(http =>
        {
            // Enable service discovery for HTTP clients
            http.AddServiceDiscovery();
        });

        return builder;
    }

    public static IHostApplicationBuilder ConfigureOpenTelemetry(this IHostApplicationBuilder builder)
    {
        builder.Logging.AddOpenTelemetry(logging =>
        {
            logging.IncludeFormattedMessage = true;
            logging.IncludeScopes = true;
        });

        builder.Services.AddOpenTelemetry()
            .WithMetrics(metrics =>
            {
                metrics.AddAspNetCoreInstrumentation()
                       .AddHttpClientInstrumentation()
                       .AddRuntimeInstrumentation();
            })
            .WithTracing(tracing =>
            {
                tracing.AddAspNetCoreInstrumentation()
                       .AddHttpClientInstrumentation();
            });

        return builder;
    }

    public static IHostApplicationBuilder AddDefaultHealthChecks(this IHostApplicationBuilder builder)
    {
        builder.Services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy(), ["live"]);

        return builder;
    }
}
```

**Using Service Defaults in Projects**:

```csharp
// ApiService/Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add service defaults (observability, health checks, service discovery)
builder.AddServiceDefaults();

builder.Services.AddControllers();

var app = builder.Build();

app.MapDefaultEndpoints(); // Adds /health, /alive endpoints
app.MapControllers();

app.Run();
```

**Key Points**:

- Service Defaults provide observability (OpenTelemetry logs, metrics, traces)
- Automatically configure health checks for liveness/readiness probes
- Enable service discovery for HTTP clients (resolves service names)
- Applied consistently across all Aspire projects

---

## Example 3: Redis Cache Integration

**Aspire Redis Component** adds Redis caching with automatic connection string management and service discovery.

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var apiService = builder.AddProject<Projects.ApiService>("apiservice")
    .WithReference(cache); // Injects Redis connection string

builder.Build().Run();
```

**Consuming Redis in API Service**:

```csharp
// ApiService/Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddRedisClient("cache"); // Connects to "cache" resource

var app = builder.Build();

app.MapGet("/cached-data", async (IConnectionMultiplexer redis) =>
{
    var db = redis.GetDatabase();
    var value = await db.StringGetAsync("my-key");

    if (value.IsNullOrEmpty)
    {
        value = "Hello from cache!";
        await db.StringSetAsync("my-key", value, TimeSpan.FromMinutes(10));
    }

    return value.ToString();
});

app.Run();
```

**Key Points**:

- `AddRedis()` provisions Redis resource (local container or Azure Redis)
- `WithReference()` injects connection string via environment variables
- `AddRedisClient()` configures `IConnectionMultiplexer` dependency injection
- Aspire dashboard shows Redis resource health and connection status

---

## Example 4: PostgreSQL Database Integration

**Aspire PostgreSQL Component** adds database with automatic connection string management.

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .WithPgAdmin() // Optional: Adds pgAdmin UI
    .AddDatabase("catalogdb");

var catalogApi = builder.AddProject<Projects.CatalogApi>("catalogapi")
    .WithReference(postgres); // Injects PostgreSQL connection string

builder.Build().Run();
```

**Consuming PostgreSQL with Entity Framework Core**:

```csharp
// CatalogApi/Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddNpgsqlDbContext<CatalogDbContext>("catalogdb"); // Connects to "catalogdb"

var app = builder.Build();

app.MapGet("/products", async (CatalogDbContext db) =>
{
    return await db.Products.ToListAsync();
});

app.Run();
```

**DbContext Configuration**:

```csharp
// CatalogApi/Data/CatalogDbContext.cs
public class CatalogDbContext : DbContext
{
    public CatalogDbContext(DbContextOptions<CatalogDbContext> options)
        : base(options) { }

    public DbSet<Product> Products => Set<Product>();
}
```

**Key Points**:

- `AddPostgres()` provisions PostgreSQL container or Azure Database for PostgreSQL
- `AddDatabase()` creates named database within PostgreSQL instance
- `WithPgAdmin()` adds pgAdmin UI for database management
- `AddNpgsqlDbContext()` configures EF Core with connection string from Aspire

---

## Example 5: Azure Service Bus Integration

**Aspire Azure Service Bus Component** integrates messaging with Azure Service Bus.

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var messaging = builder.AddAzureServiceBus("messaging");

var orderProcessor = builder.AddProject<Projects.OrderProcessor>("orderprocessor")
    .WithReference(messaging); // Injects Service Bus connection string

var orderApi = builder.AddProject<Projects.OrderApi>("orderapi")
    .WithReference(messaging);

builder.Build().Run();
```

**Publishing Messages**:

```csharp
// OrderApi/Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddAzureServiceBusClient("messaging");

var app = builder.Build();

app.MapPost("/orders", async (Order order, ServiceBusClient client) =>
{
    var sender = client.CreateSender("orders-queue");
    var message = new ServiceBusMessage(JsonSerializer.Serialize(order));
    await sender.SendMessageAsync(message);

    return Results.Created($"/orders/{order.Id}", order);
});

app.Run();
```

**Consuming Messages**:

```csharp
// OrderProcessor/Worker.cs
public class OrderProcessorWorker : BackgroundService
{
    private readonly ServiceBusClient _client;

    public OrderProcessorWorker(ServiceBusClient client)
    {
        _client = client;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var processor = _client.CreateProcessor("orders-queue");

        processor.ProcessMessageAsync += async args =>
        {
            var order = JsonSerializer.Deserialize<Order>(args.Message.Body);
            // Process order
            await args.CompleteMessageAsync(args.Message);
        };

        processor.ProcessErrorAsync += args =>
        {
            // Log error
            return Task.CompletedTask;
        };

        await processor.StartProcessingAsync(stoppingToken);
    }
}
```

**Key Points**:

- `AddAzureServiceBus()` provisions Azure Service Bus namespace (local emulator or production)
- `AddAzureServiceBusClient()` configures `ServiceBusClient` dependency injection
- Supports both queues and topics/subscriptions
- Aspire dashboard shows message throughput and processor health

---

## Example 6: Azure Key Vault Integration

**Aspire Azure Key Vault Component** integrates secrets management with Azure Key Vault.

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var keyVault = builder.AddAzureKeyVault("keyvault");

var apiService = builder.AddProject<Projects.ApiService>("apiservice")
    .WithReference(keyVault); // Injects Key Vault endpoint

builder.Build().Run();
```

**Consuming Secrets**:

```csharp
// ApiService/Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.Configuration.AddAzureKeyVault(
    new Uri(builder.Configuration["ConnectionStrings:keyvault"]!),
    new DefaultAzureCredential());

var app = builder.Build();

app.MapGet("/secret", (IConfiguration config) =>
{
    var secretValue = config["MySecretName"]; // Reads from Key Vault
    return Results.Ok(new { HasSecret = !string.IsNullOrEmpty(secretValue) });
});

app.Run();
```

**Key Points**:

- `AddAzureKeyVault()` provisions Azure Key Vault resource
- `AddAzureKeyVault()` extension integrates Key Vault as configuration provider
- Uses `DefaultAzureCredential` for seamless local dev and production authentication
- Secrets automatically loaded into `IConfiguration`

---

## Example 7: Azure App Configuration Integration

**Aspire Azure App Configuration Component** provides centralized configuration management with feature flags.

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var appConfig = builder.AddAzureAppConfiguration("appconfig");

var webApp = builder.AddProject<Projects.WebApp>("webapp")
    .WithReference(appConfig); // Injects App Configuration endpoint

builder.Build().Run();
```

**Consuming Configuration**:

```csharp
// WebApp/Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.Configuration.AddAzureAppConfiguration(options =>
{
    options.Connect(builder.Configuration["ConnectionStrings:appconfig"]!)
        .ConfigureRefresh(refresh =>
        {
            refresh.Register("Settings:Sentinel", refreshAll: true)
                   .SetCacheExpiration(TimeSpan.FromSeconds(30));
        })
        .UseFeatureFlags(ff =>
        {
            ff.CacheExpirationInterval = TimeSpan.FromSeconds(30);
        });
});

builder.Services.AddAzureAppConfiguration();

var app = builder.Build();

app.UseAzureAppConfiguration(); // Enables configuration refresh middleware

app.MapGet("/config", (IConfiguration config) =>
{
    return new
    {
        Setting = config["Settings:MyKey"],
        FeatureEnabled = config["FeatureManagement:MyFeature"]
    };
});

app.Run();
```

**Key Points**:

- `AddAzureAppConfiguration()` provisions Azure App Configuration resource
- `ConfigureRefresh()` enables dynamic configuration updates without redeployment
- `UseFeatureFlags()` integrates feature flag management
- `UseAzureAppConfiguration()` middleware refreshes configuration based on cache expiration

---

## Example 8: Local Development Dashboard

**Aspire Dashboard** provides real-time observability for local development, showing resources, logs, traces, and metrics.

**Accessing the Dashboard**:

```bash
# Run AppHost project
dotnet run --project AppHost

# Dashboard automatically opens at http://localhost:15888
```

**Dashboard Features**:

- **Resources Tab**: Shows all running projects, containers, and Azure resources
  - Health status (green/yellow/red indicators)
  - Resource endpoints (HTTP URLs, connection strings)
  - Start/stop controls for local resources

- **Console Logs Tab**: Real-time structured logs from all projects
  - Filter by log level (Debug, Info, Warning, Error)
  - Search logs across all services
  - Colored output for readability

- **Traces Tab**: Distributed tracing with OpenTelemetry
  - Trace timeline visualization
  - Span details (duration, HTTP status, errors)
  - Service-to-service call graph

- **Metrics Tab**: Real-time metrics from all projects
  - HTTP request rate, latency, errors
  - Runtime metrics (GC, memory, CPU)
  - Custom metrics from application code

**Environment Variables for Dashboard**:

```json
// launchSettings.json (AppHost project)
{
  "profiles": {
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "applicationUrl": "https://localhost:17288;http://localhost:15888",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "DOTNET_DASHBOARD_OTLP_ENDPOINT_URL": "http://localhost:18889",
        "DOTNET_RESOURCE_SERVICE_ENDPOINT_URL": "http://localhost:20888"
      }
    }
  }
}
```

**Key Points**:

- Dashboard runs automatically when starting AppHost
- No additional configuration required for basic observability
- OpenTelemetry instrumentation provided by Service Defaults
- Dashboard URL configurable via environment variables

---

## Additional Patterns

### Multi-Environment Configuration

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var isDevelopment = builder.Environment.IsDevelopment();

// Use local containers in development, Azure resources in production
var cache = isDevelopment
    ? builder.AddRedis("cache")
    : builder.AddAzureRedis("cache");

var apiService = builder.AddProject<Projects.ApiService>("apiservice")
    .WithReference(cache);

builder.Build().Run();
```

### Resource Dependencies

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .AddDatabase("mydb");

var migration = builder.AddProject<Projects.DbMigrator>("dbmigrator")
    .WithReference(postgres)
    .WaitFor(postgres); // Wait for database to be ready

var api = builder.AddProject<Projects.Api>("api")
    .WithReference(postgres)
    .WaitForCompletion(migration); // Wait for migrations to complete

builder.Build().Run();
```

### Custom Resource Connections

```csharp
// AppHost/Program.cs
var builder = DistributedApplication.CreateBuilder(args);

var customResource = builder.AddResource(new ExternalResource("external-api"))
    .WithAnnotation(new EndpointAnnotation(
        name: "https",
        protocol: "https",
        uriScheme: "https",
        targetPort: 443))
    .WithEnvironment("BaseUrl", "https://api.example.com");

var api = builder.AddProject<Projects.Api>("api")
    .WithReference(customResource);

builder.Build().Run();
```

---

These examples demonstrate .NET Aspire's powerful orchestration capabilities for building distributed applications with consistent patterns, integrated observability, and seamless local-to-cloud deployment.
