# BOLT Framework Project Constitution — Scope: Backend

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `backend` — Backend language, runtime, architecture, data, caching, identity, containers, testing, and code standards.
> Articles marked with 🔄 are **common to all scopes** and always present.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article II: Application Configuration

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 2.1: Backend Language & Runtime 🔴 CRITICAL

> **🔴 CRITICAL**: Language choice affects entire codebase - extremely difficult to change later

Select ONE:

- [ ] **C# / .NET**
  - Version: [ ] .NET 8 (LTS) [ ] .NET 10 🟡 IMPORTANT
  - API Style: [ ] Minimal APIs [ ] Controllers (MVC) [ ] Azure Functions 🟡 IMPORTANT

- [ ] **Node.js / TypeScript**
  - Version: [ ] Node.js 20 LTS [ ] Node.js 22 🟢 LOW-PRIO
  - Framework: [ ] Express [ ] Fastify [ ] NestJS [ ] Azure Functions 🟡 IMPORTANT

---

## Article III: Application Architecture

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 3.1: Backend Architecture Style 🔴 CRITICAL

> **🔴 CRITICAL**: Architecture style affects service boundaries, deployment strategy, and team organization

Select ONE:

- [ ] **Microservices** - Independent deployable services
- [ ] **Modular Monolith** - Single deployment, modular boundaries
- [ ] **Traditional Monolith** - Single deployment, layered
- [ ] **Serverless** - Azure Functions based
- [ ] **Event-Driven / CQRS+ES** - Commands, queries, event sourcing

### Section 3.3: CQRS Configuration 🟡 IMPORTANT

> **🟡 IMPORTANT**: CQRS pattern affects code structure but can be added/removed with moderate effort

CQRS Enabled: [ ] Yes [ ] No

If Yes, select pattern:

- [ ] **Full CQRS** - Commands + Queries separated, different models
- [ ] **CQRS + Event Sourcing** - Full CQRS with event store
- [ ] **Simple CQRS** - Same model, separated handlers

#### For C#/.NET: Native CQRS Interfaces (NO MediatR)

> **⚠️ IMPORTANT**: NO usar MediatR. Implementar CQRS con interfaces nativas de .NET.

```csharp
// Commands
public interface ICommand { }
public interface ICommandHandler<in TCommand> where TCommand : ICommand
{
    Task HandleAsync(TCommand command, CancellationToken ct = default);
}
public interface ICommandHandler<in TCommand, TResult> where TCommand : ICommand
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken ct = default);
}

// Queries
public interface IQuery<TResult> { }
public interface IQueryHandler<in TQuery, TResult> where TQuery : IQuery<TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken ct = default);
}

// Dispatchers (DI-based, no reflection magic)
public interface ICommandDispatcher
{
    Task DispatchAsync<TCommand>(TCommand command, CancellationToken ct = default)
        where TCommand : ICommand;
}
public interface IQueryDispatcher
{
    Task<TResult> DispatchAsync<TQuery, TResult>(TQuery query, CancellationToken ct = default)
        where TQuery : IQuery<TResult>;
}

// Domain Events
public interface IDomainEvent
{
    Guid EventId { get; }
    DateTime OccurredOn { get; }
}
public interface IDomainEventHandler<in TEvent> where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent domainEvent, CancellationToken ct = default);
}
```

#### For Node.js/TypeScript: Native CQRS Pattern

```typescript
// Commands
interface ICommand {}
interface ICommandHandler<TCommand extends ICommand, TResult = void> {
  handle(command: TCommand): Promise<TResult>;
}

// Queries
interface IQuery<TResult> {}
interface IQueryHandler<TQuery extends IQuery<TResult>, TResult> {
  handle(query: TQuery): Promise<TResult>;
}

// Bus (simple DI-based)
interface ICommandBus {
  dispatch<TCommand extends ICommand>(command: TCommand): Promise<void>;
}
interface IQueryBus {
  dispatch<TQuery extends IQuery<TResult>, TResult>(query: TQuery): Promise<TResult>;
}

// Domain Events
interface IDomainEvent {
  eventId: string;
  occurredOn: Date;
}
interface IDomainEventHandler<TEvent extends IDomainEvent> {
  handle(event: TEvent): Promise<void>;
}
```

