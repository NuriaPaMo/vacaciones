// tests/MyService.IntegrationTests/Infrastructure/DatabaseCollection.cs
// Each bounded-context test project MUST declare its own DatabaseCollection.
// xUnit collections cannot be shared across assemblies.
//
// Real example: tests/Auth.Tests.Integration/Infrastructure/DatabaseCollection.cs

using Tests.Common.Infrastructure;
using Xunit;

namespace MyService.IntegrationTests.Infrastructure;

/// <summary>
/// Defines the "Database" collection for xUnit (ADR-018).
/// All tests marked with [Collection("Database")] share the same GlobalTestContainers instance.
/// The SQL Server container starts ONCE for all tests in the collection (~60% faster).
/// Respawn resets database between tests (~200-300ms vs 3-5s for a new container).
/// </summary>
[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<GlobalTestContainers>
{
    // This class has no code - it's just a marker for xUnit
    // to recognize the collection and inject GlobalTestContainers.
}
