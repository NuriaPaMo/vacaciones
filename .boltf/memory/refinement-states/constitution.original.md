# BOLT Framework Project Constitution

> **Version**: 1.0.0
> **Ratification Date**: [YYYY-MM-DD]
> **Last Amended**: [YYYY-MM-DD]
> **Status**: Template

---

## Preamble

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article I: Project Scope & Type

> **⚠️ IMPORTANT**: Select the project scope FIRST. This determines which sections apply.

### Section 1.0: Project Scope

Select ONE:

- [ ] **🏗️ Infrastructure Only** - Landing Zone, Platform, IaC
  - *Applies*: Articles VIII, IX, X (IaC, Environments, CI/CD for Infra)
  - *Skip*: Application development articles (II-VII, XI-XIV)

- [ ] **💻 Application Development Only** - App code on existing infrastructure
  - *Applies*: Articles II-VII, X-XIV (Architecture, Code, Testing, etc.)
  - *Skip*: Infrastructure articles, assumes infra exists

- [ ] **🚀 Full Stack (App + Infrastructure)** - Complete project
  - *Applies*: ALL articles
  - *Recommended for*: Greenfield projects, complete solutions

### Section 1.0.1: Infrastructure Scope (if Infrastructure or Full Stack)

- [ ] **Landing Zone** - Enterprise-scale foundation
  - Management Groups, Subscriptions, Policies
  - Hub-Spoke / Virtual WAN networking
  - Identity foundation (Entra ID integration)
  - Governance, Cost Management, Security Center

- [ ] **Workload Infrastructure** - Application-specific resources
  - Compute, Storage, Databases
  - Networking (VNets, Subnets, NSGs)
  - Identity (Managed Identities, RBAC)

- [ ] **Both** - Landing Zone + Workload

---

## Article II: Application Configuration

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 2.1: Backend Language & Runtime

Select ONE:

- [ ] **C# / .NET**
  - Version: [ ] .NET 8 (LTS) [ ] .NET 10
  - API Style: [ ] Minimal APIs [ ] Controllers (MVC) [ ] Azure Functions

- [ ] **Node.js / TypeScript**
  - Version: [ ] Node.js 20 LTS [ ] Node.js 22
  - Framework: [ ] Express [ ] Fastify [ ] NestJS [ ] Azure Functions

### Section 2.2: Frontend Framework

Select ONE:

- [ ] **Vue.js** - Version: [ ] 3.x
- [ ] **React** - Version: [ ] 18.x [ ] 19.x
- [ ] **Angular** - Version: [ ] 17.x [ ] 18.x [ ] 19.x
- [ ] **Blazor** - Type: [ ] Server [ ] WebAssembly [ ] Hybrid
- [ ] **None** - API only (headless)

### Section 2.3: Mobile Application

Select ONE:

- [ ] **None** - No mobile app
- [ ] **.NET MAUI** - Cross-platform native
- [ ] **React Native** - Cross-platform with React
- [ ] **Flutter** - Cross-platform with Dart
- [ ] **Blazor Hybrid** - .NET MAUI + Blazor

---

## Article III: Application Architecture

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 3.1: Backend Architecture Style

Select ONE:

- [ ] **Microservices** - Independent deployable services
- [ ] **Modular Monolith** - Single deployment, modular boundaries
- [ ] **Traditional Monolith** - Single deployment, layered
- [ ] **Serverless** - Azure Functions based
- [ ] **Event-Driven / CQRS+ES** - Commands, queries, event sourcing

### Section 3.2: Frontend Architecture Style

Select ONE:

- [ ] **Micro-frontends** - Module Federation, independent teams
- [ ] **Monolith SPA** - Single SPA application
- [ ] **Server-rendered (SSR/MPA)** - Server-side rendering
- [ ] **Static Site (SSG)** - Pre-built static pages
- [ ] **None** - API only

### Section 3.3: CQRS Configuration

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

### Section 3.4: Event Sourcing Configuration

Event Sourcing Enabled: [ ] Yes [ ] No

If Yes, select Event Store:

- [ ] **EventStoreDB** - Purpose-built event store
- [ ] **Azure Cosmos DB** - Change Feed for events
- [ ] **SQL Server / PostgreSQL** - Outbox pattern with projections

---

## Article IV: Communication

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 4.1: Communication Style

Select ONE:

- [ ] **Synchronous only** - REST, gRPC
- [ ] **Asynchronous only** - Messages, Events
- [ ] **Hybrid** - Both sync and async

### Section 4.2: Synchronous Communication

