# ADR-001: Use C#/.NET 10 with Minimal APIs for Backend

## Status

Accepted

## Date

2026-08-05

## Context

This is a greenfield full-stack project initiated in 2026, hosted on Azure. The team needs to select a backend technology stack that:

- Integrates natively with Azure services (Service Bus, Key Vault, SQL, Container Apps, Application Insights)
- Delivers high performance for REST API workloads
- Supports modern software development practices (async/await, strong typing, DI)
- Aligns with the broader enterprise ecosystem and long-term Microsoft/Azure support roadmap

The project targets a Modular Monolith architecture deployed as a containerised workload. The backend will expose REST APIs consumed by a Vue 3 SPA frontend.

Key forces:
- **Azure-first**: Native Azure SDK support reduces integration friction
- **Performance**: Low-latency API responses under load
- **Type safety**: Compile-time correctness reduces runtime defects
- **Team alignment**: Must be viable for current or nearshore talent pool
- **Longevity**: LTS/mainstream support through 2026–2028+

## Decision Drivers

- MUST integrate seamlessly with Azure services (SDK first-class support)
- MUST provide strong compile-time type safety
- MUST support containerisation (Docker/Azure Container Apps)
- SHOULD have high throughput for REST API use cases
- SHOULD minimise boilerplate for CRUD-heavy modules
- COULD support gRPC or SignalR for future extensions

## Considered Options

### Option 1: C#/.NET 10 with Minimal APIs ✅ (Chosen)

ASP.NET Core Minimal APIs introduced in .NET 6 and matured in .NET 8–10 provide a lightweight, low-ceremony approach to building HTTP endpoints without the overhead of MVC Controllers.

**Pros:**
- .NET 10 is the latest release (2025), offering AOT compilation, performance improvements, and full Azure SDK support
- Minimal APIs reduce boilerplate — no controller classes, attribute routing clutter, or action filters required for simple endpoints
- Native DI, middleware pipeline, and OpenAPI/Swagger support out of the box
- First-class Azure SDK for .NET with async support for all Azure services
- Top-tier throughput benchmarks (TechEmpower) across all web frameworks
- Strong typing with C# eliminates entire classes of runtime errors
- .NET Aspire for local development orchestration fits naturally

**Cons:**
- .NET 10 is the latest release; team requires familiarity with C# 13+ features
- Minimal APIs can feel less structured for very large route surfaces — mitigation: use `IEndpointRouteBuilder` extension methods per module
- Steeper learning curve than scripting-style backends (Node.js) for developers without .NET background

### Option 2: Node.js with Express/Fastify + TypeScript

**Pros:**
- Shared language with frontend (TypeScript), potential code reuse
- Vast npm ecosystem
- Fast iteration speed for small teams

**Cons:**
- Azure SDK for JavaScript is less mature than .NET SDK for enterprise scenarios
- No compile-time type safety at runtime (TypeScript compiles away)
- Inferior throughput vs .NET for CPU-bound or high-concurrency workloads
- Not the strongest choice for a CQRS + EF Core architecture pattern
- Team would need to maintain two distinct runtime environments

### Option 3: C#/.NET 8 LTS with MVC Controllers

**Pros:**
- .NET 8 is current LTS (supported until Nov 2026)
- MVC Controllers pattern is widely documented, familiar to .NET developers
- Mature ecosystem of filters, model binding, and action result abstractions

**Cons:**
- More ceremony than Minimal APIs for straightforward REST endpoints
- Controllers encourage coupling route handling to business logic unless carefully structured
- .NET 10 is available and performant — choosing LTS over current offers less with no significant risk reduction for a greenfield project
- Superseded by Minimal APIs as the recommended pattern for new .NET APIs

## Decision Outcome

**Chosen option: C#/.NET 10 with Minimal APIs**

Rationale: .NET 10 delivers the best available performance, Azure-native integration, and modern language features (C# 13). Minimal APIs reduce ceremony while remaining fully extensible. The Azure SDK for .NET is the most complete and supported option for Azure-first projects. Strong typing prevents entire categories of bugs at compile time.

### Positive Consequences

- Native Azure SDK support for all Azure services (SQL, Service Bus, Key Vault, Container Apps, Monitor)
- High throughput REST API capable of handling significant load on modest Container Apps scale-out
- Strong C# type system catches integration errors at build time, not at runtime
- .NET Aspire orchestration simplifies local development with service discovery and OTel dashboard
- Consistent language/tooling across backend and infrastructure-as-code (.NET Aspire manifests)
- Excellent Docker support with `dotnet publish` producing optimised container images

### Negative Consequences

- Team members unfamiliar with C# or .NET require onboarding time — mitigated by strong tooling (Rider/VS) and extensive official documentation
- .NET 10 is not yet LTS (LTS cadence is even-numbered: .NET 8, .NET 10 will be LTS); however, .NET 9 standard-term and .NET 10 LTS timelines align with this project's lifecycle
- Minimal APIs require discipline on endpoint organisation at scale — addressed by per-module `IEndpointRouteBuilder` extensions

## Compliance

- Architecture: Consistent with Modular Monolith + Simple CQRS pattern (see ADR-002)
- Infrastructure: Containerised deployment to Azure Container Apps (see ADR-005)
- Observability: OTel SDK for .NET integrates natively (see ADR-006)

## Links

- [ASP.NET Core Minimal APIs documentation](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis)
- [.NET 10 release notes](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10)
- [Azure SDK for .NET](https://azure.github.io/azure-sdk-for-net/)
- [TechEmpower Framework Benchmarks](https://www.techempower.com/benchmarks/)
- ADR-002: Backend Architecture — Modular Monolith with Simple CQRS
- ADR-003: Data Storage and Access Strategy
- ADR-005: Cloud Infrastructure — Azure Container Apps with Terraform
- ADR-006: CI/CD, Observability, and Security Baseline
