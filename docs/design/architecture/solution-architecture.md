# Solution Architecture — Vacation Management & Approval System

## Document metadata

| Property           | Value                                                      |
| ------------------ | ---------------------------------------------------------- |
| Project            | VAC-MGT-2026                                               |
| Version            | 1.0                                                        |
| Date               | 2026-08-07                                                 |
| Author             | Solution Architect                                         |
| Status             | Approved                                                   |
| ADR references     | ADR-001 · ADR-002 · ADR-003 · ADR-004 · ADR-005 · ADR-006 |
| Constitution scope | backend · frontend · cloud-platform                        |

---

## 1. System Overview

### 1.1 Core capabilities

| Capability | Description |
|-----------|-------------|
| **Vacation lifecycle** | Employee submission, two-level approval (PM → DM), cancellation |
| **Capacity visualisation** | Team calendar and heat-map with configurable thresholds |
| **Integrations** | Nightly AD sync (Microsoft Graph API) and ServiceNow export/import |
| **Notifications** | Event-driven email (primary) and Teams (capacity alerts) |
| **Reporting & audit** | 7-year immutable audit log, predefined reports, admin configuration |

### 1.2 Technology stack

| Layer | Technology |
|-------|-----------|
| Frontend SPA | Vue 3 · TypeScript · Vite · Pinia · MSAL.js v3 |
| Backend API | C# · .NET 10 · Minimal APIs · Modular Monolith · Simple CQRS |
| Persistence | Azure SQL (EF Core writes + Dapper reads) |
| Caching | Azure Cache for Redis (L2) + `IMemoryCache` (L1) |
| Messaging | Azure Service Bus (Standard tier) |
| Identity | Microsoft Entra ID · Managed Identity |
| Hosting | Azure Container Apps (API) · Azure Static Web Apps (SPA) |
| IaC | Terraform · workspaces: dev / prod |
| CI/CD | Azure DevOps Pipelines · GitFlow |
| Observability | OpenTelemetry → Azure Monitor · Application Insights |
| Local dev | .NET Aspire AppHost · Dashboard :15888 |

---

## 2. C4 Level 1 — System Context

```mermaid
C4Context
    title System Context — Vacation Management System

    Person(employee, "Employee", "~500 users. Submits requests, tracks status, views team calendar.")
    Person(pm, "Project Manager", "~50 users. Approves at project level, manages delegations.")
    Person(dm, "Department Manager", "~10 users. Final approval, capacity dashboard, reports.")
    Person(admin, "IT Administrator", "~5 users. User management, configuration, integration monitoring.")

    System(vms, "Vacation Management System", "Centralised vacation request, approval, capacity tracking and reporting. Hosted on Microsoft Azure.")

    System_Ext(entra, "Microsoft Entra ID", "Corporate identity provider. Auth Code + PKCE for SPA. Client Credentials for S2S.")
    System_Ext(ad, "Azure Active Directory", "Employee data, org hierarchy, role assignments. Read-only via Microsoft Graph API.")
    System_Ext(servicenow, "ServiceNow", "Receives approved vacations (4AM export). Provides vacation balances (6AM import).")
    System_Ext(smtp, "Corporate SMTP / SendGrid", "Email relay for workflow notifications.")
    System_Ext(teams, "Microsoft Teams", "Secondary channel — critical capacity alerts via Graph API 1:1 chat.")

    Rel(employee, vms, "Submits requests, views status and team calendar", "HTTPS")
    Rel(pm, vms, "Reviews and approves/rejects requests, configures delegations", "HTTPS")
    Rel(dm, vms, "Final approvals, capacity dashboard, reports", "HTTPS")
    Rel(admin, vms, "User management, system configuration, integration monitoring", "HTTPS")

    Rel(vms, entra, "Authenticates users — Auth Code + PKCE / Client Credentials", "OIDC/JWT")
    Rel(vms, ad, "Reads employee data and org hierarchy (nightly at 2AM)", "HTTPS — Graph API")
    Rel(vms, servicenow, "Exports approved vacations (4AM), imports balances (6AM)", "HTTPS — Table API")
    Rel(vms, smtp, "Sends email notifications for all workflow events", "SMTP/TLS")
    Rel(vms, teams, "Sends Teams 1:1 messages for critical capacity alerts", "HTTPS — Graph API")
```

