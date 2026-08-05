// tests/Architecture.Tests.MiBoundedContext/MiBoundedContextArchitectureTests.cs
//
// Copy this file to your Architecture.Tests.{BoundedContext} project and replace
// "MiBoundedContext" / "Peritec.MiBoundedContext" with your context's identifiers.
// Real examples: tests/Architecture.Tests.GestionUsuarios/GestionUsuariosArchitectureTests.cs

using Architecture.Tests.Common;
using Architecture.Tests.Common.Rules;
using Xunit;

namespace Architecture.Tests.MiBoundedContext;

[Trait("Category", "Architecture")]
[Trait("Speed", "Fast")]
[Trait("Feature", "MiBoundedContext")]
public class MiBoundedContextArchitectureTests
{
    // Configure once — assemblies resolved from project references
    private readonly MicroserviceConfig _config = new()
    {
        Name = "MiBoundedContext",
        RootNamespace = "Peritec.MiBoundedContext",
        DomainAssembly = typeof(global::MiBoundedContext.Domain.AssemblyMarker).Assembly,
        ApplicationAssembly = typeof(global::MiBoundedContext.Application.AssemblyMarker).Assembly,
        InfrastructureAssembly = typeof(global::MiBoundedContext.Infrastructure.AssemblyMarker).Assembly,
        ApiAssembly = typeof(global::Program).Assembly
    };

    // Layer isolation (ADR-001)
    [Fact] public void Domain_Should_Be_Isolated()
        => LayerDependencyRules.ValidateDomainIsolation(_config);

    [Fact] public void Application_Should_Be_Isolated()
        => LayerDependencyRules.ValidateApplicationIsolation(_config);

    [Fact] public void Infrastructure_Should_Be_Isolated()
        => LayerDependencyRules.ValidateInfrastructureIsolation(_config);

    [Fact] public void Domain_Should_Only_Have_Primitives_And_System_Dependencies()
        => LayerDependencyRules.ValidateDomainPurity(_config);

    // CQRS compliance — NO MediatR (ADR-002)
    [Fact] public void No_Assembly_Should_Use_MediatR()
        => CqrsComplianceRules.ValidateNoMediatR(_config);

    [Fact] public void CommandHandlers_Should_Implement_ICommandHandler()
        => CqrsComplianceRules.ValidateCommandHandlers(_config);

    [Fact] public void QueryHandlers_Should_Implement_IQueryHandler()
        => CqrsComplianceRules.ValidateQueryHandlers(_config);

    [Fact] public void CommandHandlers_Should_Reside_In_Application_Layer()
        => CqrsComplianceRules.ValidateCommandHandlersLocation(_config);

    [Fact] public void QueryHandlers_Should_Reside_In_Application_Layer()
        => CqrsComplianceRules.ValidateQueryHandlersLocation(_config);

    // Naming conventions
    [Fact] public void Async_Methods_Should_Have_Async_Suffix()
        => NamingConventionRules.ValidateAsyncMethodNaming(_config);

    [Fact] public void Interfaces_Should_Start_With_I()
        => NamingConventionRules.ValidateInterfaceNaming(_config);

    // Repository pattern (ADR-001)
    [Fact] public void Repositories_Should_Only_Be_In_Infrastructure_Layer()
        => RepositoryPatternRules.ValidateRepositoryLocation(_config);

    [Fact] public void DbContext_Should_Only_Be_In_Infrastructure()
        => RepositoryPatternRules.ValidateDbContextLocation(_config);

    [Fact] public void Domain_Should_Not_Reference_EntityFramework()
        => RepositoryPatternRules.ValidateDomainPersistenceIgnorance(_config);

    // Shared libraries compliance (ADR-011)
    [Fact] public void Aggregates_Should_Implement_IAggregateRoot_From_Shared_Library()
        => CommonLibrariesRules.ValidateAggregatesImplementSharedIAggregateRoot(_config);

    [Fact] public void CommandHandlers_Should_Implement_Shared_ICommandHandler()
        => CommonLibrariesRules.ValidateCommandHandlersImplementSharedInterface(_config);

    [Fact] public void Should_Not_Have_Duplicated_Abstractions()
        => CommonLibrariesRules.ValidateNoDuplicatedAbstractions(_config);
}
