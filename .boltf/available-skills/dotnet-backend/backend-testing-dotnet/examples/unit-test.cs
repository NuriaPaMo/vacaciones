// Domain entity test — tests/GestionMiContexto.UnitTests/Domain/Entities/MyEntityTests.cs
using FluentAssertions;
using MyBoundedContext.Domain.Entities;
using Xunit;

namespace MyBoundedContext.UnitTests.Domain.Entities;

// Required class-level traits — full taxonomy in integration-e2e-testing skill
[Trait("Category", "Unit")]
[Trait("Speed", "Fast")]
[Trait("Feature", "MyContext")]
[Trait("Layer", "Domain")]
public class MyEntityTests
{
    [Fact]
    public void Create_WithValidData_ShouldSucceed()
    {
        // Arrange
        var ownerId = Guid.NewGuid();
        var tenantId = "TENANT-001";

        // Act
        var result = MyEntity.Create(ownerId, tenantId);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.OwnerId.Should().Be(ownerId);
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void Create_WithInvalidTenantId_ShouldFail(string? tenantId)
    {
        var result = MyEntity.Create(Guid.NewGuid(), tenantId!);

        result.IsFailure.Should().BeTrue();
        result.Error.Code.Should().Be("INVALID_TENANT");
    }
}

// CQRS handler test — tests/GestionMiContexto.UnitTests/Commands/CreateMyEntityCommandHandlerTests.cs
using FluentAssertions;
using Moq;
using Xunit;

namespace MyBoundedContext.UnitTests.Commands;

[Trait("Category", "Unit")]
[Trait("Speed", "Fast")]
[Trait("Feature", "MyContext")]
[Trait("Layer", "Application")]
public class CreateMyEntityCommandHandlerTests
{
    private readonly Mock<IMyEntityRepository> _repoMock = new();
    private readonly CreateMyEntityCommandHandler _handler;

    public CreateMyEntityCommandHandlerTests()
    {
        _handler = new CreateMyEntityCommandHandler(_repoMock.Object);
    }

    [Fact]
    public async Task HandleAsync_ShouldCallRepository_WhenCommandIsValid()
    {
        // Arrange
        var command = new CreateMyEntityCommand(OwnerId: Guid.NewGuid(), TenantId: "TENANT-001");

        _repoMock
            .Setup(r => r.AddAsync(It.IsAny<MyEntity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((MyEntity e, CancellationToken _) => e);

        // Act
        // ✅ Use HandleAsync — never .Handle() (MediatR is forbidden per ADR-002)
        var result = await _handler.HandleAsync(command, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        _repoMock.Verify(
            r => r.AddAsync(It.IsAny<MyEntity>(), It.IsAny<CancellationToken>()),
            Times.Once
        );
    }
}
