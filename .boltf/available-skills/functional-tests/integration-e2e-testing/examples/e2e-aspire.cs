// tests/MyService.Tests.E2E/MyFeatureE2ETests.cs
//
// Full-stack C# E2E test using Aspire.Hosting.Testing.
// The entire AppHost (SQL Server → Migrators → APIs) starts ONCE for the collection.
//
// Based on: tests/Tests.Common/Infrastructure/E2ETestBase.cs
// Use for: C# API contract tests, cross-service integration, health checks.
// Prefer Playwright .spec.ts files for UI/browser flows.

using Tests.Common.Infrastructure;
using Xunit;

namespace MyService.Tests.E2E;

/// <summary>
/// Full-stack E2E tests via Aspire AppHost.
///
/// Available HTTP clients (created with Aspire service discovery, no hardcoded URLs):
///   - AuthApiClient       → auth-api
///   - UsuariosApiClient   → gestion-usuarios-api
///   - TestingApiClient    → testing-api (only in E2E environment)
///
/// Cold start: ~60-90s | Warm start: ~20-30s (all tests share the same AppHost instance).
/// </summary>
[Collection("E2E")]
[Trait("Category", "E2E")]
[Trait("Speed", "Slow")]
[Trait("Feature", "MyFeature")]
[Trait("Database", "Required")]
public class MyFeatureE2ETests : E2ETestBase
{
    // ── Health checks (smoke) ────────────────────────────────────────────────

    [Fact]
    [Trait("Type", "HealthCheck")]
    public async Task AuthApi_ShouldBeHealthy()
    {
        var response = await AuthApiClient!.GetAsync("/api/health");
        response.EnsureSuccessStatusCode();
    }

    // ── Business scenarios ───────────────────────────────────────────────────

    [Fact]
    public async Task CreateEntity_ShouldReturnCreated()
    {
        // Reset BOTH databases for worker 0 before the test.
        // Path-based routing: /api/testing/{workerIndex}/reset-and-seed-all
        await TestingApiClient!.PostAsync("/api/testing/0/reset-and-seed-all", null);

        var payload = new StringContent(
            """{"name": "Test Entity"}""",
            System.Text.Encoding.UTF8,
            "application/json");

        var response = await AuthApiClient!.PostAsync("/api/my-resource", payload);

        response.StatusCode.Should().Be(System.Net.HttpStatusCode.Created);
    }

    [Fact]
    public async Task GetEntity_WithInvalidId_ShouldReturn404()
    {
        await TestingApiClient!.PostAsync("/api/testing/0/reset-and-seed-all", null);

        var response = await AuthApiClient!.GetAsync($"/api/my-resource/{Guid.NewGuid()}");

        response.StatusCode.Should().Be(System.Net.HttpStatusCode.NotFound);
    }
}
