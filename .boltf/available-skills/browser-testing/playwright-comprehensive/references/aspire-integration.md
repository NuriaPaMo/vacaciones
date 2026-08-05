# .NET Aspire Integration - E2E Testing with Distributed Applications

## Overview

.NET Aspire enables orchestration of multi-service distributed applications during E2E testing. Playwright integrates with Aspire's Testing.Agent library to automatically start, configure, and tear down backend services.

## Setup

### Installation

```bash
dotnet add package Aspire.Hosting.Testing
dotnet add package Microsoft.Playwright
dotnet add package Microsoft.Playwright.NUnit
```

### Project Structure

```text
YourApp.Tests/
├── AppHost/
│   └── Program.cs              # Aspire application model
├── E2ETests/
│   ├── PlaywrightTests.cs      # E2E test suite
│   └── Fixtures/
│       └── AspireFixture.cs    # Aspire + Playwright fixture
└── YourApp.Tests.csproj
```

## Basic Aspire Integration

### Distributed Application Factory

```csharp
using Aspire.Hosting;
using Aspire.Hosting.Testing;
using Microsoft.Playwright;

public class AspirePlaywrightFixture : IAsyncLifetime
{
    private DistributedApplication? _app;
    private IPlaywright? _playwright;
    private IBrowser? _browser;

    public DistributedApplication App => _app ?? throw new InvalidOperationException("App not initialized");
    public IBrowser Browser => _browser ?? throw new InvalidOperationException("Browser not initialized");

    public async Task InitializeAsync()
    {
        // Build and start Aspire application
        var appHost = await DistributedApplicationTestingBuilder
            .CreateAsync<Projects.AppHost>();

        _app = await appHost.BuildAsync();
        await _app.StartAsync();

        // Initialize Playwright
        _playwright = await Playwright.CreateAsync();
        _browser = await _playwright.Chromium.LaunchAsync(new()
        {
            Headless = true
        });
    }

    public async Task DisposeAsync()
    {
        if (_browser != null)
            await _browser.DisposeAsync();

        _playwright?.Dispose();

        if (_app != null)
            await _app.DisposeAsync();
    }
}
```

### Test Class with Fixture

```csharp
[TestFixture]
public class E2ETests : IClassFixture<AspirePlaywrightFixture>
{
    private readonly AspirePlaywrightFixture _fixture;

    public E2ETests(AspirePlaywrightFixture fixture)
    {
        _fixture = fixture;
    }

    [Test]
    public async Task CompleteUserFlow()
    {
        // Get frontend URL from Aspire
        var frontendUrl = _fixture.App.GetEndpoint("frontend").ToString();

        // Create page and navigate
        var page = await _fixture.Browser.NewPageAsync();
        await page.GotoAsync(frontendUrl);

        // Interact with UI
        await page.FillAsync("[data-testid='username']", "testuser");
        await page.FillAsync("[data-testid='password']", "password123");
        await page.ClickAsync("[data-testid='login']");

        // Verify
        await Expect(page).ToHaveURLAsync(new Regex(".*/dashboard"));
    }
}
```

## Advanced Aspire Patterns

### Service Dependency Management

```csharp
public class AppHostBuilder
{
    public static IDistributedApplicationBuilder CreateBuilder()
    {
        var builder = DistributedApplication.CreateBuilder();

        // Database
        var postgres = builder.AddPostgres("postgres")
            .WithPgAdmin();

        var database = postgres.AddDatabase("appdb");

        // Cache
        var redis = builder.AddRedis("cache");

        // Backend API
        var api = builder.AddProject<Projects.BackendApi>("api")
            .WithReference(database)
            .WithReference(redis)
            .WithEnvironment("ASPNETCORE_ENVIRONMENT", "Testing");

        // Frontend
        builder.AddNpmApp("frontend", "../../frontend")
            .WithReference(api)
            .WithHttpEndpoint(port: 4200);

        return builder;
    }
}

// Usage in tests
public async Task InitializeAsync()
{
    var builder = AppHostBuilder.CreateBuilder();
    _app = await builder.Build().StartAsync();
}
```

