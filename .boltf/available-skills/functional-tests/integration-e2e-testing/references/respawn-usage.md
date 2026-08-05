# Respawn: Database State Management for Integration Tests

Respawn is a library that intelligently resets SQL Server databases to a clean state without
recreating the schema. It's the **fastest** way to achieve test isolation.

## Why Use Respawn?

### Performance Comparison

**Without Respawn** (slower approaches):

| Approach                 | Time Per Test | Issues                          |
| ------------------------ | ------------- | ------------------------------- |
| Drop/recreate database   | 5-10s         | Schema recreation overhead      |
| New container per test   | 3-5s          | Startup time waste              |
| Truncate tables manually | 2s            | Foreign key constraint failures |
| Delete all data          | 1-2s          | Must handle FK order manually   |

**With Respawn** (optimal):

| Approach                       | Time Per Test | Benefits                 |
| ------------------------------ | ------------- | ------------------------ |
| **Respawn per test**           | **~0.5s**     | ✅ Automatic FK handling |
| **Respawn + shared container** | **~0.3s**     | ✅ Preserves schema      |

### Key Benefits

- ✅ **Fast**: Resets database in ~100-500ms
- ✅ **Smart**: Handles foreign key constraints automatically
- ✅ **Safe**: Preserves schema and migrations
- ✅ **Configurable**: Ignore specific tables/schemas
- ✅ **Reliable**: Maintains referential integrity

## Installation

```bash
dotnet add package Respawn --version 6.2.1
dotnet add package Microsoft.Data.SqlClient
```

## Basic Integration with Testcontainers

### Enhanced IntegrationTestBase

```csharp
// File: tests/Tests.Shared/IntegrationTestBase.cs

using Respawn;
using Testcontainers.MsSql;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using Xunit;

public abstract class IntegrationTestBase : IAsyncLifetime
{
    private MsSqlContainer? _mssqlContainer;
    private Respawner? _respawner;
    private string? _connectionString;

    protected DbContextOptions<YourDbContext>? DbContextOptions;

    public async Task InitializeAsync()
    {
        // 1. Start SQL Server container
        _mssqlContainer = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong!Passw0rd")
            .Build();

        await _mssqlContainer.StartAsync();
        _connectionString = _mssqlContainer.GetConnectionString();

        // 2. Configure DbContext
        DbContextOptions = new DbContextOptionsBuilder<YourDbContext>()
            .UseSqlServer(_connectionString)
            .Options;

        // 3. Run migrations ONCE
        await using var context = new YourDbContext(DbContextOptions);
        await context.Database.MigrateAsync();

        // 4. Initialize Respawn AFTER migrations
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        _respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
        {
            DbAdapter = DbAdapter.SqlServer, // REQUIRED
            SchemasToInclude = new[] { "dbo" },
            TablesToIgnore = new[]
            {
                new Table("__EFMigrationsHistory") // Preserve migration history
            }
        });
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

    /// <summary>
    /// Resets database to clean state. Call at START of each test.
    /// </summary>
    protected async Task ResetDatabaseAsync()
    {
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        await _respawner!.ResetAsync(connection);
    }
}
```

## Usage in Tests

### ✅ Correct: Reset at START of Test

```csharp
public class UserRepositoryTests : IntegrationTestBase
{
    [Fact]
    public async Task SaveUser_ShouldPersistToDatabase()
    {
        // ✅ RESET AT START - Clean state guaranteed
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var repository = new UserRepository(context);

        var user = Usuario.Create(
            new Email("test@example.com"),
            new FullName("Test", "User"),
            TenantId.Create(Guid.NewGuid())
        );

        // Act
        await repository.SaveAsync(user);
        await context.SaveChangesAsync();

        // Assert
        var savedUser = await repository.GetByIdAsync(user.Id);
        savedUser.Should().NotBeNull();
        savedUser!.Email.Value.Should().Be("test@example.com");
    }

    [Fact]
    public async Task GetAllUsers_WithMultipleUsers_ReturnsAll()
    {
        // ✅ RESET AT START - No data from previous test
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var repository = new UserRepository(context);

        // Arrange - Create 3 users
        var users = new[]
        {
            Usuario.Create(new Email("user1@test.com"), new FullName("User", "One"), TenantId.Create(Guid.NewGuid())),
            Usuario.Create(new Email("user2@test.com"), new FullName("User", "Two"), TenantId.Create(Guid.NewGuid())),
            Usuario.Create(new Email("user3@test.com"), new FullName("User", "Three"), TenantId.Create(Guid.NewGuid()))
        };

        foreach (var user in users)
        {
            await repository.SaveAsync(user);
        }
        await context.SaveChangesAsync();

        // Act
        var allUsers = await repository.GetAllAsync();

        // Assert
        allUsers.Should().HaveCount(3);
    }
}
```

### ❌ Incorrect: Reset at END of Test

```csharp
[Fact]
public async Task BadTest()
{
    // Test logic
    await using var context = CreateDbContext();
    context.Users.Add(new User { Email = "test@test.com" });
    await context.SaveChangesAsync();

    // ❌ WRONG - If test fails, next test gets dirty data!
    await ResetDatabaseAsync();
}
```

## Advanced Configuration

### Preserving Seed Data

```csharp
_respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
{
    DbAdapter = DbAdapter.SqlServer,
    SchemasToInclude = new[] { "dbo" },
    TablesToIgnore = new[]
    {
        new Table("__EFMigrationsHistory"),
        new Table("Roles"),        // Preserve seed data
        new Table("Permissions"),  // Preserve seed data
        new Table("Countries")     // Preserve reference data
    }
});
```

### Ignoring Specific Schemas

