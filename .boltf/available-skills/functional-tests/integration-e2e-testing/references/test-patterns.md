# Integration & E2E Test Patterns

Complete examples of integration and end-to-end testing patterns using Testcontainers and Respawn.

## Repository Integration Tests

### Basic CRUD Operations

```csharp
// File: tests/GestionUsuarios.IntegrationTests/Repositories/UserRepositoryTests.cs

using Xunit;
using FluentAssertions;

public class UserRepositoryTests : IntegrationTestBase
{
    [Fact]
    public async Task SaveUser_ShouldPersistToDatabase()
    {
        // Arrange - Clean state
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
        savedUser.FullName.FirstName.Should().Be("Test");
    }

    [Fact]
    public async Task GetByIdAsync_NonExistentUser_ReturnsNull()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var repository = new UserRepository(context);
        var nonExistentId = UsuarioId.Create(Guid.NewGuid());

        // Act
        var user = await repository.GetByIdAsync(nonExistentId);

        // Assert
        user.Should().BeNull();
    }

    [Fact]
    public async Task UpdateUser_ShouldPersistChanges()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var repository = new UserRepository(context);

        var user = Usuario.Create(
            new Email("original@example.com"),
            new FullName("Original", "Name"),
            TenantId.Create(Guid.NewGuid())
        );

        await repository.SaveAsync(user);
        await context.SaveChangesAsync();

        // Act - Update email
        user.UpdateEmail(new Email("updated@example.com"));
        await repository.SaveAsync(user);
        await context.SaveChangesAsync();

        // Assert
        var updatedUser = await repository.GetByIdAsync(user.Id);
        updatedUser!.Email.Value.Should().Be("updated@example.com");
    }

    [Fact]
    public async Task DeleteUser_ShouldRemoveFromDatabase()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var repository = new UserRepository(context);

        var user = Usuario.Create(
            new Email("delete@example.com"),
            new FullName("Delete", "Me"),
            TenantId.Create(Guid.NewGuid())
        );

        await repository.SaveAsync(user);
        await context.SaveChangesAsync();

        // Act
        await repository.DeleteAsync(user.Id);
        await context.SaveChangesAsync();

        // Assert
        var deletedUser = await repository.GetByIdAsync(user.Id);
        deletedUser.Should().BeNull();
    }
}
```

### Query Tests with SQL Server Features

```csharp
public class UserQueryTests : IntegrationTestBase
{
    [Fact]
    public async Task GetUsersByRole_WithSqlServerQuery_ShouldWork()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var adminRole = new Role { Name = "Admin" };
        var userRole = new Role { Name = "User" };

        context.Roles.AddRange(adminRole, userRole);
        await context.SaveChangesAsync();

        var adminUser = Usuario.Create(
            new Email("admin@test.com"),
            new FullName("Admin", "User"),
            TenantId.Create(Guid.NewGuid())
        );
        adminUser.AssignRole(adminRole.Id);

        var regularUser = Usuario.Create(
            new Email("user@test.com"),
            new FullName("Regular", "User"),
            TenantId.Create(Guid.NewGuid())
        );
        regularUser.AssignRole(userRole.Id);

        context.Usuarios.AddRange(adminUser, regularUser);
        await context.SaveChangesAsync();

        // Act - SQL Server specific query with JOIN
        var admins = await context.Usuarios
            .Include(u => u.Roles)
            .Where(u => u.Roles.Any(r => r.Name == "Admin"))
            .ToListAsync();

        // Assert
        admins.Should().ContainSingle();
        admins[0].Email.Value.Should().Be("admin@test.com");
    }

    [Fact]
    public async Task AuditLog_WithSqlServerDateFunctions_ShouldWork()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var auditLog = new UserAuditLog
        {
            UsuarioId = Guid.NewGuid(),
            Action = "UserCreated",
            PerformedAt = DateTime.UtcNow,
            PerformedBy = Guid.NewGuid()
        };

        context.UserAuditLogs.Add(auditLog);
        await context.SaveChangesAsync();

        // Act - SQL Server DATEADD function
        var recentLogs = await context.UserAuditLogs
            .Where(l => l.PerformedAt > DateTime.UtcNow.AddDays(-1))
            .ToListAsync();

        // Assert
        recentLogs.Should().ContainSingle();
        recentLogs[0].Action.Should().Be("UserCreated");
    }
}
```