- [ ] **REST API** - Enabled
- [ ] **gRPC** - Enabled
- [ ] **GraphQL** - [ ] None [ ] HotChocolate (.NET) [ ] Apollo (Node.js)

### Section 4.3: Asynchronous Communication

Message Broker - Select ONE:

- [ ] **None**
- [ ] **Azure Service Bus** - Cloud-native, enterprise
- [ ] **Azure Event Hubs** - High-throughput streaming
- [ ] **RabbitMQ** - On-premises, flexible
- [ ] **Azure Storage Queues** - Simple, cost-effective

Background Processing - Select ONE or more:

- [ ] **None**
- [ ] **.NET BackgroundService** / **Node.js Worker Threads**
- [ ] **Azure Functions** - Serverless triggers
- [ ] **Hangfire** (.NET) / **BullMQ** (Node.js) - Persistent jobs

---

## Article V: Data Storage

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 5.1: Primary Database

Select ONE:

- [ ] **Azure SQL Database** - Managed SQL Server
- [ ] **SQL Server** - On-premises
- [ ] **PostgreSQL** - Azure Database for PostgreSQL / On-premises
- [ ] **Azure Cosmos DB** - NoSQL, globally distributed
- [ ] **MongoDB** - Document database

### Section 5.2: Data Access Pattern

#### For C#/.NET

- [ ] **Entity Framework Core** - Full ORM
- [ ] **Dapper** - Micro-ORM, performance-focused
- [ ] **EF Core + Dapper** - EF for writes, Dapper for reads (CQRS)

#### For Node.js/TypeScript

- [ ] **Prisma** - Type-safe ORM
- [ ] **TypeORM** - Active Record / Data Mapper
- [ ] **Drizzle** - Lightweight, SQL-like
- [ ] **Knex.js** - Query builder

Repository Pattern: [ ] Yes [ ] No
Unit of Work Pattern: [ ] Yes [ ] No

### Section 5.3: Database Migrations

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

### Section 6.1: Cache Levels

| Level                | Technology                                 | Enabled        | TTL Default    |
| -------------------- | ------------------------------------------ | -------------- | -------------- |
| **L1 - In-Memory**   | IMemoryCache (.NET) / node-cache (Node.js) | [ ] Yes [ ] No | \_\_\_ minutes |
| **L2 - Distributed** | (see below)                                | [ ] Yes [ ] No | \_\_\_ minutes |
| **L3 - CDN**         | (see below)                                | [ ] Yes [ ] No | \_\_\_ hours   |

### Section 6.2: Distributed Cache (L2)

Select ONE:

- [ ] **None**
- [ ] **Azure Cache for Redis** - Managed Redis
- [ ] **Redis** - On-premises / Self-hosted

### Section 6.3: CDN (L3)

Select ONE:

- [ ] **None**
- [ ] **Azure CDN** - Static content caching
- [ ] **Azure Front Door** - Global load balancing + CDN

### Section 6.4: Cache Patterns

- [ ] **Cache-Aside** - Application manages cache
- [ ] **Read-Through** - Cache loads on miss
- [ ] **Write-Through** - Cache writes to source
- [ ] **Write-Behind** - Async persistence

---

## Article VII: Identity & Access Management

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 7.1: Identity Provider (Production)

Select ONE:

- [ ] **Microsoft Entra ID (Azure AD)** - Enterprise/Internal users
- [ ] **Azure AD B2C** - Customer-facing (CIAM)
- [ ] **Duende IdentityServer** - Self-hosted OIDC (.NET)
- [ ] **Keycloak** - Open-source, self-hosted
- [ ] **Auth0** - Managed identity service

### Section 7.2: Identity Provider (Development/Testing)

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

## Article IX: Infrastructure as Code

> **📋 Applies to**: Infrastructure Only, Full Stack
> **⏭️ Skip if**: Application Development Only (assumes infra exists)

### Section 9.1: IaC Tool

Select ONE:

- [ ] **Bicep** - Azure-native, recommended
- [ ] **Terraform** - Multi-cloud, HCL
- [ ] **Pulumi** - Programmatic (.NET/TypeScript)
- [ ] **ARM Templates** - Azure legacy JSON

### Section 9.2: IaC Structure

```text
infra/
├── bicep/                      # or terraform/
│   ├── modules/
│   │   ├── networking/
│   │   ├── compute/
│   │   ├── data/
│   │   └── security/
│   ├── environments/
│   │   ├── dev.bicepparam
│   │   ├── uat.bicepparam
│   │   ├── pre.bicepparam
│   │   └── prod.bicepparam
│   └── main.bicep
├── k8s/                        # If using Kubernetes
│   ├── helm/
│   └── kustomize/
└── scripts/
    └── deploy.ps1
```