```csharp
_respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
{
    DbAdapter = DbAdapter.SqlServer,
    SchemasToInclude = new[] { "dbo" },        // Only reset 'dbo' schema
    SchemasToExclude = new[] { "audit", "log" } // Keep audit/log data
});
```

### Checkpoint Customization

```csharp
// Create once, reuse multiple times with different checkpoints
var checkpoint = await Respawner.CreateAsync(connection, new RespawnerOptions
{
    DbAdapter = DbAdapter.SqlServer,
    TablesToIgnore = new[] { new Table("__EFMigrationsHistory") }
});

// Reset with custom checkpoint
await checkpoint.ResetAsync(connection);
```

## Shared Container Pattern (Optimal Performance)

For test suites with 20+ tests, use shared container + Respawn:

```csharp
// File: tests/Tests.Shared/DatabaseFixture.cs

public class DatabaseFixture : IAsyncLifetime
{
    private MsSqlContainer? _container;
    private Respawner? _respawner;

    public string ConnectionString { get; private set; } = string.Empty;
    public DbContextOptions<YourDbContext> DbContextOptions { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        // Start container ONCE for entire test suite
        _container = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong!Passw0rd")
            .Build();

        await _container.StartAsync();
        ConnectionString = _container.GetConnectionString();

        // Configure DbContext
        DbContextOptions = new DbContextOptionsBuilder<YourDbContext>()
            .UseSqlServer(ConnectionString)
            .Options;

        // Run migrations ONCE
        await using var context = new YourDbContext(DbContextOptions);
        await context.Database.MigrateAsync();

        // Initialize Respawn ONCE
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();

        _respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
        {
            DbAdapter = DbAdapter.SqlServer,
            SchemasToInclude = new[] { "dbo" },
            TablesToIgnore = new[] { new Table("__EFMigrationsHistory") }
        });
    }

    public async Task DisposeAsync()
    {
        if (_container != null)
        {
            await _container.StopAsync();
            await _container.DisposeAsync();
        }
    }

    public async Task ResetDatabaseAsync()
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();
        await _respawner!.ResetAsync(connection);
    }
}

// Collection definition
[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<DatabaseFixture> { }
```

**Usage**:

```csharp
[Collection("Database")] // Shared container
public class UserTests
{
    private readonly DatabaseFixture _fixture;

    public UserTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task Test1()
    {
        await _fixture.ResetDatabaseAsync(); // Reset to clean state

        await using var context = new YourDbContext(_fixture.DbContextOptions);
        // Test logic
    }

    [Fact]
    public async Task Test2()
    {
        await _fixture.ResetDatabaseAsync(); // Each test gets clean state

        await using var context = new YourDbContext(_fixture.DbContextOptions);
        // Test logic
    }
}
```

## Troubleshooting

### Issue 1: Respawn.ResetAsync() Hangs

**Cause**: Open transactions or unclosed connections

**Solution**: Ensure DbContext is disposed before reset

```csharp
[Fact]
public async Task MyTest()
{
    await ResetDatabaseAsync();

    // ✅ Use 'using' to ensure disposal
    await using (var context = CreateDbContext())
    {
        // Test logic
        await context.SaveChangesAsync();
    } // Context disposed here

    // Now safe to reset if needed
}
```

### Issue 2: Foreign Key Constraint Error

**Cause**: Incorrect RespawnerOptions configuration

**Solution**: Ensure `DbAdapter.SqlServer` is specified

```csharp
// ❌ Wrong - Missing DbAdapter
new RespawnerOptions
{
    SchemasToInclude = new[] { "dbo" }
}

// ✅ Correct
new RespawnerOptions
{
    DbAdapter = DbAdapter.SqlServer, // REQUIRED
    SchemasToInclude = new[] { "dbo" }
}
```

### Issue 3: Seed Data Disappears

**Cause**: Respawn deletes all data by default

**Solution**: Preserve seed tables

```csharp
new RespawnerOptions
{
    DbAdapter = DbAdapter.SqlServer,
    TablesToIgnore = new[]
    {
        new Table("__EFMigrationsHistory"),
        new Table("Roles"),      // Preserve
        new Table("Permissions") // Preserve
    }
}
```

### Issue 4: Performance Still Slow

**Cause**: Creating new container per test

**Solution**: Use shared container pattern (see above)

**Performance Impact**:

- ❌ New container per test: ~5s each
- ✅ Shared container + Respawn: ~0.3s each

## Best Practices

### ✅ DO

- ✅ Call `ResetDatabaseAsync()` at the **START** of each test
- ✅ Initialize Respawner **AFTER** running migrations
- ✅ Specify `DbAdapter.SqlServer` in RespawnerOptions
- ✅ Preserve `__EFMigrationsHistory` table
- ✅ Use shared container + Respawn for large test suites (20+ tests)
- ✅ Dispose DbContext before calling ResetAsync()
- ✅ Preserve seed/reference data tables as needed

### ❌ DON'T

- ❌ Reset at END of test (reset at START instead)
- ❌ Use Respawn on production databases (Testcontainers only!)
- ❌ Forget to specify `DbAdapter.SqlServer`
- ❌ Reset inside active transactions
- ❌ Create new container per test (use shared container)
- ❌ Skip disposing DbContext before reset

## Performance Benchmarks

**Scenario**: 50 integration tests in a test suite

| Approach                          | Setup Time | Per Test | Total Time | Notes          |
| --------------------------------- | ---------- | -------- | ---------- | -------------- |
| Container per test                | 10s        | 5s       | ~250s      | Slow, wasteful |
| Shared container + manual cleanup | 10s        | 2s       | ~110s      | FK issues      |
| **Shared container + Respawn**    | **10s**    | **0.3s** | **~25s**   | **Optimal** ✅ |

---

**Next**: See [test-patterns.md](./test-patterns.md) for complete test examples.