## Event Handler Integration Tests

```csharp
// File: tests/GestionUsuarios.IntegrationTests/DomainEvents/UserEventHandlerTests.cs

public class UserEventHandlerTests : IntegrationTestBase
{
    [Fact]
    public async Task UserCreatedEventHandler_CreatesAuditLogEntry()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var auditService = new AuditLogService(context);
        var handler = new UserCreatedEventHandler(auditService, Mock.Of<ILogger<UserCreatedEventHandler>>());

        var @event = new UserCreatedEvent(
            userId: Guid.NewGuid(),
            email: "test@example.com",
            fullName: "Test User",
            roles: new[] { "Admin" },
            tenantId: Guid.NewGuid()
        );

        // Act
        await handler.Handle(@event, CancellationToken.None);
        await context.SaveChangesAsync();

        // Assert
        var auditLogs = await context.UserAuditLogs.ToListAsync();
        auditLogs.Should().ContainSingle();
        auditLogs[0].Action.Should().Be("UserCreated");
        auditLogs[0].Details.Should().Contain("test@example.com");
        auditLogs[0].UsuarioId.Should().Be(@event.UserId);
    }

    [Fact]
    public async Task UserDeletedEventHandler_MarksUserAsDeleted()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var user = Usuario.Create(
            new Email("delete@example.com"),
            new FullName("Delete", "Me"),
            TenantId.Create(Guid.NewGuid())
        );

        context.Usuarios.Add(user);
        await context.SaveChangesAsync();

        var auditService = new AuditLogService(context);
        var handler = new UserDeletedEventHandler(auditService, Mock.Of<ILogger<UserDeletedEventHandler>>());

        var @event = new UserDeletedEvent(user.Id.Value, "Admin");

        // Act
        await handler.Handle(@event, CancellationToken.None);
        await context.SaveChangesAsync();

        // Assert
        var auditLog = await context.UserAuditLogs
            .Where(l => l.UsuarioId == user.Id.Value && l.Action == "UserDeleted")
            .FirstOrDefaultAsync();

        auditLog.Should().NotBeNull();
        auditLog!.PerformedBy.Should().NotBeEmpty();
    }
}
```

## E2E Tests with API + Database

```csharp
// File: tests/Auth.Tests.E2E/UserFlowTests.cs

using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http.Json;

public class UserFlowTests : IntegrationTestBase, IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public UserFlowTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace DbContext with Testcontainers connection
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<UsuariosDbContext>));

                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                services.AddDbContext<UsuariosDbContext>(options =>
                    options.UseSqlServer(DbContextOptions!
                        .FindExtension<SqlServerOptionsExtension>()!
                        .ConnectionString));
            });
        }).CreateClient();
    }

    [Fact]
    public async Task CreateUser_End2End_ShouldPersistAndAudit()
    {
        // Arrange
        await ResetDatabaseAsync();

        var request = new CreateUserRequest
        {
            Email = "e2e@example.com",
            FirstName = "E2E",
            LastName = "Test",
            Roles = new[] { "User" }
        };

        // Act - Call API
        var response = await _client.PostAsJsonAsync("/api/users", request);

        // Assert - API Response
        response.Should().BeSuccessful();
        var result = await response.Content.ReadFromJsonAsync<CreateUserResponse>();
        result.Should().NotBeNull();
        result!.UserId.Should().NotBeEmpty();

        // Assert - Database Verification
        await using var context = CreateDbContext();
        var user = await context.Usuarios.FindAsync(UsuarioId.Create(result.UserId));
        user.Should().NotBeNull();
        user!.Email.Value.Should().Be("e2e@example.com");
        user.FullName.FirstName.Should().Be("E2E");

        // Assert - Audit Trail
        var auditLog = await context.UserAuditLogs
            .Where(l => l.UsuarioId == result.UserId && l.Action == "UserCreated")
            .FirstOrDefaultAsync();

        auditLog.Should().NotBeNull();
        auditLog!.Details.Should().Contain("e2e@example.com");
    }

    [Fact]
    public async Task UpdateUser_End2End_ShouldUpdateAndAudit()
    {
        // Arrange
        await ResetDatabaseAsync();

        // Create user via API
        var createRequest = new CreateUserRequest
        {
            Email = "original@test.com",
            FirstName = "Original",
            LastName = "Name"
        };

        var createResponse = await _client.PostAsJsonAsync("/api/users", createRequest);
        var createResult = await createResponse.Content.ReadFromJsonAsync<CreateUserResponse>();

        // Act - Update via API
        var updateRequest = new UpdateUserRequest
        {
            Email = "updated@test.com",
            FirstName = "Updated",
            LastName = "Name"
        };

        var updateResponse = await _client.PutAsJsonAsync(
            $"/api/users/{createResult!.UserId}",
            updateRequest);

        // Assert
        updateResponse.Should().BeSuccessful();

        await using var context = CreateDbContext();
        var user = await context.Usuarios.FindAsync(UsuarioId.Create(createResult.UserId));
        user!.Email.Value.Should().Be("updated@test.com");

        // Verify audit trail has both Create and Update
        var auditLogs = await context.UserAuditLogs
            .Where(l => l.UsuarioId == createResult.UserId)
            .OrderBy(l => l.PerformedAt)
            .ToListAsync();

        auditLogs.Should().HaveCount(2);
        auditLogs[0].Action.Should().Be("UserCreated");
        auditLogs[1].Action.Should().Be("UserUpdated");
    }
}
```

