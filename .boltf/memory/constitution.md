# Bolt Framework Project Constitution

> **Generated**: 2026-08-05 13:35:00
> **Practice**: Apps & Infra
> **Project Type**: full-stack (green)
> **Active Scopes**: backend, frontend, cloud-platform
> **Version**: 1.0.0
> **Status**: Ratified

---

This constitution contains only articles explicitly approved during refinement.

---

# Scope: backend

## Article II: Backend Language & Runtime

- **Language**: C# / .NET 10
- **API Style**: Minimal APIs
- **Cloud Provider**: Microsoft Azure (mandatory)

---

## Article III: Application Architecture

- **Architecture Style**: Modular Monolith — single deployment, modular boundaries
- **CQRS**: Enabled — Simple CQRS (same model, separated handlers)
- **Event Sourcing**: Disabled

### Native CQRS Interfaces (NO MediatR)

```csharp
public interface ICommand { }
public interface ICommandHandler<in TCommand> where TCommand : ICommand
{
    Task HandleAsync(TCommand command, CancellationToken ct = default);
}
public interface ICommandHandler<in TCommand, TResult> where TCommand : ICommand
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken ct = default);
}
public interface IQuery<TResult> { }
public interface IQueryHandler<in TQuery, TResult> where TQuery : IQuery<TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken ct = default);
}
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

---

## Article IV: Communication

- **Style**: Hybrid — synchronous + asynchronous
- **Synchronous**: REST API (no gRPC, no GraphQL)
- **Asynchronous Message Broker**: Azure Service Bus (cloud-native, enterprise)
- **Background Processing**: .NET BackgroundService (native, no extra dependencies)

---

## Article V: Data Storage

- **Primary Database**: Azure SQL Database (Managed SQL Server)
- **Data Access**:
  - Writes: Entity Framework Core (ORM)
  - Reads: Dapper (micro-ORM, performance-focused)
- **Repository Pattern**: Enabled
- **Unit of Work Pattern**: Enabled
- **Database Migrations**: EF Core Migrations (code-first)

---

## Article VI: Caching Strategy

- **L1 In-Memory**: Enabled (IMemoryCache) — TTL: 5 minutes default
- **L2 Distributed**: Azure Cache for Redis — TTL: 30 minutes default
- **L3 CDN**: None (managed by frontend/cloud-platform scope)
- **Cache Pattern**: Cache-Aside (application manages cache)

---

## Article VII: Identity & Access Management

- **Identity Provider (Production)**: Microsoft Entra ID (Azure AD)
- **Identity Provider (Development/Testing)**: Mock IDP (in-memory, fake tokens)
- **Authentication Flows**:
  - SPA Frontend: Authorization Code + PKCE — Enabled
  - Service-to-Service: Client Credentials — Enabled
  - Backend API: JWT Bearer — Enabled
  - Mobile App: Disabled
- **Authorization Model**: Policy-Based (.NET Authorization Policies)

---

## Article X: Environments & Configuration

- **Environments**:
  - dev — Development, rapid iteration — Auto-deploy on commit to develop
  - prod — Production — Manual approval
- **Configuration Management**: appsettings.{Environment}.json + environment variables
- **Secrets Management**: Azure Key Vault (production) / .env files gitignored (local dev)
- **Feature Flags**: None

---

## Article XI: CI/CD Pipeline

- **Platform**: Azure DevOps Pipelines
- **Branch Strategy**: GitFlow (feature/, develop, release/, main)
- **Deployment Strategy**: Rolling Update
- **Pipeline Stages (Application)**:
  - Build (warnings as errors: Yes)
  - Lint/Format
  - Unit Tests (coverage >= 80%)
  - Security Scan (0 Critical)
- **Deployment Stages**:
  - Deploy Dev — Auto on commit to develop
  - Deploy Prod — Manual approval
- **IaC Tool**: Terraform

---

## Article XII: Observability

- **Strategy**: OpenTelemetry → Azure Monitor Exporter (OTel SDK)
- **Health Check Endpoints**:
  - /health — Full health check
  - /health/ready — Readiness probe
  - /health/live — Liveness probe

---

## Article XIII: Testing Standards (Backend)

- **Philosophy**: Coverage-First validated by Mutation Testing
- **Thresholds**:
  - Line Coverage: >= 80% (coverlet)
  - Branch Coverage: >= 75% (coverlet)
  - Mutation Score: >= 70% (Stryker.NET) — deferred to later sprint
- **Frameworks**:
  - Unit Tests: xUnit
  - Integration Tests: xUnit + Testcontainers
  - Architecture Tests: NetArchTest
  - BDD/Gherkin: Reqnroll
  - E2E Tests: Playwright
  - Performance Tests: k6
- **Test Project Structure**:
  ```
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

---

## Article XIV: Code Standards (Backend)

### Naming Conventions (C#/.NET)

