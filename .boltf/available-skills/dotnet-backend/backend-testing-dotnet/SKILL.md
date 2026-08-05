---
name: backend-testing-dotnet
description: Unit tests and architecture tests for .NET backends. Use for xUnit, FluentAssertions, Moq patterns, CQRS handler testing (ICommandHandler/IQueryHandler — no MediatR), test data builders, and architecture enforcement with NetArchTest (MicroserviceConfig pattern). For integration tests (DatabaseFixture, SQL Server, Respawn) and E2E tests use the integration-e2e-testing skill.
---

# Backend Testing for .NET

> 🔗 Integration & E2E tests → [`integration-e2e-testing`](../integration-e2e-testing/SKILL.md)  
> 🔗 Playwright patterns → [`playwright-e2e`](../playwright-e2e/SKILL.md)

## Quick Start

```bash
dotnet add package FluentAssertions
dotnet add package Moq
dotnet add package coverlet.collector

dotnet test Backend.sln
dotnet test Backend.sln --settings coverlet.runsettings /p:CollectCoverage=true
dotnet test --filter "Category=Unit"
dotnet test --filter "Category=Architecture"
```

## Test Project Structure

```text
tests/
├── {BoundedContext}.UnitTests/           # e.g. GestionUsuarios.UnitTests
│   ├── Commands/
│   │   └── CreateEntityCommandHandlerTests.cs
│   ├── Queries/
│   │   └── SearchEntityQueryHandlerTests.cs
│   └── Builders/                          # Test data builders
│       └── EntityBuilder.cs
├── {BoundedContext}.IntegrationTests/    # → see integration-e2e-testing skill
├── Architecture.Tests.Common/            # Shared NetArchTest rule classes
│   └── Rules/
│       ├── LayerDependencyRules.cs        # ADR-001: Clean Architecture isolation
│       ├── CqrsComplianceRules.cs         # ADR-002: no MediatR, ICommandHandler/IQueryHandler
│       ├── NamingConventionRules.cs        # Async suffix, interface I-prefix
│       ├── DomainEntityRules.cs
│       ├── DomainEventsComplianceRules.cs
│       ├── MinimalApiComplianceRules.cs
│       ├── RepositoryPatternRules.cs
│       └── SharedLibrariesRules.cs        # ADR-011
└── Architecture.Tests.{BoundedContext}/  # Per-bounded-context architecture tests
    └── {BoundedContext}ArchitectureTests.cs
```

## Unit Tests

AAA pattern, class-level `[Trait]` attributes on every test class, `HandleAsync()` — never
`.Handle()` (MediatR is forbidden per ADR-002).

See → [examples/unit-test.cs](examples/unit-test.cs)

Required traits:

```csharp
[Trait("Category", "Unit")]    // Unit | Integration | E2E | Architecture
[Trait("Speed", "Fast")]       // Fast (<100ms) | Medium (<5s) | Slow (>5s)
[Trait("Feature", "MyCtx")]    // Bounded context name
[Trait("Layer", "Domain")]     // Domain | Application | Infrastructure
```

## Integration Tests (con Base de Datos)

> 🔗 Los integration tests con base de datos real están a cargo del skill
> [`integration-e2e-testing`](../integration-e2e-testing/SKILL.md).
>
> Ese skill provee `DatabaseFixture<TContext>` + `GlobalTestContainers` (SQL Server compartido),
> Respawn para reset rápido (~200-300 ms), y colecciones xUnit.

Reglas clave para no violate el patrón:

- ✅ SQL Server ONLY (nunca SQLite ni in-memory)
- ✅ Un contenedor compartido (`GlobalTestContainers`) — nunca uno por test
- ✅ Resetear la BD al **inicio** de cada test, nunca al final
- ✅ `[Trait("Database", "Required")]` en todos los tests que usen BD real
- ✅ `[Trait("Feature", "<feature-name>")]` en todos los tests que se creen dentro de una feature y sus bolts

## Architecture Tests (NetArchTest + MicroserviceConfig)

Each bounded context has a dedicated `Architecture.Tests.{BoundedContext}` project that delegates
to shared static rule classes from `Architecture.Tests.Common/Rules/`:

| Rule class                      | What it enforces                                                      |
| ------------------------------- | --------------------------------------------------------------------- |
| `LayerDependencyRules`          | Clean Architecture layer isolation (ADR-001)                          |
| `CqrsComplianceRules`           | No MediatR, `ICommandHandler`/`IQueryHandler` compliance (ADR-002)   |
| `NamingConventionRules`         | Async suffix, interface `I`-prefix, handler/service/repo naming       |
| `DomainEntityRules`             | Domain entity structure constraints                                   |
| `DomainEventsComplianceRules`   | Domain event naming and placement                                     |
| `MinimalApiComplianceRules`     | Minimal API endpoint conventions                                      |
| `RepositoryPatternRules`        | Repository and DbContext placement                                    |
| `SharedLibrariesRules`          | Shared library compliance (ADR-011)                                   |

See → [examples/architecture-test.cs](examples/architecture-test.cs) — `MicroserviceConfig` template  
Real example → `tests/Architecture.Tests.GestionUsuarios/GestionUsuariosArchitectureTests.cs`

## Test Data Builders

Fluent builder pattern — each test overrides only what it cares about; everything else defaults.

See → [examples/test-data-builder.cs](examples/test-data-builder.cs)

## Coverage

See → [examples/coverlet.runsettings](examples/coverlet.runsettings)

Targets: line ≥ 80% | branch ≥ 75% | excludes migrations and test assemblies.

## Running Tests

```bash
dotnet test Backend.sln
dotnet test --filter "Category=Unit"
dotnet test --filter "Category=Architecture"
dotnet test /p:CollectCoverage=true /p:CoverageThreshold=80 /p:ThresholdType=line
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
reportgenerator -reports:coverage.cobertura.xml -targetdir:coverage-report
```

## Best Practices

### Unit Tests

- ✅ AAA pattern (Arrange, Act, Assert)
- ✅ One assertion per test (or related assertions)
- ✅ Use FluentAssertions for readable assertions
- ✅ Use Theory + InlineData for parameterized tests
- ✅ Test data builders for complex objects
- ❌ Don't mock what you don't own
- ❌ Don't test framework code

### Integration Tests (→ integration-e2e-testing skill)

- ✅ SQL Server only — never SQLite or in-memory
- ✅ Use `DatabaseFixture<TContext>` (shared `GlobalTestContainers` container)
- ✅ Reset database at **start** of each integration test with Respawn
- ✅ Decorate with `[Trait("Database", "Required")]`
- ❌ Don't create a new container per test
- ❌ Don't reset at end of test

See [integration-e2e-testing SKILL.md](../integration-e2e-testing/SKILL.md) for full patterns.

### Architecture Tests

- ✅ Enforce layer dependencies
- ✅ Validate naming conventions
- ✅ Check for forbidden dependencies
- ✅ Run in CI pipeline
- ❌ Don't skip architecture tests

## References

- [xUnit Documentation](https://xunit.net/)
- [FluentAssertions](https://fluentassertions.com/)
- [Moq documentation](https://github.com/devlooped/moq)
- [NetArchTest](https://github.com/BenMorris/NetArchTest)
- [Architecture.Tests.Common rules](../../../tests/Architecture.Tests.Common/Rules/) — shared rule classes
- [integration-e2e-testing skill](../integration-e2e-testing/SKILL.md) — integration & E2E tests
- [playwright-e2e skill](../playwright-e2e/SKILL.md) — Playwright POM, locators, assertions
