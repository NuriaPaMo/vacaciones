# Backend Testing for .NET Skill

Este skill proporciona guías completas y mejores prácticas para testing de backend en .NET usando
xUnit, Testcontainers, FluentAssertions, Moq y NetArchTest.

## ¿Por qué este skill?

- **Cobertura alta**: Alcanzar targets de 80%+ line coverage, 75%+ branch coverage
- **Tests reales**: Testcontainers para tests con bases de datos reales
- **Arquitectura validada**: NetArchTest para enforcing de reglas arquitectónicas
- **Mejores prácticas**: Patrones AAA, builders, fixtures, mocking apropiado

## Ejemplos de Uso

### Ejemplo 1: Generar Unit Tests para Entidad de Dominio

**Input al Copilot:**

```text
Genera unit tests para la entidad Account con validaciones
```

**Copilot cargará este skill y generará:**

```csharp
public class AccountTests
{
    [Fact]
    public void Create_WithValidData_ShouldSucceed()
    {
        // Arrange
        var code = "1234";
        var name = "Development";

        // Act
        var result = Account.Create(code, name);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Code.Should().Be(code);
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void Create_WithInvalidCode_ShouldFail(string code)
    {
        // Act
        var result = Account.Create(code, "Name");

        // Assert
        result.IsFailure.Should().BeTrue();
        result.Error.Code.Should().Be("INVALID_ACCOUNT_CODE");
    }
}
```

### Ejemplo 2: Generar Integration Tests con Testcontainers

**Input al Copilot:**

```text
Genera integration tests para AccountRepository usando Testcontainers
```

**Copilot generará:**

- DatabaseFixture con PostgreSQL container
- Tests de persistencia usando base de datos real
- Setup y teardown apropiados
- Verificación de operaciones CRUD

### Ejemplo 3: Generar Architecture Tests

**Input al Copilot:**

```text
Genera tests de arquitectura para validar que Domain no dependa de Infrastructure
```

**Copilot generará:**

```csharp
[Fact]
public void Domain_ShouldNotHaveDependencyOnInfrastructure()
{
    var result = Types.InAssembly(typeof(DomainAssembly).Assembly)
        .ShouldNot()
        .HaveDependencyOn("Infrastructure")
        .GetResult();

    result.IsSuccessful.Should().BeTrue();
}
```

### Ejemplo 4: Generar Test Data Builders

**Input al Copilot:**

```text
Crea un builder pattern para generar datos de test de TimeEntry
```

**Copilot generará:**

```csharp
public class TimeEntryBuilder
{
    private Guid _userId = Guid.NewGuid();
    private DateTime _startTime = DateTime.UtcNow;
    private TimeSpan _duration = TimeSpan.FromHours(2);

    public TimeEntryBuilder WithUserId(Guid userId)
    {
        _userId = userId;
        return this;
    }

    public TimeEntryBuilder WithDuration(TimeSpan duration)
    {
        _duration = duration;
        return this;
    }

    public TimeEntry Build()
    {
        return TimeEntry.Create(_userId, _startTime, _duration).Value;
    }
}
```

## Coverage Targets

Este skill ayuda a alcanzar:

| Métrica         | Mínimo | Recomendado | Critical Paths |
| --------------- | ------ | ----------- | -------------- |
| Line Coverage   | 80%    | 90%         | 100%           |
| Branch Coverage | 75%    | 85%         | 100%           |
| Mutation Score  | 70%    | 80%         | 90%            |

## Integración con Bolt Framework

Este skill se integra con:

- **@Bolt Framework Testing**: Agente especializado en generar tests
- **Constitution**: Lee frameworks y targets de testing
- **Feature Specs**: Genera tests basados en acceptance criteria
- **Quality Gates**: Valida cobertura antes de merge

## Test Pyramid

```text
      ┌─────────┐
      │   E2E   │  10% - User journeys (Playwright)
      ├─────────┤
      │  Integ  │  20% - Component interaction (Testcontainers)
      ├─────────┤
      │  Unit   │  70% - Isolated logic (xUnit)
      └─────────┘
```

## Archivos Relacionados

- [SKILL.md](./SKILL.md) - Instrucciones principales
- [../skill-gherkin-reqnroll](../skill-gherkin-reqnroll/) - BDD tests relacionados
- [../skill-playwright-e2e](../skill-playwright-e2e/) - E2E tests relacionados
- [../../agents/bolt-testing.agent.md](../../agents/bolt-testing.agent.md) - Agente Testing

## Referencias

- [xUnit Documentation](https://xunit.net/)
- [FluentAssertions](https://fluentassertions.com/)
- [Testcontainers for .NET](https://dotnet.testcontainers.org/)
- [NetArchTest](https://github.com/BenMorris/NetArchTest)
