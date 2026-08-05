// Source: tests/Tests.Common/Infrastructure/DatabaseFixture.cs
// Copied here so the skill examples are self-contained.
// DO NOT edit this copy — edit the source file instead.

using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Respawn;
using Xunit;

namespace Tests.Common.Infrastructure;

/// <summary>
/// Generic per-suite database fixture.
///
/// Lifecycle (called inside each test class's IAsyncLifetime):
///   1. InitializeAsync()      — resolves connection string (LocalDB dev / GlobalTestContainers CI)
///   2. EnsureMigrationsAsync() — runs EF migrations once + initialises Respawn (idempotent)
///   3. ResetDatabaseAsync()   — ~200-300ms Respawn reset at START of each test
///   4. CreateDbContext()      — returns a fresh, isolated DbContext per test
///
/// Environment detection:
///   CI=true or USE_TESTCONTAINERS=true  → uses GlobalTestContainers shared SQL Server container
///   otherwise                           → uses LocalDB (no Docker required)
/// </summary>
/// <typeparam name="TContext">The DbContext type for this test suite.</typeparam>
public class DatabaseFixture<TContext> : IAsyncLifetime
    where TContext : DbContext
{
    // Static readonly arrays to avoid per-call allocations (CA1861)
    private static readonly string[] SchemasToInclude = ["dbo"];
    private static readonly Respawn.Graph.Table[] TablesToIgnore =
    [
        new Respawn.Graph.Table("__EFMigrationsHistory") // preserve migration history
    ];

    private Respawner? _respawner;
    private bool _migrationsExecuted;

    /// <summary>
    /// Optional factory for creating DbContext instances.
    /// MUST be set if your DbContext needs dependencies beyond DbContextOptions (e.g. ILogger).
    /// Set this BEFORE calling EnsureMigrationsAsync().
    /// </summary>
    public Func<DbContextOptions<TContext>, TContext>? ContextFactory { get; set; }

    public string ConnectionString { get; private set; } = string.Empty;
    public DbContextOptions<TContext>? DbContextOptions { get; private set; }

    /// <summary>Resolves connection string. Does NOT run migrations (lazy via EnsureMigrationsAsync).</summary>
    public async Task InitializeAsync()
    {
        var useTestcontainers =
            string.Equals(Environment.GetEnvironmentVariable("CI"), "true", StringComparison.Ordinal) ||
            string.Equals(Environment.GetEnvironmentVariable("USE_TESTCONTAINERS"), "true", StringComparison.Ordinal);

        if (useTestcontainers)
        {
            if (!GlobalTestContainers.IsInitialized)
                throw new InvalidOperationException(
                    "GlobalTestContainers not initialized. Ensure the test class uses [Collection(\"Database\")] attribute.");

            ConnectionString = GlobalTestContainers.GetConnectionString();
        }
        else
        {
            // LocalDB: unique database per fixture to avoid cross-suite conflicts
            var dbName = $"PeritecTestDB_{typeof(TContext).Name}_{Guid.NewGuid():N}";
            ConnectionString = $"Server=(localdb)\\mssqllocaldb;Database={dbName};" +
                               "Trusted_Connection=true;ConnectRetryCount=0;MultipleActiveResultSets=true";
        }

        DbContextOptions = new DbContextOptionsBuilder<TContext>()
            .UseSqlServer(ConnectionString)
            .EnableSensitiveDataLogging()
            .Options;

        await Task.CompletedTask;
    }

    /// <summary>
    /// Runs EF migrations and initialises Respawn.
    /// Idempotent — safe to call multiple times.
    /// Call AFTER setting ContextFactory.
    /// </summary>
    public async Task EnsureMigrationsAsync()
    {
        if (_migrationsExecuted) return;

        await using (var ctx = CreateDbContext())
            await ctx.Database.MigrateAsync();

        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();

        _respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
        {
            DbAdapter = DbAdapter.SqlServer,
            SchemasToInclude = SchemasToInclude,
            TablesToIgnore = TablesToIgnore
        });

        _migrationsExecuted = true;
    }

    /// <summary>
    /// Resets DB to clean state via Respawn (~200-300ms).
    /// Call at the START of each test — never at the end.
    /// </summary>
    public async Task ResetDatabaseAsync()
    {
        if (_respawner == null)
            throw new InvalidOperationException("Call EnsureMigrationsAsync() before ResetDatabaseAsync().");

        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();
        await _respawner.ResetAsync(connection);
    }

    /// <summary>Global container lifecycle is managed by GlobalTestContainers — nothing to dispose here.</summary>
    public Task DisposeAsync() => Task.CompletedTask;

    /// <summary>
    /// Creates a new DbContext. Dispose after use (using / await using).
    /// Uses ContextFactory if set; otherwise uses Activator to call the single-parameter constructor.
    /// </summary>
    public TContext CreateDbContext()
    {
        if (DbContextOptions == null)
            throw new InvalidOperationException("Call InitializeAsync() first.");

        if (ContextFactory != null)
            return ContextFactory(DbContextOptions);

        try
        {
            return (TContext)Activator.CreateInstance(typeof(TContext), DbContextOptions)!;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException(
                $"Failed to create {typeof(TContext).Name}. " +
                "Set ContextFactory if the DbContext needs extra constructor arguments.", ex);
        }
    }
}
