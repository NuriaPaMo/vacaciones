# ADR-006: Azure DevOps Pipelines with GitFlow, OpenTelemetry→Azure Monitor, and GDPR-Compliant Security Baseline

## Status

Accepted

## Date

2026-08-05

## Context

All project scopes (backend, frontend, infrastructure) share cross-cutting concerns around CI/CD, observability, and security. These decisions affect every module, every deployment, and every team member. Establishing a consistent, opinionated baseline avoids configuration drift and ensures all components operate under the same quality, visibility, and compliance standards.

Key requirements:
- **CI/CD**: Automated build, test, and deploy pipelines for backend, frontend, and Terraform
- **Branching strategy**: A structured Git workflow that supports parallel feature development and hotfixes
- **Deployment strategy**: Safe, zero-downtime production deployments
- **Observability**: Unified telemetry (traces, metrics, logs) across backend and frontend
- **Security**: Baseline hardening appropriate for a greenfield Azure-hosted application with GDPR compliance
- **Testing coverage**: Minimum 80% code coverage enforced in CI

The organisation already uses Azure DevOps for source control and project management, making Azure DevOps Pipelines the natural CI/CD choice.

Key forces:
- OTel (OpenTelemetry) is vendor-neutral — avoids lock-in to a specific APM vendor
- Azure Monitor is the Azure-native observability backend, cost-effective for Azure-hosted workloads
- GDPR compliance is a legal requirement — data minimisation, consent, and right-to-erasure must be designed in from day one
- VNet and WAF add significant operational cost and complexity — deferred to post-MVP phase when threat model justifies the investment
- Managed identity eliminates credential management for container-to-Azure-service communication

## Decision Drivers

- MUST use Azure DevOps Pipelines for all CI/CD workflows (already in use)
- MUST implement GitFlow branching strategy
- MUST use Rolling Update deployment strategy for zero-downtime deployments
- MUST use OpenTelemetry SDK for backend observability, exporting to Azure Monitor
- MUST use Azure Application Insights JS SDK for frontend observability
- MUST enforce TLS 1.2+ for all traffic
- MUST implement GDPR compliance baseline (data minimisation, consent, erasure)
- MUST use managed identity for container authentication to Azure services
- MUST enforce ≥80% code coverage in CI
- SHOULD defer VNet and WAF to post-MVP (not required for greenfield)
- SHOULD NOT implement mutation testing initially (deferred)

## Considered Options

### CI/CD: Azure DevOps Pipelines vs. GitHub Actions

#### Option A: Azure DevOps Pipelines ✅ (Chosen)
**Pros:** Already in organisational use; tight integration with Azure boards and repos; native Terraform task (`TerraformTaskV4`); service connections for Azure authentication; variable groups for secrets
**Cons:** YAML pipeline syntax is more verbose than GitHub Actions; less community-contributed pipeline templates

#### Option B: GitHub Actions
**Pros:** Largest marketplace of reusable actions; closer to open-source community tooling; `azure/login` and `hashicorp/setup-terraform` actions are mature
**Cons:** Organisation uses Azure DevOps — migration introduces friction; GitHub Actions secrets management separate from Azure DevOps variable groups; inconsistent toolchain for a team already on Azure DevOps

**Decision: Azure DevOps Pipelines** — organisation is already on Azure DevOps; switching introduces friction without material benefit.

---

### Branching Strategy: GitFlow vs. Trunk-Based Development

#### Option A: GitFlow ✅ (Chosen)
Structure: `main` (production), `develop` (integration), `feature/*`, `release/*`, `hotfix/*`
**Pros:** Clear separation between production-stable code and in-progress features; hotfix branches enable emergency patches without including in-progress features; release branches allow QA stabilisation before production
**Cons:** More branches to manage; merge conflicts between long-lived branches if not kept short; requires discipline

#### Option B: Trunk-Based Development
Structure: `main` (trunk), short-lived feature branches, feature flags for in-progress work
**Pros:** Simpler; encourages continuous integration; less merge conflict risk
**Cons:** Requires mature feature flag infrastructure to hide incomplete features; less suitable for teams with formal QA/release cycles; Azure DevOps board integration aligns better with GitFlow's branch naming conventions