## Complex Scenario Tests

### Multi-Aggregate Transaction Test

```csharp
public class MultiAggregateTests : IntegrationTestBase
{
    [Fact]
    public async Task CreateUserWithCompany_ShouldPersistBothAggregates()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();

        var company = Company.Create(
            new CompanyName("Test Company"),
            new TaxId("12345678")
        );

        context.Companies.Add(company);
        await context.SaveChangesAsync();

        var user = Usuario.Create(
            new Email("user@company.com"),
            new FullName("Company", "User"),
            TenantId.Create(company.Id.Value)
        );

        user.AssignToCompany(company.Id);
        context.Usuarios.Add(user);

        // Act
        await context.SaveChangesAsync();

        // Assert - User persisted
        var savedUser = await context.Usuarios
            .Include(u => u.Company)
            .FirstAsync(u => u.Id == user.Id);

        savedUser.Company.Should().NotBeNull();
        savedUser.Company!.Name.Should().Be("Test Company");

        // Assert - Company persisted
        var savedCompany = await context.Companies
            .Include(c => c.Users)
            .FirstAsync(c => c.Id == company.Id);

        savedCompany.Users.Should().ContainSingle();
    }
}
```

### Concurrent Access Test

```csharp
public class ConcurrentAccessTests : IntegrationTestBase
{
    [Fact]
    public async Task ConcurrentUpdates_WithOptimisticLocking_ShouldPreventConflicts()
    {
        // Arrange
        await ResetDatabaseAsync();

        await using var context = CreateDbContext();
        var user = Usuario.Create(
            new Email("concurrent@test.com"),
            new FullName("Concurrent", "Test"),
            TenantId.Create(Guid.NewGuid())
        );

        context.Usuarios.Add(user);
        await context.SaveChangesAsync();

        // Act - Simulate concurrent updates
        await using var context1 = CreateDbContext();
        await using var context2 = CreateDbContext();

        var user1 = await context1.Usuarios.FindAsync(user.Id);
        var user2 = await context2.Usuarios.FindAsync(user.Id);

        user1!.UpdateEmail(new Email("update1@test.com"));
        user2!.UpdateEmail(new Email("update2@test.com"));

        await context1.SaveChangesAsync(); // First update succeeds

        // Assert - Second update throws concurrency exception
        var act = async () => await context2.SaveChangesAsync();

        await act.Should().ThrowAsync<DbUpdateConcurrencyException>();
    }
}
```

---

**Next**: See [ci-cd-integration.md](./ci-cd-integration.md) for CI/CD setup and performance
optimization.