---

## 3. C4 Level 2 — Container Diagram

```mermaid
C4Container
    title Container Diagram — Vacation Management System

    Person(user, "User (Employee / PM / DM / Admin)")

    System_Boundary(vms, "Vacation Management System") {
        Container(spa, "Vue 3 SPA", "Vue 3 · TypeScript · Vite · Pinia · MSAL.js", "All user-facing screens. Auth via MSAL Auth Code + PKCE. Hosted on Azure Static Web Apps (global CDN).")
        Container(api, "Backend API", ".NET 10 · Minimal APIs · Modular Monolith · Simple CQRS", "All business logic. REST API consumed by the SPA. Background services for nightly jobs. Azure Container Apps.")
        ContainerDb(sqldb, "Azure SQL Database", "SQL Server 12 · EF Core + Dapper", "Primary store. TDE enabled. 7-year LTR. EF Core migrations as schema source of truth.")
        Container(redis, "Azure Cache for Redis", "Redis 7 · Standard/Basic", "L2 distributed cache (30-min TTL). Capacity snapshots, approval queues. Distributed locks for background jobs.")
        Container(servicebus, "Azure Service Bus", "Standard SKU · 4 topics · 8 subscriptions", "Async event backbone. Decouples notifications, capacity updates, and integrations.")
        Container(keyvault, "Azure Key Vault", "Standard tier · RBAC-enabled", "Centralised secrets. API uses Managed Identity. No credentials in code or environment variables.")
    }

    System_Ext(entra, "Microsoft Entra ID")
    System_Ext(monitor, "Azure Monitor + App Insights")
    System_Ext(ad, "Active Directory (Graph API)")
    System_Ext(sn, "ServiceNow")

    Rel(user, spa, "Uses", "HTTPS")
    Rel(spa, api, "REST API — vacation requests, approvals, reports", "HTTPS/JSON · Bearer JWT")
    Rel(api, sqldb, "EF Core writes · Dapper reads", "TCP 1433 · AAD Auth")
    Rel(api, redis, "Cache-Aside reads/writes · Distributed locks", "TLS 6380")
    Rel(api, servicebus, "Publishes domain events · Consumes events in BackgroundServices", "AMQP · Managed Identity")
    Rel(api, keyvault, "Reads secrets at startup and runtime", "HTTPS · Managed Identity")
    Rel(api, entra, "Validates JWT tokens · Client Credentials for S2S", "OIDC/JWT")
    Rel(api, ad, "Nightly employee sync", "HTTPS · Managed Identity")
    Rel(api, sn, "Nightly export/import", "HTTPS · API Key from Key Vault")
    Rel(api, monitor, "OTel SDK — traces, metrics, logs", "HTTPS/OTLP")
    Rel(spa, monitor, "Application Insights JS SDK — RUM, exceptions, Core Web Vitals", "HTTPS")
```

---

## 4. C4 Level 3 — Component Diagram (Backend)

The backend is a **Modular Monolith** — a single deployable process with explicit module
boundaries enforced by NetArchTest. Cross-module communication happens only through CQRS
dispatchers, never via direct class references.