### Section 3.4: Event Sourcing Configuration 🔴 CRITICAL

> **🔴 CRITICAL**: Once committed to Event Sourcing, very difficult to migrate away from

Event Sourcing Enabled: [ ] Yes [ ] No

If Yes, select Event Store:

- [ ] **EventStoreDB** - Purpose-built event store
- [ ] **Azure Cosmos DB** - Change Feed for events
- [ ] **SQL Server / PostgreSQL** - Outbox pattern with projections

---

## Article IV: Communication

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 4.1: Communication Style 🔴 CRITICAL

> **🔴 CRITICAL**: Sync vs Async vs Hybrid defines entire integration approach

Select ONE:

- [ ] **Synchronous only** - REST, gRPC
- [ ] **Asynchronous only** - Messages, Events
- [ ] **Hybrid** - Both sync and async

### Section 4.2: Synchronous Communication 🟡 IMPORTANT

- [ ] **REST API** - Enabled
- [ ] **gRPC** - Enabled
- [ ] **GraphQL** - [ ] None [ ] HotChocolate (.NET) [ ] Apollo (Node.js)

### Section 4.3: Asynchronous Communication

Message Broker - Select ONE: 🔴 CRITICAL (if async)

- [ ] **None**
- [ ] **Azure Service Bus** - Cloud-native, enterprise
- [ ] **Azure Event Hubs** - High-throughput streaming
- [ ] **RabbitMQ** - On-premises, flexible
- [ ] **Azure Storage Queues** - Simple, cost-effective

Background Processing - Select ONE or more: 🟡 IMPORTANT

- [ ] **None**
- [ ] **.NET BackgroundService** / **Node.js Worker Threads**
- [ ] **Azure Functions** - Serverless triggers
- [ ] **Hangfire** (.NET) / **BullMQ** (Node.js) - Persistent jobs

---

## Article V: Data Storage

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 5.1: Primary Database 🔴 CRITICAL

> **🔴 CRITICAL**: SQL vs NoSQL migration is extremely expensive - choose carefully

Select ONE:

- [ ] **Azure SQL Database** - Managed SQL Server
- [ ] **SQL Server** - On-premises
- [ ] **PostgreSQL** - Azure Database for PostgreSQL / On-premises
- [ ] **Azure Cosmos DB** - NoSQL, globally distributed
- [ ] **MongoDB** - Document database

### Section 5.2: Data Access Pattern 🟡 IMPORTANT

#### For C#/.NET

- [ ] **Entity Framework Core** - Full ORM
- [ ] **Dapper** - Micro-ORM, performance-focused
- [ ] **EF Core + Dapper** - EF for writes, Dapper for reads (CQRS)

#### For Node.js/TypeScript

- [ ] **Prisma** - Type-safe ORM
- [ ] **TypeORM** - Active Record / Data Mapper
- [ ] **Drizzle** - Lightweight, SQL-like
- [ ] **Knex.js** - Query builder

Repository Pattern: [ ] Yes [ ] No 🟡 IMPORTANT
Unit of Work Pattern: [ ] Yes [ ] No 🟡 IMPORTANT

### Section 5.3: Database Migrations 🟢 LOW-PRIO

#### For C#/.NET

- [ ] **EF Core Migrations** - Code-first
- [ ] **DbUp** - SQL scripts
- [ ] **FluentMigrator** - Fluent API

#### For Node.js/TypeScript

- [ ] **Prisma Migrate** - Integrated with Prisma
- [ ] **TypeORM Migrations** - Integrated with TypeORM
- [ ] **Knex Migrations** - SQL-based

---

## Article VI: Caching Strategy

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 6.1: Cache Levels 🟡 IMPORTANT (Enabled) / 🟢 LOW-PRIO (TTL values)