### Section 9.3: Landing Zone Configuration

> **📋 Applies to**: Infrastructure Only (Landing Zone scope), Full Stack (if deploying platform)

Landing Zone Pattern: [ ] CAF Enterprise-Scale [ ] Start-Small (single subscription)

#### If CAF Enterprise-Scale

| Component                  | Enabled                       | Notes                                                |
| -------------------------- | ----------------------------- | ---------------------------------------------------- |
| Management Group Hierarchy | [ ] Yes                       | Platform, Landing Zones, Decommissioned, Sandboxes   |
| Connectivity               | [ ] Hub-Spoke [ ] Virtual WAN | Central networking                                   |
| Identity                   | [ ] Yes                       | Entra ID integration, Privileged Identity Management |
| Management                 | [ ] Yes                       | Azure Monitor, Log Analytics, Automation             |
| Security                   | [ ] Yes                       | Microsoft Defender for Cloud, Sentinel (optional)    |

#### Governance Components

| Policy                   | Enabled        | Scope                             |
| ------------------------ | -------------- | --------------------------------- |
| Azure Policy Initiatives | [ ] Yes        | [ ] Built-in ALZ [ ] Custom       |
| Azure RBAC Custom Roles  | [ ] Yes        | -                                 |
| Azure Blueprints         | [ ] Yes [ ] No | Deprecated, use Deployment Stacks |
| Cost Management Budgets  | [ ] Yes        | Per subscription/resource group   |
| Resource Tags            | [ ] Yes        | Required tags: \_\_\_             |

#### Landing Zone Structure (Bicep)

```text
infra/
├── platform/
│   ├── management-groups/
│   │   └── main.bicep
│   ├── policies/
│   │   ├── initiatives/
│   │   └── assignments/
│   ├── connectivity/
│   │   ├── hub-network.bicep
│   │   ├── dns-zones.bicep
│   │   └── firewall.bicep
│   ├── identity/
│   │   └── main.bicep
│   └── management/
│       ├── log-analytics.bicep
│       └── automation.bicep
├── landing-zones/
│   ├── templates/
│   │   ├── corp/           # Internal workloads
│   │   └── online/         # Public-facing workloads
│   └── subscriptions/
│       └── {workload-name}/
└── scripts/
    ├── deploy-platform.ps1
    └── deploy-landing-zone.ps1
```

---

## Article X: Environments & Configuration

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

## Article XI: CI/CD Pipeline

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

#### For Infrastructure

| Stage                | Enabled | Threshold           |
| -------------------- | ------- | ------------------- |
| **IaC Lint**         | [ ] Yes | Bicep lint / tflint |
| **IaC Validation**   | [ ] Yes | what-if / plan      |
| **Security Scan**    | [ ] Yes | Checkov / tfsec     |
| **Cost Estimation**  | [ ] Yes | Infracost           |
| **Compliance Check** | [ ] Yes | Azure Policy        |

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

## Article XII: Observability

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

### Section 12.3: Infrastructure Monitoring (if Infrastructure scope)

| Component       | Tool                      | Enabled |
| --------------- | ------------------------- | ------- |
| Resource Health | Azure Resource Health     | [ ] Yes |
| Activity Logs   | Azure Monitor             | [ ] Yes |
| Diagnostics     | Log Analytics             | [ ] Yes |
| Alerts          | Azure Monitor Alerts      | [ ] Yes |
| Dashboards      | Azure Workbooks / Grafana | [ ] Yes |

---

## Article XIII: Testing Standards

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only (see IaC testing below)

### Section 13.1: Testing Philosophy

> **Coverage-First approach validated by Mutation Testing**

| Metric          | Minimum | Recommended | Tool                                 |
| --------------- | ------- | ----------- | ------------------------------------ |
| Line Coverage   | >= 80%  | >= 90%      | coverlet (.NET) / istanbul (Node.js) |
| Branch Coverage | >= 75%  | >= 85%      | coverlet (.NET) / istanbul (Node.js) |
| Mutation Score  | >= 70%  | >= 80%      | Stryker.NET / Stryker Mutator        |

### Section 13.2: Testing Frameworks

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

### Section 13.4: Infrastructure Testing (if Infrastructure scope)

| Test Type         | Tool                   | Purpose                    |
| ----------------- | ---------------------- | -------------------------- |
| IaC Lint          | Bicep linter / tflint  | Syntax and best practices  |
| Security Scan     | Checkov / tfsec        | Security misconfigurations |
| Policy Compliance | Azure Policy (what-if) | Governance validation      |
| Integration Test  | Pester / Terratest     | Post-deployment validation |
| Cost Estimation   | Infracost              | Budget validation          |

