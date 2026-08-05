// tests/MyService.IntegrationTests/SomeFeature/MyFeatureTests.cs
//
// Based on the real pattern from:
//   tests/Auth.Tests.Integration/Tests/AuditLogging/AuditLoggingTests.cs
//
// Infrastructure provided by Tests.Common:
//   - GlobalTestContainers  → ONE shared SQL Server container per test run
//   - DatabaseFixture<T>    → per-suite fixture: connection, migrations, Respawn

using MyService.Infrastructure.Persistence;
using Tests.Common.Infrastructure;
using Xunit;

namespace MyService.IntegrationTests.SomeFeature;

/// <summary>
/// Integration tests for MyRepository.
///
/// Trait taxonomy:
/// - Category: Unit | Integration | E2E | Architecture
/// - Speed:    Fast | Medium | Slow
/// - Feature:  name of the bounded context (e.g. Clientes, Usuarios, Auth)
/// - Layer:    Domain | Application | Infrastructure
/// - Database: Required          ← include when test needs a real DB
/// - Type:     HealthCheck | Migration | EventHandler | BackgroundJob | Structural | Observability
/// - UserStory: US-XXX-NNN       ← link to the acceptance criterion being verified
/// </summary>
[Collection("Database")]
[Trait("Category", "Integration")]
[Trait("Speed", "Medium")]
[Trait("Feature", "MyFeature")]
[Trait("Layer", "Infrastructure")]
[Trait("Database", "Required")]
// Optional: link to a user story → [Trait("UserStory", "US-XXX-001")]
public class MyRepositoryTests : IAsyncLifetime
{
    private readonly DatabaseFixture<MyDbContext> _fixture;

    public MyRepositoryTests(GlobalTestContainers _)
    {
        _fixture = new DatabaseFixture<MyDbContext>();

        // Set ContextFactory BEFORE calling EnsureMigrationsAsync() if your DbContext
        // requires additional dependencies beyond DbContextOptions.
        // _fixture.ContextFactory = opts => new MyDbContext(opts, someDependency);
    }

    public async Task InitializeAsync()
    {
        await _fixture.InitializeAsync();       // Connects to LocalDB (dev) or GlobalTestContainers (CI)
        await _fixture.EnsureMigrationsAsync(); // Idempotent: runs migrations + initializes Respawn
        await _fixture.ResetDatabaseAsync();    // Clean slate at START of each test (NEVER at end)
    }

    public async Task DisposeAsync() => await Task.CompletedTask;

    [Fact]
    public async Task SaveEntity_ShouldPersistToDatabase()
    {
        // Arrange
        await using var context = _fixture.CreateDbContext();
        var repo = new MyRepository(context);
        var entity = MyEntity.Create("example");

        // Act
        await repo.AddAsync(entity);
        await context.SaveChangesAsync();

        // Assert
        var found = await repo.GetByIdAsync(entity.Id);
        found.Should().NotBeNull();
        found!.Name.Should().Be("example");
    }

    [Fact]
    public async Task GetById_WithNonExistentId_ShouldReturnNull()
    {
        // Arrange — fresh DB guaranteed by ResetDatabaseAsync() in InitializeAsync
        await using var context = _fixture.CreateDbContext();
        var repo = new MyRepository(context);

        // Act
        var result = await repo.GetByIdAsync(Guid.NewGuid());

        // Assert
        result.Should().BeNull();
    }
}