```mermaid
C4Component
    title Component Diagram — Backend Modular Monolith

    Container_Boundary(api, "VacationManagement.Api (.NET 10 Container App)") {
        Component(minapi, "Minimal API Layer", "ASP.NET Core Minimal APIs", "Route registration, auth middleware, CORS, health endpoints.")
        Component(vm, "VacationManagement Module", "C# Domain + CQRS", "VacationRequest aggregate. Commands: Submit, Cancel. Queries: GetMyRequests, GetDetail.")
        Component(aw, "ApprovalWorkflow Module", "C# Domain + CQRS", "ApprovalWorkflow aggregate, Delegation. Commands: Approve/Reject L1+L2, Appeal, Delegate. Escalation BackgroundService.")
        Component(cm, "CapacityManagement Module", "C# Domain + CQRS", "CapacitySnapshot aggregate. Redis cache-aside. Service Bus consumers for invalidation.")
        Component(is_, "IdentitySync Module", "C# Domain + BackgroundService", "SyncJob aggregate. GraphApiClient. Nightly AD sync at 2AM. Redis distributed lock.")
        Component(sn_, "ServiceNowIntegration Module", "C# Domain + BackgroundService", "ExportJob/ImportJob aggregates. Polly retry + circuit breaker. Nightly export 4AM / import 6AM.")
        Component(notif, "Notifications Module", "C# Domain + Service Bus Consumers", "NotificationTemplate (Handlebars.NET). SMTP email. Teams Graph API. CapacityAlert dedup. HMAC action links.")
        Component(ra, "ReportingAdmin Module", "C# Domain + Dapper", "AuditInterceptor (EF Core). AuditEntry append-only. SystemConfiguration. Dapper reports. ClosedXML/QuestPDF/CsvHelper export.")
        Component(cqrs, "CQRS Infrastructure", "ICommandDispatcher · IQueryDispatcher", "Manual dispatcher — no MediatR. Resolves handlers via DI.")
        Component(ef, "EF Core DbContext", "VacationManagementDbContext", "Shared DbContext. AuditInterceptor registered globally. Migrations as schema source of truth.")
        Component(svcdef, "ServiceDefaults", "Aspire ServiceDefaults", "OTel SDK. Health endpoints: /health/live, /health/ready. Resilience handlers.")
    }

    Rel(minapi, cqrs, "Dispatches commands and queries")
    Rel(cqrs, vm, "Routes to VacationManagement handlers")
    Rel(cqrs, aw, "Routes to ApprovalWorkflow handlers")
    Rel(cqrs, cm, "Routes to CapacityManagement handlers")
    Rel(cqrs, ra, "Routes to ReportingAdmin handlers")
    Rel(vm, ef, "EF Core writes · Dapper reads")
    Rel(aw, ef, "EF Core writes · Dapper reads")
    Rel(ra, ef, "AuditInterceptor captures all writes · Dapper reads")
```

### 4.1 CQRS binding contracts (immutable by constitution)

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
```

### 4.2 Module directory structure

```
src/backend/
├── src/
│   ├── Api/                          ← Minimal API layer (routes, middleware, auth)
│   ├── Modules/
│   │   ├── VacationManagement/       ← F-001: Domain / Application / Infrastructure / Api
│   │   ├── ApprovalWorkflow/         ← F-002
│   │   ├── CapacityManagement/       ← F-003
│   │   ├── IdentitySync/             ← F-004
│   │   ├── ServiceNowIntegration/    ← F-005
│   │   ├── Notifications/            ← F-006
│   │   └── ReportingAdmin/           ← F-007
│   ├── Infrastructure/
│   │   ├── Cqrs/                     ← CommandDispatcher, QueryDispatcher
│   │   └── Persistence/              ← DbContext, AuditInterceptor, Migrations
│   └── Domain/Common/                ← BaseEntity, IDomainEvent, AggregateRoot
└── tests/
    ├── VacationManagement.ReqnrollTests/
    └── ...