| Level                | Technology                                 | Enabled        | TTL Default    |
| -------------------- | ------------------------------------------ | -------------- | -------------- |
| **L1 - In-Memory**   | IMemoryCache (.NET) / node-cache (Node.js) | [ ] Yes [ ] No | \_\_\_ minutes |
| **L2 - Distributed** | (see below)                                | [ ] Yes [ ] No | \_\_\_ minutes |
| **L3 - CDN**         | (see below)                                | [ ] Yes [ ] No | \_\_\_ hours   |

### Section 6.2: Distributed Cache (L2) 🟡 IMPORTANT

Select ONE:

- [ ] **None**
- [ ] **Azure Cache for Redis** - Managed Redis
- [ ] **Redis** - On-premises / Self-hosted

### Section 6.3: CDN (L3) 🟡 IMPORTANT

Select ONE:

- [ ] **None**
- [ ] **Azure CDN** - Static content caching
- [ ] **Azure Front Door** - Global load balancing + CDN

### Section 6.4: Cache Patterns 🟢 LOW-PRIO

- [ ] **Cache-Aside** - Application manages cache
- [ ] **Read-Through** - Cache loads on miss
- [ ] **Write-Through** - Cache writes to source
- [ ] **Write-Behind** - Async persistence

---

## Article VII: Identity & Access Management

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 7.1: Identity Provider (Production) 🔴 CRITICAL

> **🔴 CRITICAL**: Identity provider choice affects entire auth stack and user management

Select ONE:

- [ ] **Microsoft Entra ID (Azure AD)** - Enterprise/Internal users
- [ ] **Azure AD B2C** - Customer-facing (CIAM)
- [ ] **Duende IdentityServer** - Self-hosted OIDC (.NET)
- [ ] **Keycloak** - Open-source, self-hosted
- [ ] **Auth0** - Managed identity service

### Section 7.2: Identity Provider (Development/Testing) 🟢 LOW-PRIO

Select ONE:

- [ ] **Mock IDP** - In-memory, fake tokens for tests
- [ ] **Azure AD Test Tenant** - Real AD, test users
- [ ] **Local IdentityServer/Keycloak** - Containerized dev instance

### Section 7.3: Authentication Flows

| Scenario           | Flow                      | Enabled        |
| ------------------ | ------------------------- | -------------- |
| SPA Frontend       | Authorization Code + PKCE | [ ] Yes [ ] No |
| Mobile App         | Authorization Code + PKCE | [ ] Yes [ ] No |
| Service-to-Service | Client Credentials        | [ ] Yes [ ] No |
| Backend API        | JWT Bearer Validation     | [ ] Yes [ ] No |

### Section 7.4: Authorization Model

Select ONE:

- [ ] **RBAC** - Role-Based Access Control
- [ ] **Claims-Based** - Claims in JWT
- [ ] **Policy-Based** - .NET Authorization Policies / Node.js CASL
- [ ] **ABAC** - Attribute-Based Access Control

---

## Article VIII: Containers & Orchestration

> **📋 Applies to**: Application Development, Full Stack (workload infra)
> **⏭️ Skip if**: Infrastructure Only (platform level)

### Section 8.1: Container Strategy

- [ ] **Docker** - Standard containers
- [ ] **None** - PaaS only (Azure App Service)

### Section 8.2: Orchestration Platform

Select ONE:

- [ ] **Azure Kubernetes Service (AKS)** - Managed K8s
- [ ] **Azure Container Apps** - Serverless containers
- [ ] **Azure App Service** - PaaS (Containers or Code)
- [ ] **On-premises Kubernetes** - Self-managed K8s
- [ ] **Docker Compose** - Development only

### Section 8.3: Kubernetes Configuration (if AKS/K8s selected)

Package Manager:

- [ ] **Helm** - Chart-based deployments
- [ ] **Kustomize** - Overlay-based configuration

Ingress Controller:

- [ ] **NGINX Ingress** - Community standard
- [ ] **Azure Application Gateway Ingress (AGIC)** - Azure-native
- [ ] **Traefik** - Cloud-native, auto-discovery

### Section 8.4: Cloud-Native Extensions

#### KEDA (Kubernetes Event-Driven Autoscaling)

KEDA Enabled: [ ] Yes [ ] No