**Decision: GitFlow** — structured release process with QA stabilisation is preferred for this project's delivery model.

---

### Deployment Strategy: Rolling Update vs. Blue/Green vs. Canary

#### Option A: Rolling Update ✅ (Chosen)
**Pros:** Built-in to Azure Container Apps via Revision management; zero-downtime by gradually replacing old revision with new; simple to configure; no doubled infrastructure cost
**Cons:** Mixed versions briefly in flight during rollout — mitigated by backward-compatible API versioning

#### Option B: Blue/Green
**Pros:** Instant cutover with no mixed-version period; easy rollback by flipping traffic
**Cons:** Requires doubled infrastructure during deployment; more complex traffic routing in ACA

#### Option C: Canary
**Pros:** Gradual traffic shift with real-user validation
**Cons:** Most complex to configure; requires traffic split infrastructure; unnecessary for this project's risk profile

**Decision: Rolling Update** — simplest zero-downtime strategy natively supported by ACA Revisions.

---

### Observability: OpenTelemetry → Azure Monitor vs. Alternatives

#### Option A: OpenTelemetry SDK → Azure Monitor Exporter ✅ (Chosen)
**Backend**: `OpenTelemetry.Sdk` + `Azure.Monitor.OpenTelemetry.Exporter` NuGet packages. Auto-instruments ASP.NET Core, EF Core, HTTP clients.
**Frontend**: Azure Application Insights JavaScript SDK (`@microsoft/applicationinsights-web`) for browser traces, page views, and exceptions.
**Pros:** OTel is vendor-neutral — exporters can be swapped (e.g., add Jaeger for local dev, Datadog for enterprise); Azure Monitor Exporter is Microsoft-maintained with first-class ACA integration; unified trace/metric/log pipeline; Application Insights JS SDK is officially supported for Vue/SPA
**Cons:** Azure Monitor cost scales with ingestion volume — mitigated by sampling and log level filtering; OTel SDK adds startup initialisation code (one-time setup)

#### Option B: Application Insights SDK (legacy)
**Pros:** Simpler setup, Microsoft-maintained
**Cons:** Vendor-locked to Application Insights; deprecated in favour of OTel-based approach; less flexible for future APM migrations

#### Option C: Prometheus + Grafana (self-hosted)
**Pros:** Open source, highly customisable dashboards
**Cons:** Requires hosting and maintaining Grafana/Prometheus infrastructure on Azure; adds operational complexity; not Azure-native; cost advantage disappears when factoring in VM/container costs

**Decision: OpenTelemetry SDK → Azure Monitor** — vendor-neutral instrumentation with Azure-native backend; aligns with Microsoft's recommended approach for .NET on Azure.

---

### Security Baseline

#### Scope
This ADR defines the **greenfield baseline**. Advanced controls (VNet, WAF, DDoS protection) are explicitly deferred to post-MVP when threat model assessment justifies the investment.

#### Decisions

| Control | Decision | Notes |
|---------|----------|-------|
| Transport security | TLS 1.2+ enforced | ACA managed TLS certificates; no HTTP allowed |
| Encryption at rest | Azure-managed keys | Azure SQL TDE, Storage Service Encryption, Key Vault |
| Authentication (containers) | Managed Identity | ACA system-assigned managed identity for Key Vault, SQL, ACR |
| Secrets management | Azure Key Vault | No secrets in environment variables or config files |
| Network isolation | Deferred (no VNet/WAF) | Greenfield; add VNet integration and WAF post-MVP |
| GDPR compliance | Design-in from day one | Data minimisation, consent capture, right-to-erasure API endpoints |
| Code coverage | ≥80% enforced in CI | Coverage gate blocks PR merge below threshold |
| Mutation testing | Deferred | Not required initially; revisit post-MVP |
| Dependency scanning | Azure DevOps security scan | `dotnet list package --vulnerable` + `npm audit` in pipeline |

#### Option A: No VNet / WAF for Greenfield ✅ (Chosen)
**Pros:** Reduces infrastructure complexity and cost; ACA provides built-in ingress TLS; managed identity provides secure service-to-service auth without network isolation
**Cons:** No network perimeter around workloads; mitigated by TLS, managed identity, Key Vault, and least-privilege RBAC