```

### 4.3 Cross-module boundary rules (NetArchTest)

| Rule | Tool |
|------|------|
| Module A must not directly reference classes from Module B | `DoNotHaveDependencyOn` |
| Application layer must not reference Infrastructure layer | Layer dependency rule |
| Domain layer has zero external package dependencies | `OnlyHaveDependenciesOn(["System.*"])` |

---

## 5. Deployment Architecture

```mermaid
flowchart TB
    subgraph RG["Resource Group: rg-vacmgt-{env}"]
        subgraph COMPUTE["Compute"]
            SWA["Azure Static Web Apps\nstapp-vacmgt-{env}\nVue 3 SPA — global CDN"]
            ACA_ENV["Container Apps Environment\ncae-vacmgt-{env}"]
            ACA["Container App\nca-vacmgt-api-{env}\n.NET 10 API — rolling update\nmin:1–2 / max:3–10 replicas"]
        end
        subgraph DATA["Data & Messaging"]
            SQL["Azure SQL Database\nsqldb-vacmgt-{env}\nTDE · LTR 7 years"]
            REDIS["Azure Cache for Redis\nredis-vacmgt-{env}\nTLS 6380 · allkeys-lru"]
            SB["Azure Service Bus\nsb-vacmgt-{env}\nStandard · 4 topics · 8 subs"]
        end
        subgraph SECURITY["Security"]
            KV["Azure Key Vault\nkv-vacmgt-{env}\nRBAC-enabled · purge-protected"]
            MI["Managed Identity\nid-vacmgt-api-{env}\nAPI auth to KV, SQL, SB, Graph"]
        end
        subgraph OBS["Observability"]
            LAW["Log Analytics Workspace\nlaw-vacmgt-{env}\n90-day hot retention"]
            APPI["Application Insights\nappi-vacmgt-{env}\nworkspace-based"]
            AG["Monitor Action Group\nEmail alerts: ops@company.com"]
        end
    end
    ACR["Azure Container Registry\nContainer image store"]
    ENTRA["Microsoft Entra ID\nJWT validation"]

    DEV["Dev / CI Pipeline"] -->|docker push| ACR
    ACR -->|image pull| ACA
    ACA -->|SQL AAD auth| SQL
    ACA -->|TLS 6380| REDIS
    ACA -->|AMQP · Managed Identity| SB
    ACA -->|Managed Identity| KV
    ACA -->|OTLP| APPI
    APPI --> LAW --> AG
```

### 5.1 Environment matrix

| Attribute | dev | prod |
|-----------|-----|------|
| SQL SKU | S1 (10 DTUs) | GP_Gen5_2 (2 vCores) |
| Redis SKU | Basic C0 | Standard C1 |
| API min replicas | 1 | 2 |
| API max replicas | 3 | 10 |
| Terraform workspace | `dev` | `prod` |
| Deploy trigger | Auto on `develop` push | Manual approval on `main` push |

---

## 6. Integration Architecture

```mermaid
sequenceDiagram
    participant CRON as BackgroundService Scheduler
    participant SYNC as AdSyncBackgroundService
    participant GRAPH as Microsoft Graph API
    participant DB as Azure SQL
    participant REDIS as Redis (dist. lock)
    participant SN as ServiceNow Table API

    Note over CRON,REDIS: 2:00 AM — AD Sync (F-004)
    CRON->>SYNC: TriggerScheduledAdSyncCommand
    SYNC->>REDIS: Acquire lock "adsync-running"
    SYNC->>GRAPH: GET /v1.0/users?$select=... (paged 100/page)
    GRAPH-->>SYNC: Users (N pages)
    loop Each user (parallel, max 10 concurrent)
        SYNC->>DB: Upsert Employee by ExternalAdId
    end
    SYNC->>DB: Write SyncJob summary
    SYNC->>REDIS: Release lock

    Note over CRON,SN: 4:00 AM — ServiceNow Export (F-005)
    CRON->>SYNC: TriggerNightlyExportCommand
    SYNC->>DB: Query Approved + IsExported=false (delta)
    loop Each approved request
        SYNC->>SN: POST /api/now/table/u_vacations
        SN-->>SYNC: sys_id
        SYNC->>DB: Set IsExported=true, ServiceNowRecordId
    end

    Note over CRON,SN: 6:00 AM — Balance Import (F-005)
    CRON->>SYNC: TriggerNightlyBalanceImportCommand
    SYNC->>SN: GET /api/now/table/u_vacation_balances
    SN-->>SYNC: Balance records
    SYNC->>DB: Update Employee.VacationBalance fields
