// Source: tests/Tests.Common/Infrastructure/E2ETestBase.cs
// Copied here so the skill examples are self-contained.
// DO NOT edit this copy — edit the source file instead.

using Aspire.Hosting;
using Aspire.Hosting.Testing;
using Xunit;

namespace Tests.Common.Infrastructure;

/// <summary>
/// Base class for C# E2E tests that require the full Aspire AppHost running.
/// Starts SQL Server → Migrators → APIs and waits for health checks before tests run.
///
/// Performance:
///   Cold start: ~60-90s (container pull + migrations)
///   Warm start: ~20-30s (container reuse)
///   Tests share the SAME AppHost instance within a collection.
///
/// Available HTTP clients (Aspire service discovery — no hardcoded URLs):
///   AuthApiClient      → "auth-api"
///   UsuariosApiClient  → "gestion-usuarios-api"
///   TestingApiClient   → "testing-api"  (E2E environment only)
///
/// Usage:
///   [Collection("E2E")]
///   [Trait("Category", "E2E")]
///   [Trait("Speed", "Slow")]
///   public class MyE2ETests : E2ETestBase { … }
/// </summary>
public class E2ETestBase : IAsyncLifetime
{
    protected DistributedApplication? App { get; private set; }
    protected HttpClient? AuthApiClient { get; private set; }
    protected HttpClient? UsuariosApiClient { get; private set; }
    protected HttpClient? TestingApiClient { get; private set; }

    public virtual async Task InitializeAsync()
    {
        var appHost = await DistributedApplicationTestingBuilder
            .CreateAsync<Projects.Peritec_AppHost>();

        App = await appHost.BuildAsync();
        await App.StartAsync();

        // Wait for critical services to be healthy (includes DB migrations)
        await App.ResourceNotifications.WaitForResourceHealthyAsync("auth-api");
        await App.ResourceNotifications.WaitForResourceHealthyAsync("gestion-usuarios-api");
        await App.ResourceNotifications.WaitForResourceHealthyAsync("testing-api");

        AuthApiClient = App.CreateHttpClient("auth-api");
        UsuariosApiClient = App.CreateHttpClient("gestion-usuarios-api");
        TestingApiClient = App.CreateHttpClient("testing-api");
    }

    public virtual async Task DisposeAsync()
    {
        AuthApiClient?.Dispose();
        UsuariosApiClient?.Dispose();
        TestingApiClient?.Dispose();

        if (App != null)
        {
            await App.StopAsync();
            await App.DisposeAsync();
        }
    }
}

/// <summary>
/// xUnit collection: all E2E test classes that use this share the same AppHost instance.
/// </summary>
[CollectionDefinition("E2E")]
public class E2ECollection : ICollectionFixture<E2ETestBase> { }