### Health Check Verification

```csharp
[Test]
public async Task AllServicesHealthy()
{
    // Verify all services started successfully
    var resources = _fixture.App.Resources;

    foreach (var resource in resources)
    {
        if (resource is IResourceWithEndpoints endpointResource)
        {
            var endpoints = endpointResource.GetEndpoints();

            foreach (var endpoint in endpoints)
            {
                var healthUrl = $"{endpoint}/health";

                using var client = new HttpClient();
                var response = await client.GetAsync(healthUrl);

                Assert.That(response.IsSuccessStatusCode, Is.True,
                    $"Service {resource.Name} health check failed");
            }
        }
    }
}
```

### Database Seeding for Tests

```csharp
public class DatabaseSeeder
{
    public static async Task SeedTestData(DistributedApplication app)
    {
        var dbConnectionString = await app.GetConnectionStringAsync("appdb");

        await using var connection = new NpgsqlConnection(dbConnectionString);
        await connection.OpenAsync();

        // Seed test users
        await using var cmd = new NpgsqlCommand(
            @"INSERT INTO users (id, username, email, password_hash)
              VALUES (@id, @username, @email, @password)
              ON CONFLICT (id) DO NOTHING",
            connection);

        cmd.Parameters.AddWithValue("id", Guid.NewGuid());
        cmd.Parameters.AddWithValue("username", "testuser");
        cmd.Parameters.AddWithValue("email", "test@example.com");
        cmd.Parameters.AddWithValue("password", BCrypt.Net.BCrypt.HashPassword("password123"));

        await cmd.ExecuteNonQueryAsync();
    }
}

// In fixture initialization
public async Task InitializeAsync()
{
    _app = await appHost.BuildAsync();
    await _app.StartAsync();

    // Seed database before tests
    await DatabaseSeeder.SeedTestData(_app);

    // ... initialize Playwright
}
```

## Agent Coordination

### Multi-Service Workflow Testing

```csharp
[Test]
public async Task OrderProcessingWorkflow()
{
    var frontendUrl = _fixture.App.GetEndpoint("frontend").ToString();
    var apiUrl = _fixture.App.GetEndpoint("api").ToString();

    var page = await _fixture.Browser.NewPageAsync();

    // 1. User places order via frontend
    await page.GotoAsync($"{frontendUrl}/products");
    await page.ClickAsync("[data-testid='add-to-cart-1']");
    await page.ClickAsync("[data-testid='checkout']");
    await page.FillAsync("[data-testid='card-number']", "4111111111111111");
    await page.ClickAsync("[data-testid='submit-order']");

    // 2. Verify order created in backend
    var orderId = await page.Locator("[data-testid='order-id']").TextContentAsync();

    using var httpClient = new HttpClient();
    var orderResponse = await httpClient.GetAsync($"{apiUrl}/api/orders/{orderId}");
    Assert.That(orderResponse.IsSuccessStatusCode, Is.True);

    var order = await orderResponse.Content.ReadFromJsonAsync<Order>();
    Assert.That(order.Status, Is.EqualTo("Pending"));

    // 3. Simulate payment processing (background service)
    await Task.Delay(2000); // Wait for payment processor

    // 4. Verify order updated
    orderResponse = await httpClient.GetAsync($"{apiUrl}/api/orders/{orderId}");
    order = await orderResponse.Content.ReadFromJsonAsync<Order>();
    Assert.That(order.Status, Is.EqualTo("Confirmed"));

    // 5. Verify UI reflects updated status
    await page.ReloadAsync();
    var status = await page.Locator("[data-testid='order-status']").TextContentAsync();
    Assert.That(status, Does.Contain("Confirmed"));
}
```

### Service Communication Testing