If Yes, select scalers:

- [ ] Azure Service Bus
- [ ] Azure Event Hubs
- [ ] Azure Storage Queue
- [ ] HTTP Request count

#### Dapr (Distributed Application Runtime)

Dapr Enabled: [ ] Yes [ ] No

If Yes, select building blocks:

| Building Block     | Enabled        | Azure Component                      |
| ------------------ | -------------- | ------------------------------------ |
| Service Invocation | [ ] Yes [ ] No | -                                    |
| State Management   | [ ] Yes [ ] No | [ ] Azure Cosmos DB [ ] Redis        |
| Pub/Sub            | [ ] Yes [ ] No | [ ] Azure Service Bus [ ] Event Hubs |
| Secrets            | [ ] Yes [ ] No | [ ] Azure Key Vault                  |

---

## Article X: Environments & Configuration 🔄

> **📋 Applies to**: ALL project types

### Section 10.1: Environment Strategy

| Environment | Purpose                      | Enabled | Auto-Deploy              |
| ----------- | ---------------------------- | ------- | ------------------------ |
| **dev**     | Development, rapid iteration | [ ] Yes | [ ] On commit to develop |
| **uat**     | User Acceptance Testing      | [ ] Yes | [ ] On PR merge          |
| **pre**     | Pre-production, staging      | [ ] Yes | [ ] Manual trigger       |
| **prod**    | Production                   | [ ] Yes | [ ] Manual approval      |

### Section 10.2: Configuration Management

Select strategy:

- [ ] **Azure App Configuration** - Centralized, feature flags (recommended)
- [ ] **Environment Variables** - Container/App Service config
- [ ] **appsettings.{Environment}.json** (.NET) / **.env files** (Node.js)
- [ ] **Combination** - App Config + Key Vault (recommended)

### Section 10.3: Secrets Management

| Secret Type        | Storage         |
| ------------------ | --------------- |
| Connection Strings | Azure Key Vault |
| API Keys           | Azure Key Vault |
| Certificates       | Azure Key Vault |

Local Development Secrets:

- [ ] **User Secrets** (.NET) - `dotnet user-secrets`
- [ ] **.env files** (Node.js) - gitignored
- [ ] **Local Key Vault** - Azure Key Vault dev instance

### Section 10.4: Feature Flags

Feature Flag Provider:

- [ ] **None**
- [ ] **Azure App Configuration** - Native integration
- [ ] **LaunchDarkly** - Enterprise features
- [ ] **Unleash** - Open-source

---

## Article XI: CI/CD Pipeline 🔄

> **📋 Applies to**: ALL project types

### Section 11.1: CI/CD Platform

Select ONE:

- [ ] **GitHub Actions** - GitHub-native
- [ ] **Azure DevOps Pipelines** - Azure-native

### Section 11.2: Pipeline Stages

#### For Application Development

| Stage                  | Enabled | Threshold                          |
| ---------------------- | ------- | ---------------------------------- |
| **Build**              | [ ] Yes | Warnings as errors: [ ] Yes [ ] No |
| **Lint/Format**        | [ ] Yes | -                                  |
| **Unit Tests**         | [ ] Yes | Coverage >= \_\_%                  |
| **Integration Tests**  | [ ] Yes | -                                  |
| **Architecture Tests** | [ ] Yes | -                                  |
| **Mutation Tests**     | [ ] Yes | Score >= \_\_%                     |
| **Security Scan**      | [ ] Yes | 0 Critical                         |
| **Container Build**    | [ ] Yes | -                                  |
| **Container Scan**     | [ ] Yes | 0 Critical                         |

#### Deployment Stages

| Stage           | Enabled | Trigger            |
| --------------- | ------- | ------------------ |
| **Deploy Dev**  | [ ] Yes | Auto on develop    |
| **Deploy UAT**  | [ ] Yes | Auto on release/\* |
| **Deploy Pre**  | [ ] Yes | Manual trigger     |
| **Deploy Prod** | [ ] Yes | Manual approval    |

### Section 11.3: Deployment Strategy

Select ONE:

- [ ] **Rolling Update** - Gradual replacement
- [ ] **Blue-Green** - Azure Deployment Slots / K8s
- [ ] **Canary** - Gradual traffic shift
- [ ] **Feature Flags** - Deploy dark, enable via flags

### Section 11.4: Branch Strategy

Select ONE:

- [ ] **GitFlow** - feature/, develop, release/, main
- [ ] **GitHub Flow** - feature/, main
- [ ] **Trunk-Based** - Short-lived branches, main

---

## Article XII: Observability 🔄

> **📋 Applies to**: ALL project types

### Section 12.1: Observability Strategy

Select ONE:

- [ ] **Azure-Native** - Azure Monitor + Application Insights
- [ ] **OpenTelemetry → Azure** - OTel SDK → Azure Monitor Exporter
- [ ] **OpenTelemetry → Grafana Stack** - Self-hosted Grafana/Loki/Tempo

### Section 12.2: Health Checks

```text
/health       - Full health check
/health/ready - Readiness probe
/health/live  - Liveness probe
```

---

## Article XIII: Testing Standards

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only (see IaC testing below)

### Section 13.1: Testing Philosophy 🟢 LOW-PRIO (thresholds are configurable)

> **🟢 LOW-PRIO**: Coverage thresholds are runtime CI/CD configs - easily adjustable

> **Coverage-First approach validated by Mutation Testing**

| Metric          | Minimum | Recommended | Tool                                 |
| --------------- | ------- | ----------- | ------------------------------------ |
| Line Coverage   | >= 80%  | >= 90%      | coverlet (.NET) / istanbul (Node.js) |
| Branch Coverage | >= 75%  | >= 85%      | coverlet (.NET) / istanbul (Node.js) |
| Mutation Score  | >= 70%  | >= 80%      | Stryker.NET / Stryker Mutator        |

### Section 13.2: Testing Frameworks 🟡 IMPORTANT

> **🟡 IMPORTANT**: Framework choice affects project structure and test patterns

#### For C#/.NET

| Type               | Framework              |
| ------------------ | ---------------------- |
| Unit Tests         | xUnit                  |
| Integration Tests  | xUnit + Testcontainers |
| Architecture Tests | NetArchTest            |
| BDD/Gherkin        | SpecFlow / Reqnroll    |
| E2E Tests          | Playwright             |
| Performance Tests  | NBomber / k6           |

#### For Node.js/TypeScript

| Type               | Framework             |
| ------------------ | --------------------- |
| Unit Tests         | Jest / Vitest         |
| Integration Tests  | Jest + Testcontainers |
| Architecture Tests | dependency-cruiser    |
| BDD/Gherkin        | Cucumber.js           |
| E2E Tests          | Playwright / Cypress  |
| Performance Tests  | k6 / Artillery        |

### Section 13.3: Test Project Structure

#### For C#/.NET

```text
tests/
├── {Module}.UnitTests/
├── {Module}.IntegrationTests/
├── Architecture.Tests/
├── E2E.Tests/
└── Common.Tests/
    ├── Fixtures/
    ├── Fakes/
    └── Builders/
```

#### For Node.js/TypeScript

```text
src/
├── modules/
│   └── {module}/
│       ├── __tests__/
│       │   ├── unit/
│       │   └── integration/
│       └── ...
tests/
├── e2e/
├── architecture/
└── fixtures/
```

---

## Article XIV: Code Standards 🟢 LOW-PRIO

> **🟢 LOW-PRIO**: Code formatting and naming conventions are enforced by linter - easy to change
> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 14.1: Naming Conventions

#### For C#/.NET

| Element        | Convention     | Example                      |
| -------------- | -------------- | ---------------------------- |
| Namespaces     | PascalCase     | `MyCompany.MyProject.Domain` |
| Classes        | PascalCase     | `OrderService`               |
| Interfaces     | I + PascalCase | `IOrderService`              |
| Methods        | PascalCase     | `GetOrderByIdAsync`          |
| Properties     | PascalCase     | `OrderId`                    |
| Private fields | \_camelCase    | `_orderRepository`           |
| Async methods  | Suffix Async   | `GetOrderByIdAsync`          |