#### Option B: VNet Integration + Application Gateway WAF from Day One
**Pros:** Defence in depth from the start; prevents direct internet access to ACA
**Cons:** Significant cost (Application Gateway v2 WAF SKU); operational complexity (subnet management, NSG rules, private endpoints); overkill for a greenfield project before the threat model is established

**Decision: Defer VNet/WAF** — the greenfield security baseline (TLS, managed identity, Key Vault, RBAC) is appropriate for the initial phase. VNet and WAF will be evaluated in post-MVP security hardening.

## Decision Outcome

**Chosen options:** Azure DevOps Pipelines + GitFlow + Rolling Update + OTel→Azure Monitor + GDPR-compliant security baseline (no VNet/WAF for greenfield)

### Pipeline Architecture

```
feature/* → develop → release/* → main
                ↓              ↓
           CI Pipeline    CD Pipeline
           (build/test)   (deploy to staging/prod)
```

**CI Pipeline (all branches):**
1. `dotnet restore` + `npm ci`
2. `dotnet build --no-restore`
3. `dotnet test` with coverage gate (≥80%)
4. `dotnet publish` → Docker build → push to ACR
5. `npm run build` → deploy to Azure Static Web Apps (staging slot)
6. `terraform validate` + `terraform plan`

**CD Pipeline (main branch):**
1. `terraform apply` (infrastructure changes)
2. ACA rolling deployment (new revision)
3. Smoke tests against production
4. Pipeline gate: manual approval for production deploy (optional)

### Positive Consequences

- Unified CI/CD toolchain across all scopes — single Azure DevOps organisation, consistent pipeline YAML patterns
- OTel vendor-neutral instrumentation allows switching APM backend without code changes
- Azure Monitor provides integrated traces, metrics, logs, and alerts in a single pane of glass
- GitFlow provides clear audit trail of what code is in production vs. in development
- Rolling Update ensures zero-downtime deployments with no doubled infrastructure cost
- Managed identity eliminates credential rotation risk for container-to-Azure-service communication
- GDPR compliance built-in from day one avoids costly remediation later
- ≥80% coverage gate in CI prevents quality regression as codebase grows

### Negative Consequences

- GitFlow's multiple long-lived branches require merge discipline — mitigated by short-lived feature branches and PR policies
- Azure Monitor ingestion cost scales with log volume — mitigated by structured logging with appropriate log levels (Warning+ in production) and sampling
- No VNet/WAF means workloads are accessible from the internet (protected by TLS and managed identity, but no network perimeter) — this is an accepted risk for the greenfield phase, must be reviewed post-MVP
- ≥80% coverage gate may slow initial feature velocity — accepted trade-off for long-term quality
- Mutation testing deferred — test suite quality not fully validated; revisit in post-MVP quality review

## Compliance

- Infrastructure: Terraform pipelines provision Azure Monitor, Application Insights (ADR-005)
- Backend: OTel SDK auto-instruments .NET 10 Minimal APIs (ADR-001)
- Frontend: Application Insights JS SDK integrates with Vue 3 SPA (ADR-004)
- Security: Key Vault + managed identity pattern applied to ACA deployments (ADR-005)

## Links

- [Azure DevOps Pipelines documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [OpenTelemetry .NET SDK](https://opentelemetry.io/docs/languages/net/)
- [Azure Monitor OpenTelemetry Exporter](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=net)
- [Application Insights JavaScript SDK](https://learn.microsoft.com/en-us/azure/azure-monitor/app/javascript)
- [GitFlow branching model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Azure Container Apps revisions and rolling updates](https://learn.microsoft.com/en-us/azure/container-apps/revisions)
- [GDPR compliance on Azure](https://learn.microsoft.com/en-us/compliance/regulatory/gdpr)
- ADR-001: Backend Technology Stack
- ADR-002: Backend Architecture — Modular Monolith with Simple CQRS
- ADR-003: Data Storage and Access Strategy
- ADR-004: Frontend Technology Stack
- ADR-005: Cloud Infrastructure — Azure Container Apps with Terraform