---

## Article XIV: Code Standards

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

| Setting                  | Value                         |
| ------------------------ | ----------------------------- |
| Indentation              | 4 spaces                      |
| Line Length              | 120 characters                |
| File-scoped namespaces   | [ ] Yes [ ] No                |
| Nullable reference types | [ ] Enabled (recommended)     |
| Tooling                  | .editorconfig + dotnet format |

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
> Run `/boltf.scaffold` to generate the project structure.

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

### Template E: Infrastructure Only - Landing Zone

```text
project-root/
├── platform/
│   ├── management-groups/
│   │   ├── main.bicep
│   │   └── modules/
│   ├── policies/
│   │   ├── initiatives/
│   │   │   ├── security.bicep
│   │   │   └── tagging.bicep
│   │   ├── definitions/
│   │   └── assignments/
│   ├── connectivity/
│   │   ├── hub-network/
│   │   │   ├── main.bicep
│   │   │   ├── firewall.bicep
│   │   │   └── bastion.bicep
│   │   ├── dns/
│   │   │   └── private-dns-zones.bicep
│   │   └── vwan/                 # If Virtual WAN
│   ├── identity/
│   │   ├── main.bicep
│   │   └── rbac-assignments.bicep
│   └── management/
│       ├── log-analytics.bicep
│       ├── automation.bicep
│       └── defender.bicep
├── landing-zones/
│   ├── templates/
│   │   ├── corp-workload/
│   │   │   ├── main.bicep
│   │   │   └── parameters/
│   │   └── online-workload/
│   │       ├── main.bicep
│   │       └── parameters/
│   └── subscriptions/
│       └── README.md             # Instructions for new workloads
├── modules/
│   ├── networking/
│   ├── security/
│   ├── compute/
│   └── data/
├── tests/
│   ├── policy-compliance/
│   ├── integration/
│   └── security-scan/
├── pipelines/
│   ├── platform-deploy.yml
│   └── landing-zone-deploy.yml
├── docs/
│   ├── architecture/
│   └── runbooks/
└── README.md
```

### Template F: Infrastructure Only - Workload

```text
project-root/
├── infra/
│   ├── bicep/                    # or terraform/
│   │   ├── main.bicep
│   │   ├── modules/
│   │   │   ├── networking/
│   │   │   │   ├── vnet.bicep
│   │   │   │   └── nsg.bicep
│   │   │   ├── compute/
│   │   │   │   ├── aks.bicep
│   │   │   │   └── container-apps.bicep
│   │   │   ├── data/
│   │   │   │   ├── sql.bicep
│   │   │   │   └── cosmos.bicep
│   │   │   └── security/
│   │   │       ├── keyvault.bicep
│   │   │       └── managed-identity.bicep
│   │   └── environments/
│   │       ├── dev.bicepparam
│   │       ├── uat.bicepparam
│   │       ├── pre.bicepparam
│   │       └── prod.bicepparam
│   └── k8s/                      # If AKS
│       ├── helm/
│       └── kustomize/
├── tests/
│   ├── bicep-lint/
│   ├── security/
│   └── post-deploy/
├── pipelines/
│   └── infra-deploy.yml
├── docs/
│   └── architecture.md
└── README.md
```

---

## Article XVI: Security Policies

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

## Article XVII: Legacy & Migration

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

## Article XIX: Governance

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

### Agent Checklist

Before generating code or making changes:

#### For Application Development / Full Stack

- [ ] Project scope matches Article I selection
- [ ] Language/Runtime matches Article II
- [ ] Architecture follows Article III
- [ ] CQRS uses native interfaces (no MediatR for .NET) per Section 3.3
- [ ] Communication patterns match Article IV
- [ ] Data access follows Article V
- [ ] Caching strategy per Article VI
- [ ] Identity/Auth per Article VII
- [ ] Container/K8s config per Article VIII
- [ ] IaC follows Article IX structure
- [ ] Environment config per Article X
- [ ] CI/CD per Article XI
- [ ] Observability per Article XII
- [ ] Testing meets Article XIII thresholds
- [ ] Code standards per Article XIV
- [ ] Project structure per Article XV

#### For Infrastructure Only

- [ ] Project scope is Infrastructure per Article I
- [ ] Landing Zone or Workload scope per Section 1.0.1
- [ ] IaC tool and structure per Article IX
- [ ] Environment strategy per Article X
- [ ] CI/CD for infra per Article XI
- [ ] Observability per Article XII
- [ ] Infrastructure testing per Section 13.4
- [ ] Security policies per Article XVI

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