#### For Node.js/TypeScript

| Element    | Convention       | Example            |
| ---------- | ---------------- | ------------------ |
| Files      | kebab-case       | `order-service.ts` |
| Classes    | PascalCase       | `OrderService`     |
| Interfaces | I + PascalCase   | `IOrderService`    |
| Functions  | camelCase        | `getOrderById`     |
| Variables  | camelCase        | `orderId`          |
| Constants  | UPPER_SNAKE_CASE | `MAX_RETRIES`      |

### Section 14.2: Code Formatting

#### For C#/.NET

| Setting                  | Value                                  |
| ------------------------ | -------------------------------------- |
| Indentation              | 4 spaces                               |
| Line Length              | 120 characters                         |
| File-scoped namespaces   | [ ] Yes [ ] No                         |
| Nullable reference types | [ ] Enabled (recommended) 🟡 IMPORTANT |
| Tooling                  | .editorconfig + dotnet format          |

#### For Node.js/TypeScript

| Setting     | Value                 |
| ----------- | --------------------- |
| Indentation | 2 spaces              |
| Line Length | 100 characters        |
| Semicolons  | [ ] Yes [ ] No        |
| Quotes      | [ ] Single [ ] Double |
| Tooling     | ESLint + Prettier     |

---

## Article XV: Project Structure Templates

> **📋 Applies to**: Application Development, Full Stack
> **Auto-generated based on selections above.**
> Run `/bolt.scaffold` to generate the project structure.

### Template A: C# + Modular Monolith

```text
project-root/
├── src/
│   ├── Modules/
│   │   ├── Orders/
│   │   │   ├── Orders.Domain/
│   │   │   ├── Orders.Application/
│   │   │   ├── Orders.Infrastructure/
│   │   │   └── Orders.Api/
│   │   └── Users/
│   ├── Shared/
│   │   ├── SharedKernel/
│   │   │   └── CQRS/           # Native interfaces
│   │   └── Contracts/
│   └── Api.Host/
├── tests/
│   ├── Orders.UnitTests/
│   ├── Orders.IntegrationTests/
│   └── Architecture.Tests/
├── infra/
│   └── bicep/
├── Directory.Build.props
└── Directory.Packages.props
```

### Template B: C# + Microservices

```text
project-root/
├── src/
│   ├── Services/
│   │   ├── Orders/
│   │   │   ├── Orders.Api/
│   │   │   ├── Orders.Domain/
│   │   │   ├── Orders.Application/
│   │   │   └── Orders.Infrastructure/
│   │   └── Users/
│   ├── BuildingBlocks/
│   │   ├── SharedKernel/
│   │   ├── EventBus/
│   │   └── ServiceDiscovery/
│   └── ApiGateway/
├── tests/
│   └── ...
├── infra/
│   ├── bicep/
│   └── k8s/
└── docker-compose.yml
```

### Template C: Node.js + Modular Monolith

```text
project-root/
├── src/
│   ├── modules/
│   │   ├── orders/
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── infrastructure/
│   │   │   └── api/
│   │   └── users/
│   ├── shared/
│   │   ├── kernel/
│   │   │   └── cqrs/
│   │   └── contracts/
│   └── main.ts
├── tests/
│   ├── e2e/
│   └── architecture/
├── infra/
│   └── bicep/
├── package.json
└── tsconfig.json
```

### Template D: Node.js + Microservices

```text
project-root/
├── services/
│   ├── orders/
│   │   ├── src/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── users/
├── packages/
│   ├── shared-kernel/
│   ├── event-bus/
│   └── service-discovery/
├── infra/
│   ├── bicep/
│   └── k8s/
├── docker-compose.yml
└── package.json (workspaces)
```

---

## Article XVI: Security Policies 🔄 🟡 IMPORTANT

> **🟡 IMPORTANT**: Security configuration affects compliance and data protection
> **📋 Applies to**: ALL project types

### Section 16.1: Network Security

