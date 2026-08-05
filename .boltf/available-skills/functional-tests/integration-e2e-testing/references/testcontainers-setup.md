# Testcontainers Setup for .NET Integration Tests

Complete guide for setting up Testcontainers with SQL Server for .NET integration testing.

## Installation

```bash
dotnet add package Testcontainers
dotnet add package Testcontainers.MsSql
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

## Environment Setup

### Podman Configuration (No License Required)

Create `.testcontainers.properties` in your project root:

```text
# Configure Testcontainers to use Podman instead of Docker
# Format: npipe://./pipe/<podman-pipe-name>
docker.host=npipe://./pipe/podman-machine-default
```

### Docker Configuration

Ensure Docker/Podman is running:

```bash
# Linux/macOS
sudo systemctl start docker

# Windows - Start Docker Desktop or Podman

# Verify
docker ps  # or: podman ps
```

## Base Test Class with IAsyncLifetime

```csharp
// File: tests/Tests.Shared/IntegrationTestBase.cs

using Testcontainers.MsSql;
using Microsoft.EntityFrameworkCore;
using Xunit;

public abstract class IntegrationTestBase : IAsyncLifetime
{
    private MsSqlContainer? _mssqlContainer;
    protected DbContextOptions<YourDbContext>? DbContextOptions;
    protected string? ConnectionString;

    public async Task InitializeAsync()
    {
        // Start SQL Server container
        _mssqlContainer = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong!Passw0rd")
            .WithPortBinding(1433, true) // Random host port
            .WithCleanUp(true) // Auto-cleanup on dispose
            .Build();

        await _mssqlContainer.StartAsync();

        // Get connection string
        ConnectionString = _mssqlContainer.GetConnectionString();

        // Configure DbContext with container connection string
        DbContextOptions = new DbContextOptionsBuilder<YourDbContext>()
            .UseSqlServer(ConnectionString)
            .EnableSensitiveDataLogging() // For debugging
            .LogTo(Console.WriteLine) // Optional: log queries
            .Options;

        // Run migrations to create schema
        await using var context = new YourDbContext(DbContextOptions);
        await context.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        if (_mssqlContainer != null)
        {
            await _mssqlContainer.StopAsync();
            await _mssqlContainer.DisposeAsync();
        }
    }

    protected YourDbContext CreateDbContext()
    {
        return new YourDbContext(DbContextOptions!);
    }
}
```

## Container Configuration Options

### Timeout Control

```csharp
_mssqlContainer = new MsSqlBuilder()
    .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
    .WithPassword("YourStrong!Passw0rd")
    .WithStartupTimeout(TimeSpan.FromMinutes(2)) // For slow CI environments
    .Build();
```

### Resource Limits

```csharp
_mssqlContainer = new MsSqlBuilder()
    .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
    .WithPassword("YourStrong!Passw0rd")
    .WithResourceMapping(
        new MountConfiguration(
            source: "/path/to/data",
            target: "/var/opt/mssql/data",
            accessMode: AccessMode.ReadWrite))
    .Build();
```

### Environment Variables

```csharp
_mssqlContainer = new MsSqlBuilder()
    .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
    .WithPassword("YourStrong!Passw0rd")
    .WithEnvironment("MSSQL_COLLATION", "SQL_Latin1_General_CP1_CI_AS")
    .WithEnvironment("ACCEPT_EULA", "Y")
    .Build();
```

## Migration Management

### Automatic Migrations on Startup

```csharp
public async Task InitializeAsync()
{
    await _container.StartAsync();

    // Apply all pending migrations
    await using var context = new YourDbContext(DbContextOptions);
    await context.Database.MigrateAsync();

    // Optional: Seed test data
    await SeedTestDataAsync(context);
}