```csharp
[Test]
public async Task VerifyServiceCommunication()
{
    var apiUrl = _fixture.App.GetEndpoint("api").ToString();
    var frontendUrl = _fixture.App.GetEndpoint("frontend").ToString();

    // Monitor network requests
    var page = await _fixture.Browser.NewPageAsync();
    var apiCalls = new List<string>();

    page.Request += (_, request) =>
    {
        if (request.Url.StartsWith(apiUrl))
        {
            apiCalls.Add($"{request.Method} {request.Url}");
        }
    };

    await page.GotoAsync(frontendUrl);
    await page.ClickAsync("[data-testid='load-data']");

    // Wait for API call to complete
    await page.WaitForResponseAsync(response =>
        response.Url.Contains("/api/data") && response.Ok);

    // Verify expected API calls were made
    Assert.That(apiCalls, Does.Contain($"GET {apiUrl}/api/data"));
}
```

## Service Health Checks

### Wait for Services Ready

```csharp
public static class AspireExtensions
{
    public static async Task WaitForServicesReadyAsync(
        this DistributedApplication app,
        TimeSpan? timeout = null)
    {
        timeout ??= TimeSpan.FromSeconds(30);
        var deadline = DateTime.UtcNow + timeout.Value;

        var resources = app.Resources
            .OfType<IResourceWithEndpoints>()
            .ToList();

        while (DateTime.UtcNow < deadline)
        {
            var allReady = true;

            foreach (var resource in resources)
            {
                try
                {
                    var endpoint = resource.GetEndpoints().FirstOrDefault();
                    if (endpoint == null) continue;

                    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(2) };
                    var response = await client.GetAsync($"{endpoint}/health");

                    if (!response.IsSuccessStatusCode)
                    {
                        allReady = false;
                        break;
                    }
                }
                catch
                {
                    allReady = false;
                    break;
                }
            }

            if (allReady) return;

            await Task.Delay(500);
        }

        throw new TimeoutException("Services did not become ready within timeout period");
    }
}

// Usage
public async Task InitializeAsync()
{
    _app = await appHost.BuildAsync();
    await _app.StartAsync();
    await _app.WaitForServicesReadyAsync();

    // Now safe to run tests
}
```

## Environment Configuration

### Test-Specific Configuration

```csharp
var builder = DistributedApplication.CreateBuilder();

var api = builder.AddProject<Projects.BackendApi>("api")
    .WithEnvironment("ASPNETCORE_ENVIRONMENT", "Testing")
    .WithEnvironment("ConnectionStrings__Redis", "localhost:6379")
    .WithEnvironment("FeatureFlags__NewCheckout", "true")
    .WithEnvironment("Logging__LogLevel__Default", "Debug");
```

### Configuration Override

```csharp
var builder = DistributedApplication.CreateBuilder();

builder.Configuration["ApiSettings:Timeout"] = "30";
builder.Configuration["ApiSettings:RetryCount"] = "3";

var api = builder.AddProject<Projects.BackendApi>("api")
    .WithEnvironment("ApiSettings__Timeout", "30")
    .WithEnvironment("ApiSettings__RetryCount", "3");
```

## Troubleshooting

**Issue: Services not starting**

- Check Aspire dashboard logs
- Verify Docker is running (if using containers)
- Check port conflicts
- Review service health endpoints

**Issue: Tests timeout waiting for services**

- Increase startup timeout in `WaitForServicesReadyAsync`
- Verify all service dependencies are configured
- Check firewall/network policies

**Issue: Playwright cannot reach frontend**

- Verify frontend endpoint in Aspire configuration
- Check that frontend dev server started successfully
- Use `GetEndpoint()` to retrieve dynamic URLs

## Best Practices

- Use `IClassFixture` to share Aspire app across tests in a class
- Seed test data in fixture initialization
- Verify service health before running tests
- Use Aspire's dynamic endpoint resolution
- Clean up test data after each test
- Monitor service logs for debugging
- Test cross-service communication explicitly
- Use environment variables for test-specific configuration
