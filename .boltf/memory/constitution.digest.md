# Constitution Digest — Token-Optimized Reference

> **Source**: constitution.md (canonical)
> **Generated**: 2026-08-05 13:35:00
> **Scopes**: backend · frontend · cloud-platform
> **Purpose**: Tier-1 read for AI agents (~1–2K tokens). Every binding decision present.
> **Full constitution**: `.boltf/memory/constitution.md`

---

## SCOPE: backend

| Article | Decision |
|---------|----------|
| **II — Language** | C# / .NET 10 · Minimal APIs · Azure (mandatory) |
| **III — Architecture** | Modular Monolith · Simple CQRS · NO MediatR · No Event Sourcing |
| **IV — Communication** | Hybrid: REST API (sync) + Azure Service Bus (async) · .NET BackgroundService |
| **V — Data** | Azure SQL Database · EF Core (writes) + Dapper (reads) · Repository + UoW · EF Core Migrations |
| **VI — Caching** | L1 IMemoryCache (5 min) · L2 Azure Cache for Redis (30 min) · Cache-Aside |
| **VII — Identity** | Entra ID (prod) · Mock IDP (dev/test) · Auth Code+PKCE (SPA) · Client Credentials (S2S) · JWT Bearer (API) · Policy-Based authz |
| **X — Environments** | dev (auto-deploy) · prod (manual approval) · appsettings.json + env vars · Key Vault (prod) / .env (local) · No feature flags |
| **XI — CI/CD** | Azure DevOps · GitFlow · Rolling Update · Stages: build, lint, unit tests (≥80%), security scan · Terraform (IaC) |
| **XII — Observability** | OTel SDK → Azure Monitor · /health /health/ready /health/live |
| **XIII — Testing** | xUnit · Testcontainers · NetArchTest · Reqnroll (BDD) · Playwright (E2E) · k6 (perf) · Coverage ≥80% line / ≥75% branch |
| **XIV — Code Standards** | PascalCase classes/methods · _camelCase private fields · IInterface · 4 spaces · 120 chars · nullable refs enabled · .editorconfig |
| **XVI — Security** | No VNet/WAF · Azure-managed keys · TLS 1.2+ · Encryption PII · GDPR |
| **XIX — Governance** | Amendment: proposal → Tech Lead+Arch review → majority approval · Agents MUST read+validate constitution |

### CQRS Binding Contracts (HIGH — full detail required)

```csharp
public interface ICommand { }
public interface ICommandHandler<in TCommand> where TCommand : ICommand
    { Task HandleAsync(TCommand command, CancellationToken ct = default); }
public interface ICommandHandler<in TCommand, TResult> where TCommand : ICommand
    { Task<TResult> HandleAsync(TCommand command, CancellationToken ct = default); }
public interface IQuery<TResult> { }
public interface IQueryHandler<in TQuery, TResult> where TQuery : IQuery<TResult>
    { Task<TResult> HandleAsync(TQuery query, CancellationToken ct = default); }
public interface ICommandDispatcher
    { Task DispatchAsync<TCommand>(TCommand command, CancellationToken ct = default) where TCommand : ICommand; }
public interface IQueryDispatcher
    { Task<TResult> DispatchAsync<TQuery, TResult>(TQuery query, CancellationToken ct = default) where TQuery : IQuery<TResult>; }
public interface IDomainEvent { Guid EventId { get; } DateTime OccurredOn { get; } }
public interface IDomainEventHandler<in TEvent> where TEvent : IDomainEvent
    { Task HandleAsync(TEvent domainEvent, CancellationToken ct = default); }
```

---

## SCOPE: frontend

| Article | Decision |
|---------|----------|
| **II §2.2 — Framework** | Vue.js 3.x · TypeScript · Vite |
| **II §2.3 — Mobile** | None |
| **II §2.4 — Design Tool** | None (HTML mockups only; design gate inactive) |
| **III §3.2 — Architecture** | Monolith SPA · Azure Static Web Apps · Vue Router · Pinia |
| **VII — Auth** | Auth Code+PKCE · MSAL.js v3 (@azure/msal-browser + @azure/msal-vue) · Claims-based route guards |
| **X — Environments** | dev · prod · .env files (VITE_*) · No feature flags |
| **XI — CI/CD** | Azure DevOps · GitFlow · Vite build · ESLint+Prettier · Vitest ≥80% · Playwright E2E · Azure Static Web Apps deploy |
| **XII — Observability** | Azure Application Insights JS SDK · Exception tracking · RUM · Core Web Vitals |
| **XIII — Testing** | Vitest · Vue Testing Library · Playwright (E2E + visual regression) · Lighthouse CI · Coverage ≥80% |
| **XIV — Code Standards** | kebab-case files · PascalCase components · use+camelCase composables · 2 spaces · 100 chars · no semicolons · single quotes · ESLint+Prettier |
| **XVI — Security** | TLS 1.2+ (Static Web Apps) · No WAF · No PII client-side · GDPR (no cookies without consent) |

---

## SCOPE: cloud-platform

| Article | Decision |
|---------|----------|
| **VIII §8.1 — Containers** | Docker (standard containers) |
| **VIII §8.2 — Orchestration** | Azure Container Apps (serverless; no AKS) |
| **VIII-B — Infra Scope** | Workload only: Container Apps · Azure SQL · Redis · Service Bus · Static Web Apps · Key Vault · Entra ID · Azure Monitor |
| **VIII-C — Aspire** | Enabled (local dev only) · AppHost: src/AppHost/ · ServiceDefaults: src/ServiceDefaults/ · WithReference() discovery · Dashboard :15888 |
| **IX §9.1 — IaC** | Terraform · Remote state: Azure Storage · Modules: container-apps, sql, redis, service-bus, static-web-apps, key-vault · Workspaces: dev, prod |
| **X — Environments** | dev · prod · Terraform workspaces · Key Vault per env |
| **XI — CI/CD (IaC)** | Azure DevOps · GitFlow · tflint · terraform plan · Checkov/tfsec (0 Critical) · Infracost · Auto dev / manual prod |
| **XII — Infra Monitoring** | OTel → Azure Monitor · Activity Logs · Log Analytics · Alerts · Workbooks · Resource Health |
| **XIII §13.4 — IaC Testing** | tflint · Checkov/tfsec · Infracost · Terratest (Go) |
| **XVI — Security** | No VNet/private endpoints · Azure-managed keys · TLS 1.2+ · GDPR · Managed identity (no secrets in Container App env vars) |

---

## Cross-Scope Summary

| Concern | Decision |
|---------|----------|
| Cloud Provider | Microsoft Azure (mandatory, all scopes) |
| Environments | dev (auto) · prod (manual approval) |
| CI/CD Platform | Azure DevOps Pipelines |
| Branch Strategy | GitFlow |
| Deployment Strategy | Rolling Update |
| Observability | OTel SDK → Azure Monitor Exporter |
| Security Baseline | TLS 1.2+ · Azure-managed keys · GDPR · No VNet (greenfield) |
| Migration Context | Greenfield |

---

*Digest generated from merged-refinement.yaml — 37 articles included / 2 skipped. Read constitution.md for full governance text.*