private async Task SeedTestDataAsync(YourDbContext context)
{
    // Add reference data for tests
    if (!await context.Roles.AnyAsync())
    {
        context.Roles.AddRange(
            new Role { Name = "Admin" },
            new Role { Name = "User" }
        );
        await context.SaveChangesAsync();
    }
}
```

### Manual Schema Creation (Alternative)

```csharp
public async Task InitializeAsync()
{
    await _container.StartAsync();

    await using var context = new YourDbContext(DbContextOptions);

    // Option 1: Ensure schema is created (doesn't run migrations)
    await context.Database.EnsureCreatedAsync();

    // Option 2: Execute SQL scripts directly
    await context.Database.ExecuteSqlRawAsync(@"
        CREATE TABLE Users (
            Id INT PRIMARY KEY IDENTITY,
            Email NVARCHAR(255) NOT NULL,
            CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
        );
    ");
}
```

## Performance Optimization

### Container Reuse with xUnit Collections

For test suites with many test classes, reuse containers:

```csharp
// File: tests/Tests.Shared/DatabaseFixture.cs

public class DatabaseFixture : IAsyncLifetime
{
    private MsSqlContainer? _container;
    public string ConnectionString { get; private set; } = string.Empty;

    public async Task InitializeAsync()
    {
        _container = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong!Passw0rd")
            .Build();

        await _container.StartAsync();
        ConnectionString = _container.GetConnectionString();

        // Run migrations once
        var options = new DbContextOptionsBuilder<YourDbContext>()
            .UseSqlServer(ConnectionString)
            .Options;

        await using var context = new YourDbContext(options);
        await context.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        if (_container != null)
        {
            await _container.StopAsync();
            await _container.DisposeAsync();
        }
    }
}

// File: tests/Tests.Shared/DatabaseCollection.cs

[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<DatabaseFixture>
{
    // This class is just a marker for xUnit
}
```

**Usage in test classes**:

```csharp
[Collection("Database")] // Reuses same container
public class UserRepositoryTests
{
    private readonly DatabaseFixture _fixture;

    public UserRepositoryTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task MyTest()
    {
        var options = new DbContextOptionsBuilder<YourDbContext>()
            .UseSqlServer(_fixture.ConnectionString)
            .Options;

        await using var context = new YourDbContext(options);
        // Test logic
    }
}
```

## Troubleshooting

### Issue 1: Container Startup Timeout

**Error**: `Container did not start within timeout`

**Solutions**:

1. Increase timeout:

   ```csharp
   .WithStartupTimeout(TimeSpan.FromMinutes(2))
   ```

2. Wait for SQL Server to be ready:

   ```csharp
   await _container.StartAsync();
   await Task.Delay(TimeSpan.FromSeconds(5)); // Give SQL Server time to initialize
   ```

3. Use wait strategies:

   ```csharp
   .WithWaitStrategy(Wait.ForUnixContainer()
       .UntilPortIsAvailable(1433))
   ```

### Issue 2: Migration Failures

**Error**: `Cannot open database requested by login`

**Solution**: Ensure connection is open before migrating:

```csharp
await using var context = new YourDbContext(DbContextOptions);
await context.Database.OpenConnectionAsync();
await context.Database.MigrateAsync();
```

### Issue 3: Docker Not Available in CI

**Solution**: Install Docker in CI pipeline:

**GitHub Actions**:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      docker:
        image: docker:dind
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
      - name: Run Tests
        run: dotnet test
```

**Azure Pipelines**:

```yaml
pool:
  vmImage: "ubuntu-latest"

steps:
  - task: Docker@2
    displayName: Start Docker
  - task: DotNetCoreCLI@2
    inputs:
      command: "test"
```

### Issue 4: Port Already in Use

**Error**: `Bind for 0.0.0.0:1433 failed: port is already allocated`

**Solution**: Use random port binding:

```csharp
.WithPortBinding(1433, true) // true = assign random host port
```

## Best Practices

### ✅ DO

- ✅ Use `IAsyncLifetime` for container lifecycle management
- ✅ Run `MigrateAsync()` in `InitializeAsync()`
- ✅ Dispose containers properly in `DisposeAsync()`
- ✅ Use random port bindings to avoid conflicts
- ✅ Reuse containers with xUnit Collections for large test suites
- ✅ Use SQL Server 2022-latest image (best compatibility)
- ✅ Enable sensitive data logging for debugging

### ❌ DON'T

- ❌ Share containers between unrelated test suites
- ❌ Forget to call `DisposeAsync()` (resource leaks)
- ❌ Use hardcoded port numbers (conflicts in CI)
- ❌ Skip migrations (schema mismatch with production)
- ❌ Use weak passwords (container startup may fail)
- ❌ Create/dispose containers per test (slow, use Respawn instead)

## Performance Metrics

**Expected Times**: | Operation | Time | Notes | |-----------|------|-------| | Container startup |
5-10s | One-time per test suite | | Migration execution | 1-3s | Depends on migration count | | Test
execution | <1s | Per test with Respawn | | Container cleanup | 1-2s | Automatic with
`.WithCleanUp(true)` |

---

**Next**: See [respawn-usage.md](./respawn-usage.md) for database state management between tests.