```

### 6.1 Integration resilience

| Integration | Auth | Retry | Circuit breaker |
|------------|------|-------|----------------|
| Microsoft Graph API | Managed Identity (Client Credentials) | 3× exp backoff (1s→5s→30s) | N/A (paged; retry per page) |
| ServiceNow Table API | API Key from Key Vault | 3× exp backoff (1s→5s→30s) | 5 failures → open 60s → alert admin |
| SMTP/SendGrid | Credentials from Key Vault | 3× retry | N/A |
| Microsoft Teams Graph | Managed Identity | 3× retry | Failure does NOT block email (BR-095) |

---

## 7. Event-Driven Architecture

```mermaid
flowchart LR
    subgraph PRODUCERS["Producers"]
        VM["VacationManagement"]
        AW["ApprovalWorkflow"]
        CM["CapacityManagement"]
        IS["IdentitySync"]
        SN["ServiceNowIntegration"]
    end
    subgraph SB["Azure Service Bus"]
        T1["vacation-requests"]
        T2["approval-events"]
        T3["capacity-events"]
        T4["integration-events"]
    end
    subgraph CONSUMERS["Consumers (BackgroundService workers)"]
        N1["Notifications\n(notification-handler)"]
        CM2["CapacityManagement\n(capacity-management)"]
        SN2["ServiceNowIntegration\n(servicenow-export)"]
    end

    VM -- "VacationRequestSubmitted\nVacationRequestCancelled" --> T1
    AW -- "ApprovedAtProjectLevel\nApprovedFinal\nRejected*\nEscalationTriggered" --> T2
    CM -- "CapacityWarning/CriticalThresholdCrossed" --> T3
    IS -- "SyncJobCompleted\nEmployeeCreated/DeactivatedFromAD" --> T4
    SN -- "ExportJobCompleted\nExportRecordPermanentlyFailed" --> T4

    T1 --> N1
    T1 --> CM2
    T1 --> SN2
    T2 --> N1
    T2 --> CM2
    T3 --> N1
    T4 --> N1
```

**Delivery guarantees:** At-least-once; consumers are idempotent (event IDs deduplicate). DLQ on all subscriptions (max 5 deliveries). Message TTL 14 days.

---

## 8. Data Architecture

### 8.1 EF Core write model vs. Dapper read model

| Operation | Tool | Reason |
|-----------|------|--------|
| Submit / Cancel / Approve commands | EF Core | Change tracking, optimistic concurrency, domain event dispatch |
| `GetMyVacationRequestsQuery` | Dapper | Paginated projection — no entity hydration needed |
| `GetCapacityHeatMapQuery` | Dapper | Pure read from `CAPACITY_SNAPSHOTS` pre-computed table |
| `GetVacationHistoryReportQuery` | Dapper | Multi-table join with large date range |
| `GetAuditTrailQuery` | Dapper | 1M+ rows — covering index required |

### 8.2 Data retention policies

| Data | Retention | Mechanism |
|------|-----------|-----------|
| Audit entries | 7 years (compliance) | Azure SQL LTR + `HasNoDelete()` EF config |
| Sync / Export job history | 90 days | Application-level purge |
| Capacity snapshots | 2 years | Application-level purge (report coverage) |
| Database backups | 35 days short-term | Azure SQL auto-backup |

---

## 9. Caching Architecture

```mermaid
sequenceDiagram
    participant SPA
    participant API
    participant L1 as IMemoryCache (5 min)
    participant L2 as Azure Redis (30 min)
    participant SQL

    SPA->>API: GET /api/capacity/heat-map
    API->>L1: TryGetValue
    alt L1 hit
        L1-->>API: Snapshots[]
    else
        API->>L2: GET key
        alt L2 hit
            L2-->>API: Snapshots[] (JSON)
            API->>L1: Set (5 min)
        else
            API->>SQL: SELECT CAPACITY_SNAPSHOTS
            SQL-->>API: Snapshots[]
            API->>L2: SET key EX 1800
            API->>L1: Set (5 min)
        end
    end
    API-->>SPA: CapacityHeatMapDto

    Note over API,L2: Invalidated on every approval/cancellation/submission event