| Element        | Convention     | Example                      |
|----------------|----------------|------------------------------|
| Namespaces     | PascalCase     | MyCompany.MyProject.Domain   |
| Classes        | PascalCase     | OrderService                 |
| Interfaces     | I + PascalCase | IOrderService                |
| Methods        | PascalCase     | GetOrderByIdAsync            |
| Properties     | PascalCase     | OrderId                      |
| Private fields | _camelCase     | _orderRepository             |
| Async methods  | Suffix Async   | GetOrderByIdAsync            |

### Code Formatting

| Setting                  | Value                         |
|--------------------------|-------------------------------|
| Indentation              | 4 spaces                      |
| Line Length              | 120 characters                |
| File-scoped namespaces   | Yes                           |
| Nullable reference types | Enabled                       |
| Tooling                  | .editorconfig + dotnet format |

---

## Article XVI: Security Policies (Backend)

- **Network Security**: No VNet, no Private Endpoints, no WAF (can be added later)
- **Encryption at Rest**: Azure-managed keys
- **Encryption in Transit**: TLS 1.2+ (mandatory)
- **PII Handling**: Encryption
- **Compliance**: GDPR required

---

## Article XVII: Legacy & Migration

- **Context**: Greenfield — new project, no legacy code

---

## Article XIX: Governance

### Constitution Amendments
1. **Proposal**: Any team member may propose amendments
2. **Review**: Tech Lead + Architect review required
3. **Approval**: Majority approval from signatories
4. **Implementation**: Update constitution + notify AI agents
5. **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)

### AI Agent Compliance
All AI agents MUST:
1. Read this constitution before any operation
2. Validate all decisions against constitution principles
3. FAIL operations that violate constitution
4. Request amendment for justified exceptions
5. Log all constitution checks for audit

---

# Scope: frontend

## Article II §2.2: Frontend Framework

- **Framework**: Vue.js 3.x
- **Language**: TypeScript
- **Build Tool**: Vite

---

## Article II §2.3: Mobile Application

- **Mobile**: None — no mobile app

---

## Article II §2.4: Design Tooling

- **Design Tool**: None — HTML mockups only (bolt-mockup / bolt-ux-design)
- **Design Gate**: Inactive (no Penpot integration)
- **Token Pipeline**: Not applicable

---

## Article III §3.2: Frontend Architecture Style

- **Style**: Monolith SPA (Single Page Application)
- **Hosting**: Azure Static Web Apps
- **Routing**: Vue Router
- **State Management**: Pinia

---

## Article VII: Identity & Access Management (Frontend)

- **Authentication Flow (SPA)**: Authorization Code + PKCE (Entra ID)
- **Library**: MSAL.js v3 (@azure/msal-browser + @azure/msal-vue)
- **Authorization**: Claims-based routing guards (Vue Router)
- **Mobile App Auth**: Not applicable

---

## Article X: Environments & Configuration (Frontend)

- **Environments**: dev, prod
- **Configuration**: .env files (Vite VITE_* variables, gitignored for secrets)
- **Secrets (local)**: .env.local (gitignored)
- **Feature Flags**: None

---

## Article XI: CI/CD Pipeline (Frontend)

- **Platform**: Azure DevOps Pipelines
- **Branch Strategy**: GitFlow (feature/, develop, release/, main)
- **Deployment Strategy**: Rolling Update
- **Pipeline Stages**:
  - Build (Vite)
  - Lint/Format (ESLint + Prettier)
  - Unit Tests (coverage >= 80%)
  - E2E Tests (Playwright)
  - Security Scan (0 Critical)
  - Deploy to Azure Static Web Apps
- **Deployment**:
  - Deploy Dev — Auto on commit to develop
  - Deploy Prod — Manual approval

---

## Article XII: Observability (Frontend)

- **Strategy**: Azure Application Insights JavaScript SDK
- **Tracking**: Automatic exception tracking, dependency tracking, RUM
- **Core Web Vitals**: Monitored via Application Insights

---

## Article XIII: Testing Standards (Frontend)

- **Philosophy**: Coverage-First validated by Mutation Testing
- **Thresholds**:
  - Line Coverage: >= 80% (istanbul/v8)
  - Branch Coverage: >= 75% (istanbul/v8)
  - Mutation Score: >= 70% (Stryker Mutator) — deferred
- **Frameworks**:
  - Unit Tests: Vitest
  - Component Tests: Vue Testing Library (@testing-library/vue)
  - E2E Tests: Playwright
  - Visual Regression: Playwright screenshots
  - Performance: Lighthouse CI (Core Web Vitals)

---

## Article XIV: Code Standards (Frontend)

### Naming Conventions (TypeScript/Vue)

| Element     | Convention       | Example            |
|-------------|------------------|--------------------|
| Files       | kebab-case       | order-detail.vue   |
| Components  | PascalCase       | OrderDetail.vue    |
| Composables | use + camelCase  | useOrderStore.ts   |
| Interfaces  | I + PascalCase   | IOrderService      |
| Functions   | camelCase        | getOrderById       |
| Variables   | camelCase        | orderId            |
| Constants   | UPPER_SNAKE_CASE | MAX_RETRIES        |

