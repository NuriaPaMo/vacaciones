# ADR-002: Adopt Modular Monolith Architecture with Simple CQRS Using Native .NET Interfaces

## Status

Accepted

## Date

2026-08-05

## Context

The project requires an architectural pattern that:

- Keeps deployment simple (single deployable unit for an early-stage product)
- Maintains clear boundaries between business domains to avoid a "big ball of mud"
- Supports a read/write split aligned with the chosen data access strategy (EF Core writes, Dapper reads)
- Avoids unnecessary complexity and third-party dependencies (e.g., MediatR, Event Sourcing)
- Enables independent testability of commands and queries without framework coupling

The team has chosen C#/.NET 10 (ADR-001) and Azure SQL Database (ADR-003). The application is expected to start as a single team product and may evolve modules into separate services only if warranted by scale or organisational need.

Key forces:
- **Simplicity over premature optimisation**: A Modular Monolith avoids distributed systems complexity (network partitions, distributed transactions) until truly needed
- **Clear bounded contexts**: Each module encapsulates its own domain model, commands, queries, and persistence concerns
- **No magical reflection**: MediatR relies on handler discovery via reflection/DI scanning — native interfaces make the call graph explicit
- **Testability**: Plain C# interfaces are trivially mockable without framework adapters

## Decision Drivers

- MUST support single-deployment artifact for early product phase
- MUST enforce clear boundaries between bounded contexts (no cross-module direct DB access)
- MUST implement CQRS with explicit ICommand/IQuery/IHandler interfaces (no MediatR)
- MUST NOT require Event Sourcing (operational overhead not justified)
- SHOULD allow future extraction of modules to microservices if required
- SHOULD keep the command/query handler registration simple and transparent

## Considered Options

### Option 1: Modular Monolith + Simple CQRS (Native Interfaces) ✅ (Chosen)

A Modular Monolith structures the application as a single deployable process with modules that respect explicit API boundaries. Simple CQRS separates read and write concerns using native C# generic interfaces without a mediator library.

**Interface contracts:**
```csharp
public interface ICommand { }
public interface ICommandResult { }
public interface IQuery<TResult> { }

public interface ICommandHandler<TCommand, TResult>
    where TCommand : ICommand
    where TResult : ICommandResult
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken ct);
}

public interface IQueryHandler<TQuery, TResult>
    where TQuery : IQuery<TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken ct);
}
```

**Pros:**
- Single deployment unit — no inter-service network calls, no distributed tracing complexity
- Module folders map directly to bounded contexts (e.g., `Modules/Reservations/`, `Modules/Users/`)
- No reflection magic: handler registration is explicit via DI, call graph is statically traceable
- Trivially testable — mock `ICommandHandler<T, R>` without any framework adapter
- Aligns naturally with EF Core (write side) + Dapper (read side) split in each module
- Easier debugging — single process, single log stream, single OTel trace

**Cons:**
- Modules share a process — a crash affects all modules (mitigated: .NET exception isolation, health probes)
- Requires discipline to enforce module boundaries (no cross-module internal type references)
- Scaling individual modules independently is not possible without extraction to separate services

### Option 2: Microservices Architecture

**Pros:**
- Independent deployment and scaling per service
- Technology heterogeneity possible

**Cons:**
- Extreme operational overhead for a greenfield early-stage product
- Distributed transactions (sagas/outbox) add significant complexity
- Network latency between services; requires service mesh or API gateway from day one
- Overkill until bounded context ownership and traffic patterns are well-understood
- Contradicts the "simplicity first" principle for a 2026 greenfield project

### Option 3: Modular Monolith + MediatR

**Pros:**
- MediatR is a well-known library with pipeline behaviours (logging, validation, etc.)
- Reduces boilerplate for handler dispatch

**Cons:**
- MediatR relies on reflection-based handler discovery — makes the call graph implicit
- Additional third-party dependency to maintain and upgrade
- Pipeline behaviours can be replicated with middleware or decorator patterns natively
- `IRequest<T>` / `IRequestHandler<T,R>` are MediatR-specific types, coupling domain to library
- Native interfaces achieve the same result with zero external dependency

### Option 4: Traditional Layered Architecture (N-Tier)

**Pros:**
- Familiar to most developers
- Well-documented pattern

**Cons:**
- Encourages anemic domain models and service-layer spaghetti over time
- No clear enforcement of bounded context boundaries
- Read/write separation harder to implement cleanly without explicit CQRS abstractions
- Does not scale well to multiple domain modules without devolving into a monolithic service layer

## Decision Outcome

**Chosen option: Modular Monolith with Simple CQRS using native .NET interfaces**

Rationale: The Modular Monolith delivers the operational simplicity of a single deployment unit while maintaining the clean boundaries of a modular design. Native CQRS interfaces eliminate external dependencies, keep the call graph explicit, and enable zero-friction unit testing. This architecture supports future module extraction to microservices without rewriting domain logic.

### Module Structure (Reference)

```
src/
  Modules/
    Reservations/
      Commands/       ← ICommand + ICommandHandler implementations
      Queries/        ← IQuery + IQueryHandler implementations
      Domain/         ← Aggregates, Value Objects, Domain Events
      Persistence/    ← EF Core DbContext, Dapper queries, Repository implementations
      API/            ← Minimal API endpoint registration (IEndpointRouteBuilder extension)
    Users/
      ...
  Shared/
    CQRS/             ← ICommand, IQuery, ICommandHandler, IQueryHandler interfaces
    Domain/           ← Base classes (Entity, AggregateRoot, ValueObject)
    Persistence/      ← IUnitOfWork, IRepository<T> interfaces
```

### Positive Consequences

- Single deployable artifact simplifies CI/CD, rollback, and operational monitoring
- Module boundaries are enforced by folder structure and internal access modifiers
- Native interfaces make handler dispatch explicit — no "magic" service bus in the middle
- EF Core handles command-side change tracking; Dapper handles read-side performance
- Full OTel tracing spans the entire request within a single process — no distributed trace stitching
- Easy to extract a module to a microservice later by promoting its API folder to a separate service

### Negative Consequences

- All modules scale together — cannot scale `Reservations` independently from `Users` without service extraction
- Team discipline required to prevent cross-module coupling (enforced via architecture tests with ArchUnitNET)
- No built-in pipeline behaviour support (logging, validation) — must implement via decorators or middleware; this is a one-time setup cost

## Compliance

- Technology: Uses C#/.NET 10 (ADR-001)
- Data: Command side uses EF Core, query side uses Dapper (ADR-003)
- Infrastructure: Deployed as single container to Azure Container Apps (ADR-005)

## Links

- [Modular Monolith architecture — Sam Newman](https://samnewman.io/patterns/architectural/monolith/)
- [CQRS pattern — Martin Fowler](https://martinfowler.com/bliki/CQRS.html)
- [ArchUnitNET — architecture testing](https://archunitnet.readthedocs.io/)
- ADR-001: Backend Technology Stack
- ADR-003: Data Storage and Access Strategy