```

---

## 10. Authentication & Authorization

### 10.1 Auth flows

```mermaid
sequenceDiagram
    actor User
    participant SPA as Vue 3 SPA (MSAL.js)
    participant ENTRA as Entra ID
    participant API as .NET 10 API

    Note over User,SPA: Auth Code + PKCE (SPA users)
    User->>SPA: Navigate to app
    SPA->>ENTRA: Authorization request + code_challenge
    ENTRA-->>User: Login form (SSO)
    User->>ENTRA: Corporate credentials
    ENTRA-->>SPA: Authorization code
    SPA->>ENTRA: Token request + code_verifier
    ENTRA-->>SPA: Access token (JWT)
    SPA->>API: Request + Authorization: Bearer {JWT}
    API->>ENTRA: Validate JWT (signature, audience, expiry)
    API->>API: Extract claims → policy evaluation

    Note over API,ENTRA: Client Credentials (BackgroundServices)
    API->>ENTRA: Token request (Managed Identity)
    ENTRA-->>API: Access token
    API->>ExternalAPI: Request with token
```

### 10.2 Authorization policies

| Policy | Required claim | Accessible to |
|--------|---------------|---------------|
| `RequireEmployee` | Any authenticated role | All authenticated users |
| `RequireProjectManager` | `role = ProjectManager` | PMs + DMs + Admins |
| `RequireDepartmentManager` | `role = DepartmentManager` | DMs + Admins |
| `RequireAdministrator` | `role = Administrator` | Admins only |
| `RequireAdminOrAuditor` | `Administrator OR Auditor` | Admins + Auditors |

---

## 11. Security Architecture

### 11.1 Secrets management — zero-trust model

```
NEVER: appsettings.json → connection string
NEVER: Container App environment variable → plain text secret
ALWAYS: Azure Key Vault → Container App Secret reference → Managed Identity
```

| Secret | Stored in | Accessed via |
|--------|-----------|--------------|
| Azure SQL connection string | Key Vault | Container App KV reference + Managed Identity |
| Redis connection string | Key Vault | Container App KV reference + Managed Identity |
| ServiceNow API key | Key Vault | `SecretClient` + `DefaultAzureCredential` |
| SMTP credentials | Key Vault | `SecretClient` + `DefaultAzureCredential` |
| HMAC signing key | Key Vault | `SecretClient` + `DefaultAzureCredential` |

### 11.2 OWASP Top 10 controls

| OWASP | Control |
|-------|---------|
| A01 Broken Access Control | Policy-based authz; role-scoped Dapper queries (DM sees own dept) |
| A02 Cryptographic Failures | TLS 1.2+ (enforced at ACA ingress); Azure SQL TDE; Key Vault for all secrets |
| A03 Injection | EF Core parameterised; Dapper parameter objects — no string concatenation |
| A05 Security Misconfiguration | Checkov/tfsec 0 Critical gate in IaC pipeline |
| A06 Vulnerable Components | SCA (Dependency-Check) in every PR — fail on Critical |
| A07 Auth Failures | MSAL JWT Bearer validation; `ValidateLifetime = true`; PKCE on SPA |
| A09 Logging Failures | OTel 100% API trace coverage; `AuditInterceptor` all state changes |
| A10 SSRF | ServiceNow URL pinned in Key Vault config; no user-controlled URLs |

### 11.3 GDPR compliance baseline

| Requirement | Implementation |
|-------------|---------------|
| Data minimisation | Only minimum necessary AD fields synced; no PII in email bodies beyond names |
| Encryption at rest | Azure SQL TDE (default); Key Vault-managed keys |
| Right to erasure | `Employee.IsActive = false` (soft-delete); `[AuditRedact]` attribute on PII fields |
| Audit trail | `AuditEntry` append-only — every data change with actor, timestamp, before/after |
| 7-year retention | Azure SQL LTR policy (P7Y); `AuditEntry` `HasNoDelete()` EF config |

---

## 12. Observability Architecture

```mermaid
flowchart LR
    subgraph APP["Application"]
        API[".NET 10 API (OTel SDK)"]
        SPA["Vue 3 SPA (App Insights JS)"]
        BG["Background Services (OTel SDK)"]
    end
    subgraph OTEL["OTel Instrumentation"]
        ASPNET["ASP.NET Core (spans/request)"]
        EF["EF Core (DB spans — no SQL text)"]
        HTTP["HttpClient (Graph/SN calls)"]
        METRICS["Custom metrics\n(sync duration, export totals)"]
    end
    subgraph AZURE["Azure Monitor"]
        APPI["Application Insights\n(workspace-based)"]
        LAW["Log Analytics Workspace\n(90-day hot)"]
        ALERTS["Alert Rules"]
        WORKBOOKS["Azure Workbooks (SLO dashboard)"]
    end

    API --> ASPNET --> APPI
    API --> EF --> APPI
    API --> HTTP --> APPI
    BG --> METRICS --> APPI
    SPA --> APPI
    APPI --> LAW --> ALERTS
    LAW --> WORKBOOKS