### Code Formatting

| Setting     | Value             |
|-------------|-------------------|
| Indentation | 2 spaces          |
| Line Length | 100 characters    |
| Semicolons  | No                |
| Quotes      | Single            |
| Tooling     | ESLint + Prettier |

---

## Article XVI: Security Policies (Frontend)

- **Encryption in Transit**: TLS 1.2+ (mandatory, Azure Static Web Apps enforced)
- **WAF**: None (can add Azure Front Door WAF later)
- **PII Handling**: No PII stored client-side; encryption server-side
- **Compliance**: GDPR — no analytics cookies without consent

---

# Scope: cloud-platform

## Article VIII §8.1: Container Strategy

- **Strategy**: Docker (standard containers)
- **Runtime**: Docker (local dev) / Azure Container Apps (production)

---

## Article VIII §8.2: Orchestration Platform

- **Platform**: Azure Container Apps (serverless containers)
- **Benefits**: No K8s cluster management, auto-scaling, native Azure integration
- **Local Dev**: Docker

---

## Article VIII-B §8B.1: Infrastructure Scope

- **Scope**: Workload Infrastructure only
- **Workload Components**:
  - Compute: Azure Container Apps
  - Data: Azure SQL Database + Azure Cache for Redis
  - Integration: Azure Service Bus
  - Frontend Hosting: Azure Static Web Apps
  - Secrets: Azure Key Vault
  - Identity: Microsoft Entra ID
  - Monitoring: Azure Monitor + Application Insights
- **Assumption**: Platform/networking provided by existing subscription

---

## Article VIII-C: .NET Aspire Orchestration

- **Aspire**: Enabled (local development orchestration)
- **AppHost**: src/AppHost/ — defines service topology
- **ServiceDefaults**: src/ServiceDefaults/ — shared OTel, health checks, resilience
- **Service Discovery**: Aspire automatic (WithReference() API)
- **Dashboard**: http://localhost:15888 (local OTel observability)
- **Production**: Deploy via azd up or Azure DevOps pipeline (Container Apps)
- **Note**: Aspire is for local dev only; production uses Azure Container Apps directly

---

## Article IX §9.1: Infrastructure as Code

- **IaC Tool**: Terraform (HCL)
- **State Backend**: Azure Storage Account (remote state)
- **Modules**: container-apps, sql, redis, service-bus, static-web-apps, key-vault
- **Environments**: dev.tfvars, prod.tfvars

---

## Article X: Environments & Configuration (Cloud Platform)

- **Environments**: dev, prod
- **Terraform Workspaces**: one per environment (dev, prod)
- **Secrets**: Azure Key Vault (one vault per environment)
- **Feature Flags**: None

---

## Article XI: CI/CD Pipeline (Infrastructure)

- **Platform**: Azure DevOps Pipelines
- **Branch Strategy**: GitFlow
- **IaC Pipeline Stages**:
  - IaC Lint (tflint)
  - IaC Validation (terraform plan)
  - Security Scan (Checkov / tfsec — 0 Critical)
  - Cost Estimation (Infracost)
  - Deploy Dev — Auto on commit to develop
  - Deploy Prod — Manual approval

---

## Article XII: Observability & Infrastructure Monitoring

- **Strategy**: OpenTelemetry → Azure Monitor Exporter
- **Infrastructure Monitoring** (all enabled):
  - Activity Logs — Azure Monitor
  - Diagnostics — Log Analytics Workspace
  - Alerts — Azure Monitor Alerts
  - Dashboards — Azure Workbooks
  - Resource Health — Azure Resource Health

---

## Article XIII §13.4: Infrastructure Testing

| Test Type       | Tool            | Purpose                    |
|-----------------|-----------------|----------------------------|
| IaC Lint        | tflint          | Syntax and best practices  |
| Security Scan   | Checkov / tfsec | Security misconfigurations |
| Cost Estimation | Infracost       | Budget validation          |
| Integration     | Terratest (Go)  | Post-deployment validation |

---

## Article XVI: Security Policies (Cloud Platform)

- **Network**: No VNet / No Private Endpoints (simplicity for greenfield)
- **Encryption at Rest**: Azure-managed keys
- **Encryption in Transit**: TLS 1.2+ (mandatory)
- **Compliance**: GDPR required
- **Container Security**: Managed identity for Container Apps (no secrets in env vars)

---

## Constitution Metadata

- **Generated**: 2026-08-05 13:35:00
- **Source**: Merged refinement from 3 scopes (backend, frontend, cloud-platform)
- **Articles Included**: 37
- **Articles Excluded/Skipped**: 2
- **Total Reviewed**: 39

*Only articles with decision='include' or decision='modified' are present in this constitution.*
