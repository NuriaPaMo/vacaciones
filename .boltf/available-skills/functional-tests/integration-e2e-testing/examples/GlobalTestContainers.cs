// Source: tests/Tests.Common/Infrastructure/GlobalTestContainers.cs
// Copied here so the skill examples are self-contained.
// DO NOT edit this copy — edit the source file instead.

using System.Collections.Concurrent;
using Microsoft.Extensions.Logging;
using Testcontainers.MsSql;
using Xunit;

namespace Tests.Common.Infrastructure;

/// <summary>
/// Global shared Testcontainer for SQL Server, reused across ALL tests in the suite.
///
/// Performance Impact:
///   WITHOUT sharing: Each test suite takes 60-90s to start a new container.
///   WITH sharing:    Container starts ONCE (60-90s); all subsequent fixtures are instant.
///
/// Architecture Decision Record: ADR-018
///
/// Usage:
///   1. Create a DatabaseCollection in each test project (see database-collection.cs).
///   2. Apply [Collection("Database")] to test classes.
///   3. Accept GlobalTestContainers as a constructor parameter (injected by xUnit).
///   4. Call GlobalTestContainers.GetConnectionString() from DatabaseFixture.
/// </summary>
public class GlobalTestContainers : IAsyncLifetime
{
    private static readonly SemaphoreSlim Lock = new(1, 1);
    private static MsSqlContainer? _sqlContainer;
    private static string? _connectionString;
    private static readonly ConcurrentDictionary<string, byte> RegisteredCollections = new();

    private readonly ILogger<GlobalTestContainers>? _logger;

    /// <summary>Gets the shared SQL Server connection string (available after InitializeAsync).</summary>
    public static string GetConnectionString()
    {
        if (string.IsNullOrEmpty(_connectionString))
            throw new InvalidOperationException(
                "Global test containers not initialized. Ensure tests use [Collection(\"Database\")] attribute.");
        return _connectionString;
    }

    /// <summary>Indicates whether the global container is already running.</summary>
    public static bool IsInitialized => _sqlContainer != null && !string.IsNullOrEmpty(_connectionString);

    /// <summary>
    /// xUnit requires exactly ONE public constructor for collection fixtures.
    /// Logger is null because xUnit does not support DI in fixtures.
    /// </summary>
    public GlobalTestContainers() => _logger = null;

    /// <summary>
    /// Starts the shared SQL Server container ONCE per test run.
    /// Thread-safe via SemaphoreSlim — subsequent calls are no-ops.
    /// </summary>
    public async Task InitializeAsync()
    {
        await Lock.WaitAsync();
        try
        {
            if (_sqlContainer != null) return; // already running

            _sqlContainer = new MsSqlBuilder()
                .WithImage("mcr.microsoft.com/azure-sql-edge:latest")
                .WithPassword("YourStrong!Passw0rd123")
                .WithEnvironment("ACCEPT_EULA", "Y")
                .WithEnvironment("MSSQL_PID", "Developer")
                .WithPortBinding(1433, true) // Random host port to avoid conflicts
                .WithCleanUp(false)          // We manage the lifecycle manually
                .WithAutoRemove(true)
                .Build();

            await _sqlContainer.StartAsync();
            _connectionString = _sqlContainer.GetConnectionString();
        }
        finally
        {
            Lock.Release();
        }
    }

    /// <summary>
    /// Container stays alive for test reuse; xUnit calls this after ALL tests complete.
    /// </summary>
    public Task DisposeAsync() => Task.CompletedTask;

    /// <summary>Explicitly stops and disposes the container. Call only at the very end of all test execution.</summary>
    public static async Task ShutdownAsync()
    {
        await Lock.WaitAsync();
        try
        {
            if (_sqlContainer != null)
            {
                await _sqlContainer.StopAsync();
                await _sqlContainer.DisposeAsync();
                _sqlContainer = null;
                _connectionString = null;
            }
        }
        finally
        {
            Lock.Release();
        }
    }
}