```

### 12.1 SLOs and alert thresholds

| SLO | Target | Alert |
|-----|--------|-------|
| API availability | ≥ 99.5% | < 99% over 15 min |
| API P95 latency | < 300 ms | > 1 s sustained 5 min |
| AD sync success | ≥ 99% | Error rate > 5% |
| ServiceNow export success | ≥ 99% | Permanent failure (3 retries exhausted) |

### 12.2 Health endpoints

| Endpoint | Purpose | Probe |
|----------|---------|-------|
| `/health/live` | Process alive | Container Apps liveness probe every 30s |
| `/health/ready` | SQL + Redis reachable | Container Apps readiness probe every 15s |
| `/health` | Combined | Azure Monitor Resource Health |

---

## 13. Frontend Architecture

```mermaid
flowchart TB
    subgraph SPA["Vue 3 SPA (src/frontend/)"]
        ROUTER["Vue Router (client-side routing)"]
        AUTH["auth.ts — MSAL.js route guards (role-based)"]
        subgraph MODULES["Feature Modules"]
            VM_MOD["vacation-requests/ (F-001)"]
            AW_MOD["approval/ (F-002)"]
            CAL_MOD["calendar/ (F-003)"]
            RPT_MOD["reporting-admin/ (F-007)"]
        end
        subgraph STORES["Pinia Stores"]
            VS["vacationRequestStore"]
            AS["approvalQueueStore"]
            CS["calendarStore · dashboardStore"]
            AD_S["adminStore"]
        end
        subgraph API_LAYER["API Layer (typed Axios)"]
            VA["vacationRequestApi.ts"]
            AA["approvalApi.ts"]
            CA["capacityApi.ts"]
            RA["reportsApi.ts · auditApi.ts · adminApi.ts"]
        end
    end
    API_LAYER -->|Bearer JWT| BACKEND["Backend API"]