| Component                | Configuration                     |
| ------------------------ | --------------------------------- |
| Virtual Network          | [ ] Azure VNet [ ] None           |
| Private Endpoints        | [ ] Enabled [ ] Disabled          |
| Web Application Firewall | [ ] Azure Front Door WAF [ ] None |

### Section 16.2: Data Protection

| Policy                | Value                                                 |
| --------------------- | ----------------------------------------------------- |
| Encryption at Rest    | [ ] Azure-managed keys [ ] Customer-managed keys      |
| Encryption in Transit | TLS 1.2+ (mandatory)                                  |
| PII Handling          | [ ] Anonymization [ ] Pseudonymization [ ] Encryption |

### Section 16.3: Compliance Requirements

| Standard | Required       |
| -------- | -------------- |
| GDPR     | [ ] Yes [ ] No |
| HIPAA    | [ ] Yes [ ] No |
| SOC 2    | [ ] Yes [ ] No |
| PCI-DSS  | [ ] Yes [ ] No |

---

## Article XVII: Legacy & Migration 🟡 IMPORTANT

> **🟡 IMPORTANT**: Migration strategy affects implementation approach and timeline
> **📋 Applies to**: Application Development, Full Stack (if migrating)
> **⏭️ Skip if**: Greenfield Infrastructure Only

### Section 17.1: Migration Context

Select ONE:

- [ ] **Greenfield** - New project, no legacy
- [ ] **Brownfield** - Existing codebase enhancement
- [ ] **Legacy Migration** - Full rewrite/refactor
- [ ] **Strangler Fig** - Incremental replacement

### Section 17.2: Migration Strategy (if applicable)

Select ONE:

- [ ] **Big Bang** - Full rewrite, cutover
- [ ] **Strangler Fig** - Incremental replacement
- [ ] **Branch by Abstraction** - Parallel implementations

---

## Article XVIII: API Management

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 18.1: API Gateway

Select ONE:

- [ ] **None** - Direct service access
- [ ] **Azure API Management (APIM)** - Full-featured
- [ ] **Azure Front Door** - Global routing + WAF
- [ ] **YARP** - .NET reverse proxy

### Section 18.2: API Features

| Feature        | Enabled        | Configuration                |
| -------------- | -------------- | ---------------------------- |
| Rate Limiting  | [ ] Yes [ ] No | \_\_\_ requests/minute       |
| API Versioning | [ ] Yes [ ] No | Strategy: [ ] URL [ ] Header |

### Section 18.3: API Documentation

| Type         | Tool              | Enabled        |
| ------------ | ----------------- | -------------- |
| REST API     | OpenAPI / Swagger | [ ] Yes        |
| Async Events | AsyncAPI          | [ ] Yes [ ] No |

---

## Article XIX: Governance 🔄

> **📋 Applies to**: ALL project types

### Section 19.1: Constitution Amendments

1. **Proposal**: Any team member may propose amendments
2. **Review**: Tech Lead + Architect review required
3. **Approval**: Majority approval from signatories
4. **Implementation**: Update constitution + notify AI agents
5. **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)

### Section 19.2: AI Agent Compliance

All AI agents operating in this project MUST:

1. **Read** this constitution before any operation
2. **Validate** all decisions against constitution principles
3. **FAIL** operations that violate constitution
4. **Request** amendment for justified exceptions
5. **Log** all constitution checks for audit

---

## Signatories

| Role         | Name   | Date   | Signature |
| ------------ | ------ | ------ | --------- |
| Project Lead | [NAME] | [DATE] |           |
| Tech Lead    | [NAME] | [DATE] |           |
| Architect    | [NAME] | [DATE] |           |

---

## Revision History

| Version | Date   | Author   | Changes                                                                                    |
| ------- | ------ | -------- | ------------------------------------------------------------------------------------------ |
| 2.1.0   | [DATE] | [AUTHOR] | Added Project Scope (App/Infra/Full Stack), Landing Zone templates, Infrastructure testing |
| 2.0.0   | [DATE] | [AUTHOR] | Complete rewrite with C#/Node.js options                                                   |
| 1.0.0   | [DATE] | [AUTHOR] | Initial constitution                                                                       |