```

**Naming conventions (constitution XIV):** `kebab-case` files · `PascalCase` components · `use + camelCase` composables · 2-space indent · 100-char max line · no semicolons · single quotes.

---

## 14. CI/CD Architecture

```mermaid
flowchart LR
    subgraph GIT["GitFlow"]
        FEAT["feature/* · bolt/*"] -->|PR + review| DEV["develop"]
        DEV -->|PR + approval| MAIN["main"]
    end
    subgraph BE["backend-ci.yml"]
        direction TB
        BE1["Build\n(warnings as errors)"] --> BE2["dotnet format"] --> BE3["Unit Tests\n(coverage ≥ 80%)"] --> BE4["SAST + SCA\n(0 Critical)"] --> BE5["Docker build/push"] --> BE6["Deploy dev (auto)"] --> BE7["Deploy prod\n(manual approval)"]
    end
    subgraph FE["frontend-ci.yml"]
        direction TB
        FE1["ESLint + Prettier"] --> FE2["Vitest\n(coverage ≥ 80%)"] --> FE3["Vite build"] --> FE4["Playwright @smoke"] --> FE5["Deploy SWA dev (auto)"] --> FE6["Deploy SWA prod\n(manual approval)"]
    end
    subgraph IaC["infra-ci.yml"]
        direction TB
        TF1["terraform fmt/validate\n+ tflint"] --> TF2["Checkov\n(0 Critical/High)"] --> TF3["Infracost\n(PR cost comment)"] --> TF4["terraform plan"] --> TF5["apply dev (auto)"] --> TF6["apply prod\n(manual approval)"]
    end
    DEV --> BE
    DEV --> FE
    DEV --> IaC
```

---

## 15. Non-Functional Requirements Mapping

| NFR | Target | Architecture mechanism |
|-----|--------|----------------------|
| API P95 latency | < 300 ms | Redis L2 cache; Dapper reads; `IMemoryCache` L1 |
| Calendar render | < 1 s | Pre-computed `CAPACITY_SNAPSHOTS`; covering indexes |
| Report generation | < 5 s | Dapper + covering indexes; max 2-year range |
| Availability | ≥ 99.5% | ACA min 2 replicas (prod); Azure SQL SLA 99.99% |
| Scalability | 560 concurrent users | ACA HTTP scale rule (50 req/replica) |
| AD sync | < 30 min / 500 users | Parallel upsert (max 10); cursor-based Graph paging |
| ServiceNow export | < 15 min / 50 records | Sequential async; circuit breaker skips on SN downtime |
| Security | OWASP Top 10 | SAST gate; SCA gate; Checkov; Managed Identity; Key Vault |
| GDPR | Compliant | `[AuditRedact]`; soft-delete; right-to-erasure API; consent flow |
| Audit retention | 7 years | Azure SQL LTR (P7Y); `AuditEntry` append-only |
| Code coverage | ≥ 80% / 75% | Coverlet gate (BE); Vitest gate (FE) |
| Accessibility | WCAG 2.1 AA | axe-core in Playwright E2E; Lighthouse CI |

---

## 16. Architecture Decision Index

| ADR | Decision | Status |
|-----|---------|--------|
| ADR-001 | C# / .NET 10 / Minimal APIs | Accepted |
| ADR-002 | Modular Monolith + Simple CQRS (no MediatR) | Accepted |
| ADR-003 | Azure SQL + EF Core (writes) + Dapper (reads) | Accepted |
| ADR-004 | Vue 3 + TypeScript + Vite + Pinia + Azure Static Web Apps | Accepted |
| ADR-005 | Azure Container Apps + Terraform | Accepted |
| ADR-006 | Azure DevOps Pipelines + OTel→Azure Monitor + GDPR baseline | Accepted |

### 16.1 Hard constraints from constitution (require governance to change)

1. **No MediatR** — manual `ICommandDispatcher` / `IQueryDispatcher`
2. **No VNet / private endpoints** — deferred to post-MVP
3. **No WAF** — deferred to post-MVP
4. **No AKS** — Azure Container Apps is mandatory
5. **No Event Sourcing** — not justified for this domain
6. **TLS 1.2+ everywhere** — enforced at ACA ingress and Redis
7. **Managed Identity only** — no stored credentials anywhere
8. **Key Vault for all secrets** — no secrets in code, pipelines, or env vars
9. **Nullable reference types enabled** in all `.csproj`
10. **GitFlow branching** — no direct commits to `develop` or `main`
