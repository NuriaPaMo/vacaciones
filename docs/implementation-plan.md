# Implementation Plan — Vacation Management & Approval System

## Project Metadata

| Property            | Value                                      |
| ------------------- | ------------------------------------------ |
| Project Code        | VAC-MGT-2026                               |
| Project Name        | Vacation Management & Approval System      |
| Version             | 1.0                                        |
| Document Date       | 2026-08-07                                 |
| Project Start       | September 2026                             |
| Target Go-Live      | December 2026                              |
| Total Users         | ~560 (500 employees, ~50 PMs, ~10 DMs)     |
| Migration Context   | Greenfield (replacing manual email process)|
| Primary Cloud       | Microsoft Azure                            |
| Approved By         | Solution Architect · Product Owner         |

---

## Table of Contents

1. [Executive Overview](#executive-overview)
2. [Delivery Team](#delivery-team)
3. [Phase Roadmap](#phase-roadmap)
   - [Phase 0 — Discovery & Inception](#phase-0--discovery--inception)
   - [Phase 1 — Requirements Analysis](#phase-1--requirements-analysis)
   - [Phase 2 — Solution Architecture & Design](#phase-2--solution-architecture--design)
   - [Phase 3 — UX/UI Design](#phase-3--uxui-design)
   - [Phase 4 — Infrastructure & DevOps Setup](#phase-4--infrastructure--devops-setup)
   - [Phase 5 — Foundation Development](#phase-5--foundation-development)
   - [Phase 6 — Core Business Features Development](#phase-6--core-business-features-development)
   - [Phase 7 — Integrations](#phase-7--integrations)
   - [Phase 8 — Security & Compliance](#phase-8--security--compliance)
   - [Phase 9 — Testing & Quality Assurance](#phase-9--testing--quality-assurance)
   - [Phase 10 — User Acceptance Testing](#phase-10--user-acceptance-testing)
   - [Phase 11 — Deployment & Go-Live](#phase-11--deployment--go-live)
   - [Phase 12 — Hypercare](#phase-12--hypercare)
   - [Phase 13 — Continuous Improvement](#phase-13--continuous-improvement)
4. [Deliverables Register](#deliverables-register)
5. [Cross-Phase Mandatory Activities](#cross-phase-mandatory-activities)

---

## Executive Overview

The **Vacation Management & Approval System** (VAC-MGT-2026) is a greenfield, full-stack enterprise
application that replaces the current email-based vacation process for approximately 560 users
across multiple departments and projects. The system provides a centralized, auditable, and highly
visual platform for vacation request, two-level approval, capacity monitoring, and reporting.

### Strategic Objectives

| # | Objective | Target KPI |
|---|-----------|------------|
| O1 | Reduce approval cycle time | < 48 hours (from 5–7 days) |
| O2 | Centralize vacation requests | 100% of requests through the system |
| O3 | Proactive capacity management | Identify >70% over-requested periods in real time |
| O4 | Audit and compliance | 7-year audit log retention |
| O5 | Integration automation | 0 manual entries in ServiceNow |
| O6 | User adoption | > 90% adoption within 30 days post-launch |

### Technology Decisions (pre-approved via ADR)

| Scope | Stack |
|-------|-------|
| Backend | C# · .NET 10 · Minimal APIs · Modular Monolith · Simple CQRS |
| Frontend | Vue 3 · TypeScript · Vite · Azure Static Web Apps · Pinia |
| Cloud | Azure Container Apps · Azure SQL · Redis · Service Bus · Key Vault |
| Auth | Microsoft Entra ID · MSAL.js (Auth Code + PKCE) |
| IaC | Terraform · Azure DevOps Pipelines · GitFlow |
| Observability | OpenTelemetry → Azure Monitor |
| Testing | xUnit · Reqnroll · Playwright · Vitest · k6 |

---

## Delivery Team

### Team Overview

| Role | Count | Scope |
|------|-------|-------|
| Product Owner | 1 | Business alignment, backlog ownership |
| Business Analyst | 1 | Requirements, UAT coordination |
| Scrum Master | 1 | Ceremonies, impediment removal |
| Solution Architect | 1 | Architecture governance, ADRs |
| Technical Lead | 1 | Code quality, team guidance |
| Frontend Developer | 2 | Vue 3 SPA, Playwright E2E |
| Backend Developer | 3 | .NET 10 Minimal APIs, CQRS, integrations |
| QA Engineer | 2 | Test strategy, automation, UAT support |
| DevOps Engineer | 1 | CI/CD, pipelines, release management |
| Security Engineer | 1 | OWASP compliance, threat modelling, SAST/DAST |
| UX/UI Designer | 1 | Wireframes, design system, accessibility |
| Data Architect | 1 | Data model, migrations, query optimization |
| Platform Engineer | 1 | Azure infrastructure, Terraform modules, SRE |

---

### Role Definitions

#### Product Owner

**Responsibilities**

- Owns and prioritizes the product backlog
- Defines and communicates the product vision to all stakeholders
- Accepts or rejects completed user stories against acceptance criteria
- Manages stakeholder expectations and represents business interests
- Approves change requests and scope adjustments
- Signs off on each sprint review and phase exit criteria

**Key Deliverables**

- Product vision statement
- Prioritized product backlog (MoSCoW)
- Sprint goals per iteration
- Acceptance sign-off for each delivered feature
- Go/no-go decision for go-live

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0 – Discovery & Inception | High — vision, scope, stakeholder alignment |
| 1 – Requirements Analysis | High — business requirements, personas, prioritization |
| 2 – Solution Architecture | Medium — review, sign-off on ADRs |
| 3 – UX/UI Design | High — mockup approvals, user story validation |
| 4 – Infra & DevOps | Low — awareness only |
| 5 – Foundation | Low — sprint reviews |
| 6 – Core Features | High — sprint reviews, backlog refinement |
| 7 – Integrations | Medium — acceptance of integration user stories |
| 8 – Security & Compliance | Medium — policy decisions, GDPR sign-off |
| 9 – Testing & QA | Medium — defect triage, release readiness |
| 10 – UAT | High — test facilitation, sign-off authority |
| 11 – Deployment & Go-Live | High — go/no-go decision |
| 12 – Hypercare | Medium — incident prioritization |
| 13 – Continuous Improvement | High — roadmap prioritization |

---

#### Business Analyst

**Responsibilities**

- Elicit, document, and validate business and functional requirements
- Facilitate workshops with stakeholders (HR, IT, managers)
- Produce user stories with acceptance criteria and business rules
- Manage the requirements traceability matrix
- Support UAT planning and execution
- Document process-as-is and to-be workflows

**Key Deliverables**

- Business Requirements Document (BRD)
- Functional Requirements (user stories with acceptance criteria)
- Business Rules register
- Process flow diagrams (as-is / to-be)
- Requirements traceability matrix
- UAT test plan and test scripts

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0 – Discovery & Inception | High — stakeholder interviews, context analysis |
| 1 – Requirements Analysis | High — primary contributor |
| 2 – Solution Architecture | Medium — validate requirements completeness |
| 3 – UX/UI Design | High — validate flows against requirements |
| 4 – Infra & DevOps | None |
| 5 – Foundation | Low — clarification on business rules |
| 6 – Core Features | Medium — story elaboration, demo attendance |
| 7 – Integrations | Medium — integration acceptance criteria |
| 8 – Security & Compliance | Medium — GDPR requirements, data classification |
| 9 – Testing & QA | Medium — test case review, defect validation |
| 10 – UAT | High — facilitation, script execution |
| 11 – Deployment & Go-Live | Medium — cutover checklist |
| 12 – Hypercare | Low — business issue triage |
| 13 – Continuous Improvement | High — feedback analysis, roadmap input |

---

#### Scrum Master

**Responsibilities**

- Facilitate all agile ceremonies (planning, standups, retrospectives, reviews)
- Remove impediments and protect the team from external interruptions
- Coach the team on agile practices and continuous improvement
- Track and report velocity, sprint burndown, and delivery metrics
- Manage dependencies between teams and external vendors
- Maintain the risk register and escalation log

**Key Deliverables**

- Sprint velocity reports
- Impediment log
- Retrospective action items
- Risk register (delivery risks)
- Release burndown charts
- Project status reports (weekly)

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0 – Discovery & Inception | Medium — team onboarding, WoW setup |
| 1 – Requirements | Medium — story mapping facilitation |
| 2 – Architecture | Medium — team coordination |
| 3 – UX/UI Design | Medium — track design dependencies |
| 4 – Infra & DevOps | High — unblock infra setup |
| 5–9 – Construction | High — full ceremony facilitation |
| 10 – UAT | High — coordination, issue tracking |
| 11 – Go-Live | High — deployment coordination |
| 12 – Hypercare | High — incident prioritization |
| 13 – Continuous Improvement | Medium — retrospective-driven improvements |

---

#### Solution Architect

**Responsibilities**

- Define and govern the overall solution architecture
- Author Architecture Decision Records (ADRs) and seek team approval
- Ensure compliance with the Bolt Framework Constitution
- Design domain model, bounded contexts, and API contracts
- Review code for architectural compliance via NetArchTest
- Guide integration patterns (Service Bus, Graph API, ServiceNow)
- Evaluate non-functional requirements (performance, scalability, security)

**Key Deliverables**

- Solution Architecture Document (C4 model: Context, Container, Component)
- ADRs (ADR-001 through ADR-006 pre-approved; new ones as needed)
- Domain model and bounded context map
- API contract (OpenAPI 3.1 specification)
- Integration architecture diagrams
- NFR validation report (performance, scalability baselines)

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0 – Discovery | High — architectural feasibility |
| 1 – Requirements | High — NFR definition |
| 2 – Architecture | High — primary owner |
| 3 – UX/UI | Low — API contract review |
| 4 – Infra | High — architecture validation of IaC |
| 5 – Foundation | High — scaffolding review, CQRS patterns |
| 6 – Core Features | Medium — architecture review gate per Bolt |
| 7 – Integrations | High — integration design and review |
| 8 – Security | High — threat model, security architecture |
| 9 – Testing | Medium — architecture compliance tests |
| 10 – UAT | Low — escalation support |
| 11 – Go-Live | High — production readiness sign-off |
| 12 – Hypercare | Medium — incident architecture review |
| 13 – Improvement | High — architectural evolution |

---

#### Technical Lead

**Responsibilities**

- Lead the development team day-to-day
- Enforce coding standards (.editorconfig, PascalCase, nullable refs)
- Conduct code reviews and approve pull requests
- Own the technical debt register
- Mentor junior developers
- Participate in architecture discussions and translate them into implementation guidance
- Ensure quality gates pass before every merge

**Key Deliverables**

- Code review reports (per PR)
- Technical debt register
- Developer onboarding guide
- Implementation standards guide
- Technical spike results
- Bolt micro-iteration delivery sign-off

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0 – Discovery | Medium — technical feasibility review |
| 1 – Requirements | Medium — effort estimation |
| 2 – Architecture | High — implementation feasibility, CQRS binding contracts |
| 3 – UX/UI | Low |
| 4 – Infra | High — local dev environment, Aspire setup |
| 5 – Foundation | High — primary implementer alongside team |
| 6 – Core Features | High — code reviews, Bolt gates |
| 7 – Integrations | High — integration implementation review |
| 8 – Security | High — SAST findings remediation |
| 9 – Testing | High — coverage gate enforcement |
| 10 – UAT | Medium — defect triage |
| 11 – Go-Live | High — deployment execution |
| 12 – Hypercare | High — incident response |
| 13 – Improvement | High — refactoring, tech debt reduction |

---

#### Frontend Developers (×2)

**Responsibilities**

- Implement Vue 3 SPA following constitution standards (kebab-case files, PascalCase components)
- Build UI components using Tailwind CSS v4 and the established design system
- Integrate MSAL.js for Entra ID authentication (Auth Code + PKCE)
- Implement Pinia stores for state management
- Write Vitest unit/component tests (≥ 80% coverage)
- Author and maintain Playwright E2E test suite
- Integrate Azure Application Insights for RUM and Core Web Vitals

**Key Deliverables**

- Vue 3 SPA application (all 7 features)
- MSAL.js authentication integration
- Pinia state stores per bounded context
- Vitest test suite (≥ 80% coverage)
- Playwright E2E test suite (smoke + regression)
- Lighthouse CI score ≥ 90 (performance)
- Azure Static Web Apps deployment configuration

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–2 | Low — context familiarization |
| 3 – UX/UI | High — design implementation review, prototype feedback |
| 4 – Infra | Medium — Static Web Apps config, local Aspire setup |
| 5 – Foundation | High — Vue scaffold, auth flow, routing |
| 6 – Core Features | High — primary frontend delivery |
| 7 – Integrations | Medium — notification UI, admin screens |
| 8 – Security | Medium — CSP headers, GDPR consent |
| 9 – Testing | High — Vitest + Playwright execution |
| 10 – UAT | Medium — bug fixes, UI adjustments |
| 11 – Go-Live | Medium — final frontend build |
| 12 – Hypercare | Medium — UI bug fixes |
| 13 – Improvement | Medium — new features, UX enhancements |

---

#### Backend Developers (×3)

**Responsibilities**

- Implement .NET 10 Minimal APIs following Modular Monolith + Simple CQRS patterns
- Write commands, queries, and handlers following constitution binding contracts
- Implement repository/unit-of-work pattern with EF Core (writes) + Dapper (reads)
- Design and implement Azure Service Bus consumers and publishers
- Implement background services (.NET BackgroundService) for nightly jobs
- Write xUnit tests with Testcontainers for integration tests
- Author Reqnroll BDD step definitions

**Key Deliverables**

- .NET 10 Modular Monolith API (all 7 features)
- CQRS command/query handlers per feature
- EF Core migrations and seed data
- Azure Service Bus integration (async events)
- Background services (AD sync at 2:00 AM, ServiceNow export at 4:00 AM)
- xUnit unit and integration test suite (≥ 80% coverage)
- Reqnroll BDD step definitions
- OpenAPI/Swagger documentation

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–2 | Low — estimation, feasibility input |
| 3 | None |
| 4 – Infra | Medium — local dev setup, Aspire AppHost |
| 5 – Foundation | High — primary: project scaffold, auth, CQRS skeleton |
| 6 – Core Features | High — primary delivery (F-001, F-002, F-003, F-007) |
| 7 – Integrations | High — primary delivery (F-004, F-005, F-006) |
| 8 – Security | High — vulnerability remediation |
| 9 – Testing | High — unit/integration test completion |
| 10 – UAT | High — defect resolution |
| 11 – Go-Live | High — deployment support |
| 12 – Hypercare | High — on-call rotation |
| 13 – Improvement | High — feature enhancements |

---

#### QA Engineers (×2)

**Responsibilities**

- Design and own the test strategy (unit, integration, E2E, UAT, performance)
- Implement and maintain the Playwright E2E framework and fixtures
- Execute regression suites before every release
- Run k6 performance tests and validate NFR compliance
- Manage defect lifecycle (creation, triage, verification, closure)
- Support UAT with test scripts and facilitation
- Validate acceptance criteria for every user story

**Key Deliverables**

- Test strategy document
- Playwright E2E framework (fixtures, page objects, auth fixture)
- Automated regression suite (all @smoke scenarios)
- Performance test results (k6, P95 < 300 ms)
- Defect report per sprint
- UAT test scripts
- Test completion report (go-live sign-off)

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–2 | Low — test strategy alignment |
| 3 | Low — accessibility review |
| 4 – Infra | Medium — CI pipeline test stage configuration |
| 5 – Foundation | High — framework setup, smoke tests |
| 6 – Core Features | High — story-by-story acceptance testing |
| 7 – Integrations | High — integration testing, mocking |
| 8 – Security | Medium — DAST execution, vulnerability verification |
| 9 – Testing | High — primary owner of this phase |
| 10 – UAT | High — facilitation, defect log management |
| 11 – Go-Live | High — smoke test execution post-deploy |
| 12 – Hypercare | High — regression on every hotfix |
| 13 – Improvement | Medium — new test coverage |

---

#### DevOps Engineer (×1)

**Responsibilities**

- Design, implement, and maintain Azure DevOps Pipelines (build, test, security scan, deploy)
- Implement GitFlow branching strategy and branch protection rules
- Configure pipeline stages: build → lint → unit tests → security scan → deploy
- Manage artifact repositories (NuGet, npm private feeds)
- Implement rolling update deployment strategy for Azure Container Apps
- Manage secrets via Azure Key Vault references in pipelines
- Configure Terraform remote state and pipeline integration

**Key Deliverables**

- Azure DevOps Pipelines (backend CI/CD, frontend CI/CD, IaC pipeline)
- Branch protection rules and GitFlow policies
- Pipeline quality gates (coverage threshold, SAST 0 criticals)
- Artifact management configuration
- Release approval gates (manual for prod)
- Runbook: deployment procedure

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–2 | Low — pipeline design input |
| 3 | None |
| 4 – Infra | High — primary owner |
| 5 – Foundation | High — pipeline first pass |
| 6 – Core Features | Medium — pipeline maintenance |
| 7 – Integrations | Medium — pipeline updates for new modules |
| 8 – Security | High — SAST/DAST pipeline integration |
| 9 – Testing | High — test pipeline gates |
| 10 – UAT | Medium — environment management |
| 11 – Go-Live | High — production deployment execution |
| 12 – Hypercare | High — hotfix pipeline management |
| 13 – Improvement | Low — pipeline optimization |

---

#### Security Engineer (×1)

**Responsibilities**

- Conduct threat modelling (STRIDE) for the full solution
- Perform SAST using integrated tooling in Azure DevOps
- Execute DAST against the staging environment
- Perform dependency vulnerability scanning (SCA)
- Validate OWASP Top 10 compliance
- Define and enforce security baseline (TLS 1.2+, Azure-managed keys, GDPR)
- Review authentication/authorization implementation (Entra ID, JWT, policy-based authz)
- Produce security sign-off for go-live

**Key Deliverables**

- Threat model (STRIDE analysis)
- SAST report (zero criticals required)
- DAST report (OWASP ZAP or equivalent)
- Dependency audit report (SCA)
- GDPR compliance checklist
- Penetration test report (pre-go-live)
- Security sign-off document

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–2 | Medium — security requirements, threat modelling |
| 3 | Low — secure design review |
| 4 – Infra | High — IaC security review (Checkov/tfsec) |
| 5 – Foundation | High — auth implementation review |
| 6 – Core Features | Medium — per-feature security review |
| 7 – Integrations | High — API key, Graph, ServiceNow security |
| 8 – Security | High — primary owner |
| 9 – Testing | High — DAST execution |
| 10 – UAT | Low — observation |
| 11 – Go-Live | High — final security sign-off |
| 12 – Hypercare | Medium — security incident response |
| 13 – Improvement | Low — periodic security reviews |

---

#### UX/UI Designer (×1)

**Responsibilities**

- Create user journey maps and interaction flows per persona
- Produce low-fidelity wireframes for all 7 features
- Build the Tailwind CSS v4 design system (tokens, components)
- Ensure WCAG 2.1 AA accessibility compliance in all designs
- Conduct usability reviews and iterate based on stakeholder feedback
- Support frontend developers in implementing designs accurately
- Review and validate implemented UI against design specs

**Key Deliverables**

- User journey maps (3 personas: Employee, PM, DM)
- Low-fidelity HTML wireframes (all feature flows)
- Tailwind design system (tokens, component library)
- Accessibility audit report (WCAG 2.1 AA)
- UX review sign-off per sprint demo

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0 – Discovery | High — as-is experience mapping |
| 1 – Requirements | High — persona development, user journeys |
| 2 – Architecture | Low — UI architecture review |
| 3 – UX/UI | High — primary owner |
| 4 – Infra | None |
| 5 – Foundation | High — design implementation review |
| 6 – Core Features | High — ongoing UI guidance |
| 7 – Integrations | Low — notification template design |
| 8 – Security | Low |
| 9 – Testing | Medium — usability testing |
| 10 – UAT | Medium — design feedback collection |
| 11 – Go-Live | Low — launch assets |
| 12 – Hypercare | Low — UX issue triage |
| 13 – Improvement | High — UX enhancements |

---

#### Data Architect (×1)

**Responsibilities**

- Design the logical and physical data model for Azure SQL Database
- Define entity relationships, constraints, indexes, and partitioning strategy
- Author and maintain EF Core migrations
- Design query optimization patterns (Dapper read models, covering indexes)
- Define data retention policies (7-year audit log, GDPR data lifecycle)
- Validate data model alignment with bounded contexts
- Support integrations data mapping (AD → internal model, ServiceNow ↔ internal model)

**Key Deliverables**

- Entity Relationship Diagram (ERD)
- Physical data model (Azure SQL)
- EF Core migration scripts
- Query performance baseline report
- Data retention and archival policy
- Integration data mapping specifications

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–1 | Medium — data requirements elicitation |
| 2 – Architecture | High — domain model, ERD |
| 3 – UX/UI | None |
| 4 – Infra | High — Azure SQL provisioning, backup strategy |
| 5 – Foundation | High — EF Core scaffold, migrations |
| 6 – Core Features | High — query optimization per feature |
| 7 – Integrations | High — AD sync data mapping, ServiceNow mapping |
| 8 – Security | High — PII encryption, GDPR data classification |
| 9 – Testing | Medium — data integrity test review |
| 10 – UAT | Low — data issue resolution |
| 11 – Go-Live | High — production data validation |
| 12 – Hypercare | Medium — data incident support |
| 13 – Improvement | Medium — query optimization, data archival |

---

#### Platform Engineer (×1)

**Responsibilities**

- Author Terraform modules (container-apps, sql, redis, service-bus, static-web-apps, key-vault)
- Manage Azure DevOps environments and Terraform workspaces (dev, prod)
- Configure Azure Container Apps scaling, health probes, and managed identity
- Implement Azure Monitor workbooks, alerts, and dashboards
- Configure Key Vault references and managed identity for all services
- Ensure Checkov/tfsec 0 critical findings in Terraform plans
- Manage Aspire local development configuration (AppHost, ServiceDefaults)

**Key Deliverables**

- Terraform modules for all Azure resources
- Azure DevOps environment definitions
- Aspire AppHost configuration (local dev)
- Azure Monitor dashboards and alert rules
- Checkov/tfsec scan reports (0 criticals)
- Infracost report (cost projection)
- SRE runbook (scaling, failover procedures)

**Involvement by Phase**

| Phase | Involvement |
|-------|-------------|
| 0–2 | Medium — infrastructure sizing, cost modelling |
| 3 | None |
| 4 – Infra | High — primary owner |
| 5 – Foundation | High — Aspire local dev support |
| 6 – Core Features | Medium — scaling configuration |
| 7 – Integrations | Medium — Service Bus topics/subscriptions |
| 8 – Security | High — managed identity, Key Vault |
| 9 – Testing | Medium — performance environment |
| 10 – UAT | Medium — UAT environment |
| 11 – Go-Live | High — production provisioning |
| 12 – Hypercare | High — on-call escalation, scaling |
| 13 – Improvement | Medium — cost optimization, reliability |

---

## Phase Roadmap

:::mermaid
gantt
    title VAC-MGT-2026 — Delivery Roadmap (Sep – Dec 2026)
    dateFormat  YYYY-MM-DD
    section Pre-Construction
    Phase 0  Discovery & Inception      :p0, 2026-09-01, 5d
    Phase 1  Requirements Analysis      :p1, after p0, 5d
    Phase 2  Architecture & Design      :p2, after p1, 5d
    Phase 3  UX/UI Design               :p3, after p2, 5d
    Phase 4  Infra & DevOps Setup       :p4, after p2, 7d
    section Construction
    Phase 5  Foundation Development     :p5, after p4, 10d
    Phase 6  Core Business Features     :p6, after p5, 28d
    Phase 7  Integrations               :p7, after p5, 20d
    Phase 8  Security & Compliance      :p8, after p6, 7d
    section Validation
    Phase 9  Testing & QA               :p9, after p8, 10d
    Phase 10 User Acceptance Testing    :p10, after p9, 7d
    section Release
    Phase 11 Deployment & Go-Live       :p11, after p10, 3d
    Phase 12 Hypercare                  :p12, after p11, 14d
    Phase 13 Continuous Improvement     :p13, after p12, 30d
:::

---

### Phase 0 — Discovery & Inception

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 1 (5 business days) |
| Complexity | Medium |
| Objective | Establish project foundations, validate scope, align stakeholders, and set up the delivery framework |

#### Scope

Stakeholder alignment, project charter, team onboarding, existing system analysis (email-based
process), review of the RFP (VAC-MGT-2026) and Functional Requirements Document, Ways of Working
(WoW) definition, tool setup, and initial risk register.

#### Activities

**Architecture**

- Review pre-approved ADRs (ADR-001 through ADR-006) with the delivery team
- Validate architectural feasibility against the full feature set (F-001 – F-007)
- Produce the initial C4 Context Diagram
- Identify integration points (Entra ID, Microsoft Graph API, ServiceNow Table API)

**Security**

- Classify data assets: employee PII, approval history, vacation balances
- Identify regulatory requirements: GDPR, corporate data policies
- Begin STRIDE threat modelling at the context level

**DevOps**

- Create Azure DevOps project and repositories (backend, frontend, infra)
- Configure GitFlow branching strategy and branch protection policies
- Establish team access and permissions matrix

**Testing**

- Define test strategy approach: TDD (backend) + BDD (features) + Playwright (E2E)
- Review constitution quality thresholds (≥ 80% line coverage, ≥ 75% branch coverage)

**Documentation**

- Draft project charter
- Document Ways of Working (ceremonies, PR etiquette, Definition of Done)
- Capture stakeholder map and RACI matrix

**Compliance**

- Identify GDPR obligations: data subjects, retention periods, right-to-erasure implications
- Review 7-year audit log requirement and its technical implications

**Performance**

- Document NFR baseline targets: API P95 < 300 ms, background jobs time limits
- Record user load profile: 500 employees, peak usage Monday mornings

**Observability**

- Define observability strategy: OTel → Azure Monitor, Application Insights RUM
- Identify key SLOs: API availability ≥ 99.5%, background job success rate ≥ 99%

#### Deliverables

- Project Charter
- Stakeholder Map and RACI
- Ways of Working document
- Initial Risk Register
- C4 Context Diagram (draft)
- Azure DevOps project and repositories
- GitFlow branch strategy documentation

#### Dependencies

- RFP (origin/RFP-Vacaciones.md) — available
- Functional Requirements Document (origin/Documento Funcional de Requisitos.html) — available
- Access to corporate Active Directory (read-only) — TBC
- ServiceNow sandbox environment — TBC

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Stakeholder availability low | Medium | High | Schedule kick-off workshops 2 weeks ahead |
| AD/ServiceNow access delayed | High | High | Request access in Week 1; use mocks for dev |
| Scope creep during inception | Medium | Medium | Freeze scope after kick-off; change control process |

#### Assumptions

- All pre-approved ADRs (ADR-001 – ADR-006) remain valid
- Microsoft Azure is the mandatory cloud provider
- Entra ID tenant exists and is accessible for integration

#### Exit Criteria

- [ ] Project charter signed by PO and sponsor
- [ ] Azure DevOps project created with repositories
- [ ] GitFlow strategy documented and branch protection configured
- [ ] Team onboarded and access provisioned
- [ ] Initial risk register created with top-10 risks

#### Responsible Roles

Primary: Product Owner · Solution Architect · Scrum Master
Supporting: Business Analyst · Technical Lead · Platform Engineer

---

### Phase 1 — Requirements Analysis

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 2 (5 business days) |
| Complexity | High |
| Objective | Produce a complete, prioritized, and validated set of requirements covering all dimensions: business, functional, non-functional, user journeys, personas, and acceptance criteria |

#### Scope

Full requirements elaboration for all 7 features (F-001 – F-007), resolution of outstanding
clarifications (CL-001 – CL-013), persona definition, user journey mapping, and MoSCoW
prioritization.

---

#### Business Requirements

The following high-level business requirements govern the system:

| ID | Requirement | Priority |
|----|-------------|----------|
| BR-BIZ-001 | Replace email-based vacation process with a centralized digital system | Must Have |
| BR-BIZ-002 | Support two-level approval workflow (Project Manager → Department Manager) | Must Have |
| BR-BIZ-003 | Provide real-time visibility of team vacation coverage for managers | Must Have |
| BR-BIZ-004 | Flag over-requested periods visually when > 70% team capacity is absent | Must Have |
| BR-BIZ-005 | Reduce vacation approval cycle time from 5–7 days to < 48 hours | Must Have |
| BR-BIZ-006 | Maintain a complete, tamper-proof audit trail for all system actions | Must Have |
| BR-BIZ-007 | Retain audit data for a minimum of 7 years | Must Have |
| BR-BIZ-008 | Integrate with corporate Active Directory for employee synchronization | Must Have |
| BR-BIZ-009 | Export approved vacations to ServiceNow automatically (nightly) | Must Have |
| BR-BIZ-010 | Notify employees, PMs, and DMs via email for all workflow events | Must Have |
| BR-BIZ-011 | Enable delegation of approval authority during approver absence | Must Have |
| BR-BIZ-012 | Provide reporting and analytics on vacation patterns and coverage | Must Have |
| BR-BIZ-013 | Support ~560 concurrent users with seasonal scalability (summer peak) | Must Have |
| BR-BIZ-014 | Comply with GDPR data protection requirements | Must Have |

---

#### Functional Requirements

| ID | Feature | Requirement | Priority |
|----|---------|-------------|----------|
| FR-001 | F-001 | Employee can submit a vacation request with start/end dates and optional notes | Must Have |
| FR-002 | F-001 | System calculates business days automatically (Mon–Fri, excluding weekends) | Must Have |
| FR-003 | F-001 | System validates vacation balance before submission | Must Have |
| FR-004 | F-001 | System prevents overlapping requests for the same employee | Must Have |
| FR-005 | F-001 | Employee can cancel a pending or approved request | Must Have |
| FR-006 | F-002 | PM receives notification on new request submission | Must Have |
| FR-007 | F-002 | PM can approve or reject (with mandatory reason) at project level | Must Have |
| FR-008 | F-002 | DM can approve or reject (with reason) at department level | Must Have |
| FR-009 | F-002 | DM can override a PM rejection (employee appeal path) | Must Have |
| FR-010 | F-002 | Automatic escalation to DM after 48 hours if PM has not acted | Must Have |
| FR-011 | F-002 | Approval delegation: PM assigns substitute when unavailable | Must Have |
| FR-012 | F-003 | Team calendar view showing approved and pending vacations | Must Have |
| FR-013 | F-003 | Visual heat-map highlighting periods > 70% capacity threshold | Must Have |
| FR-014 | F-003 | Department-level capacity dashboard for DMs | Must Have |
| FR-015 | F-003 | Calendar supports drill-down: department → project → individual | Should Have |
| FR-016 | F-004 | Nightly AD synchronization via Microsoft Graph API at 2:00 AM | Must Have |
| FR-017 | F-004 | Sync creates, updates, and soft-deletes employees based on AD state | Must Have |
| FR-018 | F-004 | Sync handles partial failures with retry (max 3 attempts) | Must Have |
| FR-019 | F-005 | Nightly export of approved vacations to ServiceNow Table API at 4:00 AM | Must Have |
| FR-020 | F-005 | Delta sync: only export new/changed records since last successful run | Must Have |
| FR-021 | F-005 | Cancelled vacations trigger removal in ServiceNow | Must Have |
| FR-022 | F-006 | Email notification for all workflow events within 5 minutes | Must Have |
| FR-023 | F-006 | Avanade-branded HTML email templates with action deep-links | Must Have |
| FR-024 | F-006 | Capacity alert email to DM when department > 70% threshold | Must Have |
| FR-025 | F-007 | Vacation history report filterable by date range, department, employee, status | Must Have |
| FR-026 | F-007 | Approval time report showing average processing time per approver | Must Have |
| FR-027 | F-007 | Export reports to CSV, Excel, and PDF | Should Have |
| FR-028 | F-007 | Admin panel for threshold configuration, email templates, and role management | Must Have |
| FR-029 | F-007 | Full audit log with 7-year retention accessible to auditors | Must Have |

---

#### Non-Functional Requirements

| ID | Category | Requirement | Target |
|----|----------|-------------|--------|
| NFR-001 | Performance | API response time (P95) | < 300 ms |
| NFR-002 | Performance | Report generation time | < 5 seconds for 1 year of data |
| NFR-003 | Performance | Background job — AD sync | Complete within 30 minutes for 500 employees |
| NFR-004 | Performance | Background job — ServiceNow export | Complete within 15 minutes for 50 records |
| NFR-005 | Scalability | Peak concurrent users | 560 (seasonal scalability via Azure Container Apps) |
| NFR-006 | Availability | System uptime | ≥ 99.5% (measured monthly) |
| NFR-007 | Reliability | Background job success rate | ≥ 99% |
| NFR-008 | Security | Authentication | Entra ID · Auth Code + PKCE · JWT Bearer |
| NFR-009 | Security | Transport security | TLS 1.2+ enforced everywhere |
| NFR-010 | Security | Secrets management | Azure Key Vault (prod); never in source code or env vars |
| NFR-011 | Security | SAST | Zero critical vulnerabilities at go-live |
| NFR-012 | Data | Audit retention | 7 years minimum |
| NFR-013 | Compliance | GDPR | PII encrypted at rest; right-to-erasure mechanism |
| NFR-014 | Observability | Distributed tracing | 100% API requests traced via OTel |
| NFR-015 | Observability | Health endpoints | /health /health/ready /health/live |
| NFR-016 | Maintainability | Code coverage | ≥ 80% line, ≥ 75% branch |
| NFR-017 | Maintainability | Architecture conformance | 100% (NetArchTest validates on CI) |
| NFR-018 | Usability | Accessibility | WCAG 2.1 AA |
| NFR-019 | Usability | Browser support | Latest Chrome, Edge, Firefox, Safari |
| NFR-020 | Frontend performance | Lighthouse performance score | ≥ 90 |

---

#### User Journeys

##### Journey 1 — Employee Submits and Tracks a Vacation Request

```text
[Login via Entra ID]
    → [View Team Calendar — check teammate availability]
    → [Navigate to "New Request"]
    → [Select dates on visual calendar]
    → [System shows: business days count + remaining balance]
    → [Add optional notes] → [Submit Request]
    → [Email confirmation sent to employee]
    → [Notification sent to PM]
    → [Track status in "My Requests" dashboard]
    → [Receive email: Approved / Rejected]
    → [If rejected at PM level: option to appeal to DM]
```

##### Journey 2 — Project Manager Approves a Vacation Request

```text
[Receive email notification with deep-link]
    → [Login via Entra ID OR click action link]
    → [View approval queue: pending requests for my projects]
    → [Review request: employee, dates, days, capacity impact indicator]
    → [Click Approve OR Reject (with mandatory reason)]
    → [System routes to DM queue (if approved) OR notifies employee (if rejected)]
    → [View updated team calendar reflecting the decision]
```

##### Journey 3 — Department Manager Reviews Coverage and Approves

```text
[Receive email: request pending department approval]
    → [View DM approval queue: project-approved requests + appeal requests]
    → [Review department capacity heat-map: is the period > 70%?]
    → [If over capacity: view suggested alternative dates for employee]
    → [Click Approve (final) or Reject with reason]
    → [Employee notified immediately]
    → [ServiceNow export includes the record in next nightly batch]
```

##### Journey 4 — DM Reviews Capacity Reports

```text
[Navigate to Reports]
    → [Select: "Coverage Analysis" → date range: July 2027]
    → [View heat-map: red weeks (>70%), amber weeks (50–70%), green (<50%)]
    → [Drill down: department → project → individual]
    → [Export to Excel for executive presentation]
```

---

#### Personas

##### Persona 1 — Ana García (Employee)

| Attribute | Detail |
|-----------|--------|
| Role | Software Developer |
| Technical proficiency | High |
| Primary goal | Submit requests quickly, track status in real time |
| Pain point | No confirmation that email was received; approval takes 5–7 days |
| Key feature | Visual calendar date picker, real-time status updates |
| Device | Desktop (primary), mobile (status check) |

##### Persona 2 — Carlos Ruiz (Project Manager)

| Attribute | Detail |
|-----------|--------|
| Role | Senior Project Manager |
| Technical proficiency | Medium |
| Primary goal | Approve requests quickly without coverage gaps |
| Pain point | Multiple email chains across 15 team members; no calendar overview |
| Key feature | Approval queue with capacity impact indicator; email deep-links |
| Device | Desktop |

##### Persona 3 — Laura Sánchez (Department Manager / HR)

| Attribute | Detail |
|-----------|--------|
| Role | Department Director |
| Technical proficiency | Low–Medium |
| Primary goal | Ensure department coverage; generate compliance reports |
| Pain point | No aggregated view; audit trail must be produced manually |
| Key feature | Department capacity heat-map; automated ServiceNow export; reporting |
| Device | Desktop |

##### Persona 4 — Miguel Torres (IT Administrator)

| Attribute | Detail |
|-----------|--------|
| Role | IT Administrator |
| Technical proficiency | High |
| Primary goal | Monitor integration health; configure system parameters |
| Pain point | Manual user management when employees change departments |
| Key feature | Admin panel, AD sync health dashboard, integration logs |
| Device | Desktop |

---

#### Acceptance Criteria Standards

All acceptance criteria must follow the format:

```gherkin
Given [precondition / context]
When  [action]
Then  [expected observable outcome]
```

Classification:

| Tag | Description |
|-----|-------------|
| `@smoke` | Minimum viable acceptance; must pass for any release candidate |
| `@regression` | Must pass before every deployment |
| (none) | Full suite; must pass for UAT sign-off |

---

#### Requirement Prioritization (MoSCoW)

| Priority | Features / Capabilities |
|----------|------------------------|
| **Must Have** | F-001 Vacation Request Management |
| **Must Have** | F-002 Approval Workflow (two-level: PM + DM) |
| **Must Have** | F-003 Calendar & Capacity Visualization |
| **Must Have** | F-004 Active Directory Integration (nightly sync) |
| **Must Have** | F-005 ServiceNow Integration (nightly export) |
| **Must Have** | F-006 Notifications (email) |
| **Must Have** | F-007 Reporting & Administration (audit log, admin panel) |
| **Should Have** | Calendar drill-down (department → project → individual) |
| **Should Have** | Report export (CSV, Excel, PDF) |
| **Should Have** | Microsoft Teams notifications (Phase 2) |
| **Could Have** | Mobile app (Phase 2) |
| **Won't Have (v1)** | Teams adaptive cards, public holiday calendar by country |

---

#### Activities (Phase 1)

**Architecture**

- Validate domain model against all 7 feature requirements
- Identify bounded contexts: VacationManagement, ApprovalWorkflow, Notifications, Reporting, Identity

**Security**

- Classify all data fields for GDPR (PII identification: names, email, HR data)
- Define data retention rules per entity type

**DevOps**

- Create feature branches for all 7 features in Azure DevOps
- Configure work items linked to requirements

**Testing**

- Derive acceptance criteria for all user stories (in collaboration with BA and PO)
- Tag @smoke vs full-suite criteria

**Documentation**

- Produce BRD, functional spec, business rules register
- Document resolved clarifications (CL-001 – CL-013)
- Author use cases (UC-001 – UC-028, already in `specs/`)

**Compliance**

- GDPR data flow diagram
- Data Processing Agreement (DPA) review

**Performance**

- Document NFR targets in machine-readable format (k6 SLO config)

**Observability**

- Define SLO dashboard requirements

#### Exit Criteria

- [ ] All requirements documented and reviewed by PO and BA
- [ ] All clarifications (CL-001 – CL-013) resolved
- [ ] Requirements traceability matrix (RTM) complete
- [ ] All acceptance criteria approved by PO
- [ ] MoSCoW prioritization agreed by stakeholders
- [ ] GDPR data classification complete

#### Responsible Roles

Primary: Business Analyst · Product Owner
Supporting: Solution Architect · UX/UI Designer · Security Engineer

---

### Phase 2 — Solution Architecture & Design

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 3 (5 business days) |
| Complexity | High |
| Objective | Produce the complete, approved solution architecture including domain model, data model, API contracts, integration designs, and non-functional architecture |

#### Scope

C4 architecture (Context, Container, Component diagrams), domain model, bounded contexts, ERD,
OpenAPI specification, integration architecture (Graph API, ServiceNow), caching strategy, Service
Bus topology, and infrastructure sizing.

#### Activities

**Architecture**

- Produce C4 Container Diagram: API (Container Apps), SPA (Static Web Apps), Azure SQL, Redis, Service Bus
- Design Modular Monolith structure: modules per bounded context
- Define CQRS binding contracts (as per constitution — already defined in constitution.digest.md)
- Design Service Bus topic/subscription topology for async events
- Author integration architecture: Microsoft Graph API → AD sync pattern, ServiceNow Table API → export pattern
- Create OpenAPI 3.1 specification for all REST endpoints
- Design caching strategy: L1 IMemoryCache (5 min) → L2 Redis (30 min) → Cache-Aside pattern

**Security**

- Complete STRIDE threat model
- Design authorization model: policy-based (Employee / PM / DM / Admin roles)
- Define JWT claim mappings from Entra ID
- Design managed identity access pattern (no secrets in container env vars)

**DevOps**

- Design pipeline architecture: build → lint → unit tests → SAST → deploy stages
- Define Terraform module structure and workspace strategy

**Testing**

- Define test pyramid targets per layer (unit: 70%, integration: 20%, E2E: 10%)
- Identify integration test containers (Testcontainers: SQL Server, Redis, Service Bus emulator)

**Documentation**

- Solution Architecture Document (SAD)
- ADR authoring for any new decisions
- OpenAPI specification (contracts/openapi.yaml)
- Data model documentation (requirements/data-model.md)

**Compliance**

- Architecture review against GDPR: data at rest encryption, audit log immutability

**Performance**

- Architecture-level performance analysis: expected query patterns, index strategy
- Caching impact analysis: which queries benefit from Redis

**Observability**

- OTel instrumentation plan: which spans, metrics, and logs per module
- Define structured log schema

#### Deliverables

- Solution Architecture Document (C4: Context + Container + Component)
- Domain model and bounded context map
- Entity Relationship Diagram (ERD)
- OpenAPI 3.1 specification (contracts/openapi.yaml)
- Integration architecture diagram
- Service Bus topology diagram
- STRIDE threat model
- Authorization matrix (role → resource → operation)

#### Dependencies

- Phase 1 requirements complete and approved
- ADR-001 – ADR-006 validated by team

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| OpenAPI spec incomplete | Medium | High | Contract-first approach; derive spec from data model |
| ServiceNow API breaking changes | Low | High | Pin API version; use versioned endpoint |
| Graph API rate limits underestimated | Medium | Medium | Design with retry + exponential backoff from the start |

#### Assumptions

- ServiceNow sandbox credentials will be available for integration development
- Microsoft Graph API read permissions granted (User.Read.All, Group.Read.All)

#### Exit Criteria

- [ ] C4 diagrams (Context, Container, Component) reviewed and approved by Solution Architect
- [ ] OpenAPI specification covering all endpoints merged to main
- [ ] ERD reviewed and approved by Data Architect
- [ ] STRIDE threat model complete
- [ ] Authorization matrix approved by Security Engineer and PO
- [ ] Architecture peer-reviewed by Technical Lead

#### Responsible Roles

Primary: Solution Architect · Data Architect
Supporting: Technical Lead · Security Engineer · Platform Engineer

---

### Phase 3 — UX/UI Design

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 4 (5 business days) — runs in parallel with Phase 4 |
| Complexity | Medium |
| Objective | Deliver approved UX/UI designs for all 7 features, establishing the design system and interaction patterns used throughout construction |

#### Scope

Low-fidelity wireframes (static HTML + Tailwind v4), user journey validation, design system
definition, accessibility baseline, and stakeholder design approval.

> **Note:** Per the constitution (design-tool = none), the Design Gate is inactive. Wireframes are
> produced as static HTML mockups. No Penpot integration is required for this project.

#### Activities

**Architecture**

- Review API endpoints from OpenAPI spec to validate UI data requirements
- Confirm component-to-endpoint mapping for each feature

**Security**

- Review GDPR UI requirements: no PII displayed unnecessarily, consent flows
- WCAG 2.1 AA accessibility design review

**DevOps**

- Store wireframe HTML files in `specs/[feature]/mockups/`

**Testing**

- Define visual regression baseline for Playwright
- Plan accessibility testing (automated via axe-core in Playwright)

**Documentation**

- Design system documentation (tokens, component catalogue)
- Wireframe annotation documents

**Compliance**

- Accessibility audit (WCAG 2.1 AA) for all designed screens

**Performance**

- Design with performance in mind: avoid heavy assets, lazy load calendars
- Lighthouse CI threshold defined: ≥ 90 performance score

**Observability**

- Define UI telemetry events (Application Insights custom events) per user action

#### Key Screens

| Screen | Feature | Persona |
|--------|---------|---------|
| My Requests dashboard | F-001 | Employee |
| New Request form (visual calendar picker) | F-001 | Employee |
| PM Approval queue | F-002 | Project Manager |
| DM Approval queue with capacity warning | F-002 | Department Manager |
| Team calendar heat-map view | F-003 | PM / DM |
| Department coverage dashboard | F-003 | DM |
| Vacation history report | F-007 | DM |
| Admin panel (thresholds, templates, roles) | F-007 | Administrator |

#### Deliverables

- Static HTML wireframes (all screens, all states: default / loading / error / empty)
- Tailwind CSS v4 design system (tokens: colors, spacing, typography)
- User journey flow diagrams (3 personas)
- Accessibility audit report (WCAG 2.1 AA)
- Design review sign-off from PO

#### Dependencies

- Phase 1 requirements complete (personas, user journeys)
- Phase 2 OpenAPI spec (to validate data available for each screen)

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Design iterations consuming too much time | High | Medium | Time-box to 3 rounds of feedback |
| Accessibility gaps discovered late | Medium | Medium | Audit during design, not post-implementation |

#### Assumptions

- No external design tool (Figma/Penpot) required per constitution
- Tailwind CSS v4 CDN used for wireframe prototypes

#### Exit Criteria

- [ ] All key screens wireframed (all states: default, loading, error, empty)
- [ ] Design system token file created
- [ ] PO and stakeholder design approval obtained
- [ ] WCAG 2.1 AA accessibility audit complete
- [ ] Mockups stored in `specs/[feature]/mockups/` and indexed

#### Responsible Roles

Primary: UX/UI Designer
Supporting: Business Analyst · Frontend Developers · Product Owner

---

### Phase 4 — Infrastructure & DevOps Setup

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 4–5 (7 business days) — overlaps with Phase 3 |
| Complexity | High |
| Objective | Provision all Azure infrastructure, CI/CD pipelines, and local development environment so the construction team can begin immediately after |

#### Scope

Terraform modules for all Azure resources, Azure DevOps Pipelines (backend, frontend, IaC), Aspire
AppHost configuration, Key Vault setup, managed identity configuration, and monitoring baseline.

#### Activities

**Architecture**

- Validate Terraform module structure against architecture design
- Configure Aspire AppHost service discovery: API, Azure SQL, Redis, Service Bus emulator

**Security**

- Run Checkov/tfsec on all Terraform modules (zero criticals required)
- Configure Key Vault with managed identity access policies
- Enable audit logging on Azure SQL and Key Vault
- Enforce TLS 1.2+ on all Azure Container Apps ingress

**DevOps**

- Implement Azure DevOps backend pipeline: build → lint → unit tests (≥80%) → SAST → deploy to dev
- Implement Azure DevOps frontend pipeline: npm install → lint → Vitest → Playwright → deploy to Static Web Apps
- Implement IaC pipeline: tflint → terraform plan → Checkov → Infracost → terraform apply (auto dev / manual prod)
- Configure GitFlow policies: feature branches, PR requirements, code owner review
- Set up environment definitions: dev (auto) and prod (manual approval gate)
- Configure Infracost reporting (cost per PR)

**Testing**

- Verify pipeline test gates: build fails if coverage < 80%
- Configure Testcontainers base images available in pipeline agents
- Set up Playwright browser installation in pipeline

**Documentation**

- Infrastructure runbook (provision, destroy, scaling procedures)
- Pipeline documentation (what each stage does, how to re-run)

**Compliance**

- Enable Azure Policy for GDPR-required configurations
- Configure Azure SQL encryption at rest (TDE enabled by default)
- Set retention policies on Log Analytics workspace (90 days hot, 7 years archive)

**Performance**

- Configure Azure Container Apps auto-scaling rules (min 1, max 10 replicas)
- Configure Redis maxmemory-policy for cache eviction

**Observability**

- Create Azure Monitor workspace and Log Analytics workspace
- Configure OTel collector settings and Azure Monitor exporter
- Create initial dashboards: API health, job status, error rate
- Configure alert rules: error rate > 1%, job failure

#### Terraform Modules

| Module | Resources |
|--------|-----------|
| `container-apps` | Azure Container Apps environment, Container App (API) |
| `sql` | Azure SQL Server, Azure SQL Database, firewall rules |
| `redis` | Azure Cache for Redis (Basic/Standard per env) |
| `service-bus` | Azure Service Bus namespace, topics, subscriptions |
| `static-web-apps` | Azure Static Web Apps (frontend) |
| `key-vault` | Azure Key Vault, access policies, secrets structure |
| `monitoring` | Log Analytics, Application Insights, Alert rules, Workbooks |

#### Deliverables

- Terraform modules for all 7 resource types (dev workspace applied and verified)
- Azure DevOps pipelines: backend CI/CD, frontend CI/CD, IaC pipeline
- Aspire AppHost project (`src/AppHost/`)
- Azure Monitor dashboards and alert rules
- Checkov/tfsec scan report (0 criticals)
- Infracost baseline report
- Infrastructure runbook

#### Dependencies

- Phase 2 architecture decisions finalized
- Azure subscription provisioned with required resource provider registrations
- Service Principal created for Terraform (or Managed Identity for Azure DevOps)
- Microsoft Entra ID app registration for the SPA (Auth Code + PKCE)

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Azure quota limits | Medium | High | Request quota increases in Week 1 |
| Terraform state conflicts | Low | High | Single remote state with workspace locking |
| Checkov false positives blocking pipeline | Medium | Low | Configure skip rules for known false positives |
| Entra ID app registration delayed | Medium | High | Create registration in Phase 0 |

#### Assumptions

- Azure Container Apps are used (not AKS) — per constitution
- No VNet / private endpoints (greenfield) — per constitution
- Azure-managed keys (no CMK) — per constitution

#### Exit Criteria

- [ ] All Terraform modules applied to dev workspace with zero errors
- [ ] Backend and frontend pipelines run successfully end-to-end (with placeholder application)
- [ ] Checkov/tfsec report: 0 critical findings
- [ ] Aspire AppHost runs locally and discovers all services
- [ ] Key Vault provisioned and managed identity access configured
- [ ] Azure Monitor dashboards visible with baseline metrics

#### Responsible Roles

Primary: Platform Engineer · DevOps Engineer
Supporting: Solution Architect · Security Engineer · Technical Lead

---

### Phase 5 — Foundation Development

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 5–6 (10 business days) |
| Complexity | High |
| Objective | Implement the foundational technical skeleton of the application: project structure, authentication, CQRS infrastructure, database scaffold, and CI/CD validation |

#### Scope

.NET 10 solution structure (Modular Monolith), CQRS dispatchers and handler registration, EF Core
DbContext with initial migrations, Entra ID auth middleware, Vue 3 SPA scaffold with MSAL.js,
OpenAPI documentation setup, OTel instrumentation, health endpoints, and BaseEntity/audit
infrastructure.

#### Activities

**Architecture**

- Scaffold Modular Monolith solution: `src/Modules/[ModuleName]/`, `src/Api/`, `src/Infrastructure/`
- Implement CQRS binding contracts (ICommand, IQuery, ICommandHandler, IQueryHandler, ICommandDispatcher, IQueryDispatcher) exactly as defined in constitution
- Register CQRS handlers via DI (no MediatR)
- Implement NetArchTest project to validate architecture constraints on every build
- Scaffold Vue 3 SPA: `src/frontend/` with Vite config, Vue Router, Pinia, TypeScript strict mode

**Security**

- Integrate JWT Bearer authentication middleware (Entra ID issuer)
- Implement policy-based authorization: Employee, ProjectManager, DepartmentManager, Administrator
- Configure CORS policy for Static Web Apps origin
- Implement HTTPS redirect and HSTS headers
- Configure Content Security Policy headers

**DevOps**

- Validate full pipeline with skeleton app (build, test, deploy)
- Configure code coverage reporting (Coverlet → Azure DevOps)
- Configure Playwright test step in frontend pipeline

**Testing**

- Implement xUnit test project structure per module
- Create Testcontainers SQL Server container for integration tests
- Set up Reqnroll BDD project with feature file scaffold
- Implement Playwright project structure (fixtures, page objects, auth fixture)
- Implement Vitest setup for Vue 3 components

**Documentation**

- Developer onboarding README (`src/README.md`)
- CQRS implementation guide (`docs/guides/cqrs-guide.md`)
- Authentication flow documentation

**Compliance**

- Implement audit log base infrastructure: AuditEntry entity, EF Core interceptor
- Ensure PII fields marked with custom attribute for future encryption

**Performance**

- Configure IMemoryCache with 5-minute sliding expiration
- Implement Redis connection factory with Circuit Breaker (Polly)

**Observability**

- Configure OTel SDK: traces, metrics, logs → Azure Monitor Exporter
- Implement /health, /health/ready, /health/live endpoints
- Add structured logging baseline (Serilog or ILogger with OTel)
- Instrument CQRS dispatcher with activity spans

#### Key Technical Tasks

```csharp
// CQRS Infrastructure — constitution binding contracts
src/Infrastructure/Cqrs/CommandDispatcher.cs
src/Infrastructure/Cqrs/QueryDispatcher.cs
src/Infrastructure/Cqrs/ServiceCollectionExtensions.cs

// Domain Base
src/Domain/Common/BaseEntity.cs
src/Domain/Common/AggregateRoot.cs
src/Domain/Common/DomainEvent.cs

// EF Core
src/Infrastructure/Persistence/ApplicationDbContext.cs
src/Infrastructure/Persistence/Migrations/

// Auth Middleware
src/Api/Auth/JwtBearerConfiguration.cs
src/Api/Auth/AuthorizationPolicies.cs

// Health
src/Api/Health/HealthCheckExtensions.cs
```

#### Deliverables

- .NET 10 Modular Monolith solution (compiling, all tests green)
- Vue 3 SPA scaffold (MSAL.js auth flow working end-to-end with Entra ID dev tenant)
- EF Core initial migration applied to dev database
- NetArchTest suite (architecture rules enforced on CI)
- CQRS infrastructure (all contracts + dispatchers)
- OTel instrumentation baseline (traces visible in Azure Monitor)
- Health endpoints responding on dev environment
- Foundation test suite (unit + integration) at ≥ 50% coverage of scaffold code

#### Dependencies

- Phase 4 complete (infrastructure and pipelines operational)
- Phase 3 complete (design system available for frontend scaffold)
- Entra ID app registration and dev tenant accessible

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| EF Core migration conflicts | Medium | Medium | Single migration owner; migrate on feature branch |
| MSAL.js Entra ID integration issues | Medium | High | Allocate 1 day spike; use MSAL documentation examples |
| NetArchTest false failures | Low | Low | Review rules carefully; document exceptions |

#### Assumptions

- Aspire AppHost handles local service discovery for dev
- Dev Entra ID tenant allows SPA registration and localhost redirect URIs

#### Exit Criteria

- [ ] Solution builds with zero warnings (warnings as errors)
- [ ] Full pipeline green (build, lint, test, deploy) for both backend and frontend
- [ ] MSAL.js auth flow tested end-to-end (employee, PM, DM roles)
- [ ] EF Core migration applied successfully to dev Azure SQL
- [ ] Health endpoints return 200 OK on dev Container App
- [ ] OTel traces visible in Azure Monitor for at least one API call
- [ ] NetArchTest suite passes (architecture conformance)
- [ ] Code coverage ≥ 50% for scaffold code

#### Responsible Roles

Primary: Technical Lead · Backend Developers · Frontend Developers
Supporting: Solution Architect · Data Architect · Platform Engineer

---

### Phase 6 — Core Business Features Development

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 7–12 (6 sprints / 28 business days) |
| Complexity | High |
| Objective | Implement all core business features (F-001, F-002, F-003, F-007) using Bolt micro-iterations with mandatory quality gates after each Bolt |

#### Scope

Full implementation of vacation request lifecycle (F-001), two-level approval workflow (F-002),
calendar and capacity visualization (F-003), and reporting & administration module (F-007). Each
Bolt is a 2-day micro-iteration with exit quality gates.

#### Bolt Breakdown

| Bolt | Feature | Backend | Frontend | Duration |
|------|---------|---------|---------|----------|
| Bolt 1 | F-001 — Vacation Request Management | VacationRequest entity, CreateVacationRequestCommand, balance validation, business day calculator | New Request form, date picker, My Requests list | Week 7 |
| Bolt 2 | F-002 — Approval Workflow | ApproveCommand, RejectCommand, EscalationBackgroundService, delegation handlers | PM approval queue, DM approval queue, appeal flow | Week 8–9 |
| Bolt 3 | F-003 — Calendar & Capacity | CalendarQuery, CapacityCalculationService, Redis cache for capacity data | Team calendar heat-map, capacity dashboard, drill-down | Week 10 |
| Bolt 4 (partial) | F-007 — Reporting | VacationHistoryQuery, ApprovalTimeQuery, AuditLogQuery | Reports page, filters, CSV/Excel export | Week 11 |
| Bolt 5 (partial) | F-007 — Admin | AdminThresholdCommand, EmailTemplateCommand, RoleAssignmentCommand | Admin panel, configuration screens | Week 12 |

#### Activities

**Architecture**

- Architecture review gate at the end of each Bolt (Solution Architect or Technical Lead)
- NetArchTest must pass after every feature merge
- Module dependency validation (no cross-module direct calls; use CQRS dispatchers)

**Security**

- Per-feature security review: authorization checks on every endpoint
- Validate policy-based authz (Employee cannot access DM endpoints, etc.)
- Input validation on all commands (FluentValidation or custom validators)

**DevOps**

- Feature branch per Bolt (`bolt/[feature]-[bolt-name]`)
- PR required with at least 1 reviewer (Technical Lead or Solution Architect)
- Pipeline must be green before merge

**Testing**

After every Bolt iteration, enforce quality gates:

| Gate | Threshold |
|------|-----------|
| Line coverage | ≥ 80% |
| Branch coverage | ≥ 75% |
| Linting | 0 errors |
| NetArchTest | All rules pass |
| Reqnroll BDD | All @smoke scenarios pass |
| Playwright E2E | All @smoke scenarios pass |

**Documentation**

- Update OpenAPI spec with every new endpoint
- Update swagger documentation (XML doc comments on handlers)
- Keep CHANGELOG.md updated per Bolt

**Compliance**

- Audit log entries written for every state-changing operation (submit, approve, reject, cancel)
- GDPR: PII fields encrypted in audit log output

**Performance**

- Query performance validated against NFR-001 (P95 < 300 ms) using k6 on each new endpoint
- Capacity queries use Redis cache (L1 + L2)
- Vacation history report: Dapper read model with covering index

**Observability**

- Each new command/query handler instrumented with OTel spans
- Custom metrics: requests submitted per day, approval rate, average approval time
- Dashboard updated after each Bolt with new feature metrics

#### Critical Business Rules (implementation checklist)

| Rule | Feature |
|------|---------|
| BR-001 – BR-006: Request validation (dates, balance, overlap) | F-001 |
| BR-015 – BR-019: Approval routing, rejection not final at PM level | F-002 |
| BR-020 – BR-030: Escalation at 48h, delegation | F-002 |
| Business day calculation (Mon–Fri, no weekends) | F-001 |
| 70% capacity threshold trigger | F-003 |
| 7-year audit log retention | F-007 |
| Admin-only access to threshold configuration | F-007 |

#### Deliverables

- F-001 complete (backend + frontend + tests)
- F-002 complete (backend + frontend + tests)
- F-003 complete (backend + frontend + tests)
- F-007 complete (backend + frontend + tests)
- Updated OpenAPI spec
- Quality gate reports per Bolt (coverage, linting, BDD, E2E)
- Updated Azure Monitor dashboards

#### Dependencies

- Phase 5 foundation complete
- Phase 3 designs approved (UX sign-off)
- OpenAPI contract finalized (Phase 2)

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Business day calculation edge cases | Medium | Medium | Test extensively with Spanish/local holidays |
| 2-level approval complex state machine | High | High | Model as explicit state machine; write exhaustive unit tests |
| Calendar performance with large datasets | Medium | High | Pre-aggregate capacity data; Redis caching mandatory |
| Escalation timing accuracy | Medium | Medium | Use Azure Container Apps CRON scaling or Service Bus scheduled messages |

#### Assumptions

- No blackout periods in Phase 1 (CL-003 resolved)
- Self-approval allowed for PM-who-is-DM (CL-005 resolved)
- No maximum consecutive vacation days (CL-002 resolved)

#### Exit Criteria

- [ ] All F-001, F-002, F-003, F-007 acceptance criteria passing (Reqnroll BDD)
- [ ] All Playwright E2E @smoke scenarios passing
- [ ] Code coverage ≥ 80% line, ≥ 75% branch across all new modules
- [ ] Zero critical SAST findings
- [ ] API performance P95 < 300 ms (validated by k6)
- [ ] Architecture conformance tests passing
- [ ] OpenAPI spec updated and published

#### Responsible Roles

Primary: Backend Developers · Frontend Developers · Technical Lead
Supporting: Solution Architect · QA Engineers · Data Architect

---

### Phase 7 — Integrations

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 9–13 (overlaps with Phase 6, 20 business days) |
| Complexity | High |
| Objective | Implement all external integrations: Microsoft Graph API (AD sync), ServiceNow Table API (vacation export), email notifications, and Microsoft Teams notifications |

#### Scope

F-004 (AD sync via Graph API), F-005 (ServiceNow export), F-006 (email + Teams notifications).
All integrations use .NET BackgroundService with retry logic, circuit breakers, and full OTel
instrumentation.

#### Activities

**Architecture**

- Design and implement Service Bus topic topology:
  - `vacation.submitted` → Notification handler
  - `vacation.approved` → Notification handler + ServiceNow export trigger
  - `vacation.rejected` → Notification handler
  - `vacation.cancelled` → ServiceNow removal trigger
- Validate retry and circuit-breaker pattern using Polly
- Implement outbox pattern for reliable event publishing (no event loss)

**Security**

- Microsoft Graph API: use Managed Identity (Client Credentials) — no secret keys
- ServiceNow API: credentials stored in Key Vault; accessed via Key Vault reference
- Email (SMTP/SendGrid): API key in Key Vault; no secrets in app settings
- Validate OAuth scopes: Graph: User.Read.All, Group.Read.All (minimum required)
- Implement service-to-service auth (Client Credentials flow) for background jobs

**DevOps**

- Add integration test pipeline stage using testcontainers + WireMock for Graph/ServiceNow mocks
- Configure separate pipeline trigger for integration modules
- Secret rotation process documented for ServiceNow credentials

**Testing**

- Mock Microsoft Graph API responses using WireMock.NET (Testcontainers-based)
- Mock ServiceNow Table API for integration tests
- Test retry logic with simulated API failures (3-attempt max, exponential backoff)
- Test AD sync edge cases: new hires, departures, transfers, manager changes
- Test ServiceNow delta sync: new records, cancellations, updates

**Documentation**

- Integration architecture document (sequence diagrams for each integration)
- ServiceNow field mapping specification
- AD → internal model mapping specification
- Operations runbook: how to re-run a failed sync

**Compliance**

- Validate soft-delete-only policy for employees (never hard-delete; BR-056)
- Audit all integration job executions (start time, end time, records processed, errors)
- GDPR: only minimum necessary employee data synchronized from AD

**Performance**

- AD sync: must complete within 30 minutes for 500 employees (NFR-003)
- ServiceNow export: must complete within 15 minutes for 50 records (NFR-004)
- Batch processing: chunk API calls (Graph API paging, 100 users per page)
- Background jobs do not impact API response times (separate thread pool)

**Observability**

- Instrument each background job with OTel spans (job start, records processed, errors)
- Custom metric: sync job duration, records synced, errors per run
- Alert: job failure or duration > 2× average

#### Integration Implementation Details

| Integration | Bolt | Schedule | Auth | Retry |
|-------------|------|----------|------|-------|
| AD Sync (F-004) | Bolt 4 | 2:00 AM nightly (cron) | Managed Identity (Client Credentials) | Max 3 attempts, exp. backoff |
| ServiceNow Export (F-005) | Bolt 5 | 4:00 AM nightly (cron) | API key from Key Vault | Max 3 attempts, exp. backoff |
| Email Notifications (F-006) | Bolt 6 | Event-driven (Service Bus) | SMTP/SendGrid key from Key Vault | Max 3 attempts |
| Teams Notifications (F-006) | Phase 2 | Event-driven | Webhook URL from Key Vault | Max 3 attempts |

#### Deliverables

- F-004 AD Sync service (Graph API integration, full test suite)
- F-005 ServiceNow export service (Table API integration, full test suite)
- F-006 Email notification service (Avanade-branded templates, Service Bus consumer)
- Service Bus topology (topics and subscriptions created via Terraform)
- Integration test suite with WireMock mocks
- Integration operations runbook

#### Dependencies

- Phase 5 foundation complete (BackgroundService infrastructure)
- Microsoft Graph API permissions granted (User.Read.All, Group.Read.All)
- ServiceNow sandbox environment and credentials
- Service Bus Terraform module deployed (Phase 4)
- Key Vault provisioned (Phase 4)

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Graph API permissions not granted in time | High | High | Raise access request in Week 1; use Mock Graph during dev |
| ServiceNow sandbox unavailable | Medium | High | Use WireMock for all integration tests; prod credentials for UAT only |
| Graph API paging complexity for 500 users | Medium | Medium | Implement cursor-based pagination from day 1 |
| Email delivery issues (spam filters) | Low | Medium | Use dedicated sending domain; SPF/DKIM configured |

#### Assumptions

- Microsoft Entra ID admin grants Graph API permissions before Bolt 4 starts
- ServiceNow Table API is accessible from Azure Container Apps (no firewall blocking)
- Email service configured with corporate domain (not personal addresses)

#### Exit Criteria

- [ ] AD sync runs successfully in dev: creates, updates, deactivates employees correctly
- [ ] ServiceNow export completes within 15 minutes for test batch of 50 records
- [ ] Email notifications delivered within 5 minutes of triggering event
- [ ] All integration tests passing with WireMock mocks
- [ ] Performance benchmarks met (NFR-003, NFR-004)
- [ ] Retry logic tested and verified (3-attempt max)
- [ ] Audit log entries for every integration job execution

#### Responsible Roles

Primary: Backend Developers · Solution Architect
Supporting: Technical Lead · Security Engineer · Platform Engineer · QA Engineers

---

### Phase 8 — Security & Compliance

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 13 (7 business days) |
| Complexity | High |
| Objective | Validate the complete security posture of the application: OWASP compliance, penetration testing, GDPR validation, IaC security review, and security sign-off |

#### Scope

SAST remediation, DAST execution, dependency vulnerability audit (SCA), GDPR compliance validation,
IaC final security review (Checkov/tfsec), penetration test, and production security configuration
review.

#### Activities

**Architecture**

- Architecture security review: validate no secrets in code, proper managed identity usage
- Review authentication flow end-to-end (Entra ID → JWT → policy checks)

**Security**

- Execute SAST scan on complete codebase (zero critical findings required)
- Execute DAST against staging environment (OWASP ZAP or equivalent)
- Run SCA (dependency audit): check for known CVEs in all NuGet and npm packages
- Execute penetration test focused on: auth bypass, injection, insecure direct object references
- OWASP Top 10 validation checklist:
  - A01: Broken Access Control → policy-based authz review
  - A02: Cryptographic Failures → TLS 1.2+, encryption at rest
  - A03: Injection → parameterized queries (Dapper), EF Core
  - A05: Security Misconfiguration → Checkov/tfsec IaC review
  - A07: Auth Failures → Entra ID integration review
  - A09: Logging/Monitoring Failures → OTel completeness review
- GDPR compliance audit:
  - Data classification review (PII identified and encrypted)
  - Right-to-erasure mechanism tested
  - Data retention policies active (7-year audit, GDPR minimization)
  - Consent flows reviewed (no unnecessary cookies)

**DevOps**

- Configure SAST as a blocking pipeline gate (Critical = build fail)
- Configure SCA scan on every PR (warn on High, fail on Critical)
- Ensure Key Vault references used in all production container app configurations
- Verify no secrets in Azure DevOps pipeline variables (use variable groups with Key Vault link)

**Testing**

- DAST automated test run in pipeline (OWASP ZAP)
- Security-specific integration tests: unauthorized access attempts, token expiry handling

**Documentation**

- Security assessment report
- GDPR compliance checklist (signed off)
- Penetration test report
- Remediation log (findings and fixes)

**Compliance**

- GDPR Data Processing Agreement validated
- 7-year audit retention policy active and tested (query audit log for old data)
- All PII fields classified and encrypted at rest

**Performance**

- Validate security controls do not introduce latency > 10 ms per request

**Observability**

- Security event logging: failed auth attempts, unusual API patterns
- Configure Azure Monitor alert for > 10 failed auth attempts in 5 minutes

#### OWASP Top 10 Validation Matrix

| OWASP ID | Risk | Control in this System | Status |
|----------|------|----------------------|--------|
| A01 | Broken Access Control | Policy-based authz, role-scoped queries | Verified |
| A02 | Cryptographic Failures | TLS 1.2+, SQL TDE, Key Vault | Verified |
| A03 | Injection | EF Core + Dapper parameterized, no raw SQL | Verified |
| A04 | Insecure Design | STRIDE threat model, constitution governance | Verified |
| A05 | Security Misconfiguration | Checkov/tfsec 0 criticals, no debug in prod | Verify |
| A06 | Vulnerable Components | SCA via OWASP Dependency-Check | Verify |
| A07 | Auth Failures | Entra ID, JWT validation, token refresh | Verified |
| A08 | Software Integrity | Signed pipeline artifacts, PR gates | Verified |
| A09 | Logging Failures | OTel full coverage, audit log immutable | Verify |
| A10 | SSRF | No user-controlled URLs; ServiceNow URL pinned | Verify |

#### Deliverables

- SAST report (zero critical findings)
- DAST report (OWASP ZAP)
- SCA dependency audit report
- Penetration test report
- OWASP Top 10 compliance sign-off
- GDPR compliance checklist (signed)
- Security sign-off document (Security Engineer signature)

#### Dependencies

- Phase 6 and Phase 7 substantially complete (application feature-complete for security testing)
- Staging environment available with production-like configuration

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Critical SAST findings require significant refactoring | Medium | High | Run SAST from Phase 5 onwards; address incrementally |
| Pen test uncovers architectural issue | Low | High | Address before go-live; may delay Phase 11 |
| GDPR gap discovered late | Low | High | GDPR review ongoing from Phase 1; formal audit here is validation |

#### Exit Criteria

- [ ] SAST: zero critical findings
- [ ] DAST: zero high-severity findings
- [ ] SCA: zero critical CVEs in dependencies
- [ ] Penetration test: all findings remediated or risk-accepted by PO
- [ ] GDPR compliance checklist complete and signed
- [ ] Security Engineer security sign-off document issued

#### Responsible Roles

Primary: Security Engineer
Supporting: Solution Architect · Technical Lead · Backend Developers · Platform Engineer

---

### Phase 9 — Testing & Quality Assurance

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 14 (10 business days) |
| Complexity | High |
| Objective | Execute the complete test suite across all layers (unit, integration, E2E, performance) and validate all quality thresholds before UAT entry |

#### Scope

Full regression test execution, performance load tests (k6), accessibility audit (Lighthouse CI),
visual regression (Playwright), API contract validation, and test completion report.

#### Activities

**Architecture**

- Final NetArchTest suite execution — all architecture conformance rules must pass
- API contract validation: actual API responses validated against OpenAPI spec

**Security**

- Final SAST scan on release candidate build
- E2E security scenario tests: token expiry, unauthorized access, session timeout

**DevOps**

- Configure pipeline to run full regression suite on release candidate branch
- Ensure k6 performance test runs in the pipeline against staging environment
- Configure Lighthouse CI in frontend pipeline

**Testing**

Unit Testing (xUnit):
- All command handlers (F-001 through F-007)
- Business day calculator (exhaustive: weekends, month boundaries)
- State machine transitions (request lifecycle)
- Capacity calculation (edge cases: 0%, 70%, 100%)
- Retry logic (max attempts, exponential backoff)

Integration Testing (xUnit + Testcontainers):
- API endpoint integration: every endpoint tested with real SQL Server container
- Service Bus publish/consume round-trip
- AD sync with WireMock Graph API mock
- ServiceNow export with WireMock mock

BDD (Reqnroll):
- All @smoke Gherkin scenarios from F-001 – F-007
- Approval workflow state transitions
- Escalation timer scenarios

E2E (Playwright):
- All @smoke user journeys (Employee, PM, DM)
- Cross-browser: Chrome, Edge, Firefox, Safari
- Accessibility: axe-core on every key screen
- Visual regression: baseline screenshots for all screens

Performance (k6):
- Load test: 560 concurrent users, 30-minute sustained load
- Validate P95 API response < 300 ms
- Stress test: 2× peak load (1,120 users)
- Background job performance: AD sync < 30 min, ServiceNow export < 15 min

**Documentation**

- Test execution report (all test types, pass/fail summary)
- Performance test report (k6 results, P95 measurements)
- Defect report (all defects, severity, resolution status)

**Compliance**

- Accessibility report: WCAG 2.1 AA compliance per screen
- Data integrity test: 7-year audit log retrieval validated

**Performance**

- k6 performance test execution against staging with production-equivalent data volume
- Report: P50, P95, P99 latency by endpoint

**Observability**

- Validate OTel traces covering 100% of API requests
- Validate alert rules trigger correctly (simulated error conditions)

#### Quality Gate Summary

| Layer | Tool | Threshold |
|-------|------|-----------|
| Unit tests | xUnit | 100% pass |
| Integration tests | xUnit + Testcontainers | 100% pass |
| BDD smoke | Reqnroll | 100% @smoke pass |
| E2E smoke | Playwright | 100% @smoke pass |
| Line coverage | Coverlet | ≥ 80% |
| Branch coverage | Coverlet | ≥ 75% |
| API latency (P95) | k6 | < 300 ms |
| Lighthouse performance | Lighthouse CI | ≥ 90 |
| Accessibility | axe-core + Lighthouse | WCAG 2.1 AA |
| Architecture conformance | NetArchTest | 100% |
| SAST | Pipeline scan | 0 Critical |

#### Deliverables

- Test execution report (all layers)
- Performance test report (k6)
- Accessibility compliance report
- Defect register (open/closed)
- Test completion report (QA sign-off)
- Release candidate build artifact

#### Dependencies

- Phase 6 and Phase 7 complete (all features)
- Phase 8 security issues resolved
- Staging environment with production-equivalent data
- Test data seed scripts ready

#### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Coverage gap discovered | Medium | High | Track coverage incrementally from Phase 5 |
| Performance test fails NFR-001 | Medium | High | Profile and optimize during Phase 6/7; k6 run per Bolt |
| Flaky E2E tests | High | Medium | Implement retry-on-failure; stabilize before UAT |
| Data volume insufficient for performance test | Low | Medium | Use test data generator seeding 500 employees |

#### Exit Criteria

- [ ] All quality gates in the table above met
- [ ] Zero P1 (critical) defects open
- [ ] Zero P2 (high) defects open (or risk-accepted by PO)
- [ ] Performance test report shows P95 < 300 ms for all endpoints
- [ ] Accessibility report shows WCAG 2.1 AA compliance
- [ ] QA sign-off document issued

#### Responsible Roles

Primary: QA Engineers
Supporting: Technical Lead · Backend Developers · Frontend Developers · DevOps Engineer

---

### Phase 10 — User Acceptance Testing

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 16 (7 business days) |
| Complexity | Medium |
| Objective | Validate the system against real user scenarios with actual business stakeholders, obtain formal UAT sign-off, and confirm the system is fit for purpose |

#### Scope

Structured UAT with representatives from all three user groups (employees, PMs, DMs), using
pre-defined test scripts derived from acceptance criteria, run against a UAT environment with
anonymized production-like data.

#### Participants

| Role | Count | Responsibilities |
|------|-------|-----------------|
| Employee testers | 5 | Test vacation submission, status tracking, calendar |
| Project Manager testers | 3 | Test approval queue, rejection, delegation |
| Department Manager testers | 2 | Test DM queue, capacity dashboard, reports |
| IT Administrator | 1 | Test admin panel, integration health screens |
| Business Analyst | 1 | Facilitate, document defects, resolve ambiguities |
| QA Engineer | 2 | Support testers, manage defect log |

#### Activities

**Architecture**

- Verify UAT environment is production-equivalent (same Terraform workspace config)

**Security**

- UAT uses anonymized data — no real employee PII in UAT environment

**DevOps**

- Deploy release candidate to UAT environment via approved pipeline stage
- UAT environment tear-down after sign-off

**Testing**

UAT test scripts cover:
- Employee: submit request, check balance, view team calendar, cancel request
- PM: receive notification, approve, reject with reason, delegate
- DM: final approval, override rejection, review capacity dashboard, generate report
- Admin: configure threshold, update email template, review audit log

**Documentation**

- UAT test plan
- UAT test scripts (per persona)
- UAT defect log
- UAT completion report

**Compliance**

- Validate audit log entries created during UAT sessions
- Validate GDPR consent and data handling during real user testing

**Performance**

- Observe system performance during UAT (Azure Monitor dashboard visible to team)

**Observability**

- Monitor Application Insights during UAT sessions for real user errors

#### Deliverables

- UAT test plan
- UAT test scripts (all personas)
- UAT defect log (all defects found during UAT)
- UAT completion report
- Formal UAT sign-off (PO + key stakeholder signatures)

#### Exit Criteria

- [ ] All UAT test scripts executed to completion
- [ ] Zero P1 defects open at sign-off
- [ ] P2 defects: remediated or scheduled for post-launch patch
- [ ] Formal UAT sign-off obtained from Product Owner and business stakeholders
- [ ] Go/no-go recommendation issued by PO

#### Responsible Roles

Primary: Product Owner · Business Analyst · QA Engineers
Supporting: Technical Lead · Frontend Developers · Backend Developers

---

### Phase 11 — Deployment & Go-Live

#### Overview

| Property | Value |
|----------|-------|
| Duration | Week 17 (3 business days) |
| Complexity | High |
| Objective | Execute the production deployment, validate the go-live, communicate to all users, and formally cut over from the email-based process |

#### Scope

Production Terraform apply (manual approval), backend Container App rolling deploy, frontend Static
Web Apps deploy, production smoke test, cutover communication, and old process decommission.

#### Go-Live Checklist

| Category | Check |
|----------|-------|
| Security | SAST 0 critical · TLS 1.2+ verified · Key Vault keys rotated · Managed identity verified |
| Infrastructure | Terraform apply succeeded · All health checks green · Auto-scaling configured |
| Application | Rolling deploy complete · Zero downtime · /health 200 OK |
| Testing | Smoke test suite passes in production · API P95 < 300 ms |
| Observability | Azure Monitor dashboards live · Alert rules active · On-call rotation set |
| Communication | User communication sent · Training materials published · Support email active |
| Rollback | Rollback procedure documented and tested · Previous Container App revision available |

#### Activities

**Architecture**

- Production architecture verification: all components connected as designed
- Verify managed identity access to Key Vault, Azure SQL, Service Bus in production

**Security**

- Rotate all production secrets (Key Vault) before go-live
- Final SAST scan on production artifact
- Security Engineer go-live sign-off confirmation

**DevOps**

- Trigger production pipeline (manual approval gate)
- Execute rolling deploy: zero-downtime strategy on Azure Container Apps
- Deploy frontend to Azure Static Web Apps production slot
- Apply production Terraform (Terraform workspace: prod)
- Configure production alert notifications (PagerDuty or Azure Monitor action group)

**Testing**

- Execute full @smoke test suite against production
- Validate all integration jobs with a manual trigger (AD sync, ServiceNow export)
- Monitor Azure Monitor dashboards for first 2 hours post-go-live

**Documentation**

- Go-live announcement email (to all 560 users)
- User guide / quick-start guide for each persona
- System administration guide
- Rollback procedure document

**Compliance**

- Confirm production audit log is active and collecting entries
- Confirm GDPR data processing is per approved DPA

**Performance**

- Execute k6 smoke performance test against production (light load only — not full stress)
- Monitor P95 latency in Azure Monitor for first hour

**Observability**

- Validate all OTel traces flowing to Azure Monitor in production
- Confirm Application Insights receiving RUM data from user browsers
- Validate all alert rules active and tested (send test alert)

#### Rollback Plan

| Trigger | Action |
|---------|--------|
| P95 > 1 second for > 5 minutes | Roll back to previous Container App revision |
| > 5% error rate | Roll back and investigate |
| Health endpoint fails | Immediate rollback |
| Security incident | Isolate service; invoke incident response |

#### Deliverables

- Production deployment confirmation
- Go-live smoke test report
- User communication (email to all 560 users)
- User guide (per persona)
- Go-live incident report (if any)
- Post-deployment monitoring report (first 24 hours)

#### Exit Criteria

- [ ] Production deployment successful (zero-downtime rolling deploy)
- [ ] All @smoke tests passing in production
- [ ] Azure Monitor dashboards showing healthy metrics
- [ ] User communication sent
- [ ] On-call rotation active
- [ ] No P1 incidents in first 4 hours

#### Responsible Roles

Primary: DevOps Engineer · Platform Engineer · Technical Lead
Supporting: Solution Architect · Security Engineer · QA Engineers · Product Owner

---

### Phase 12 — Hypercare

#### Overview

| Property | Value |
|----------|-------|
| Duration | Weeks 18–19 (14 business days post go-live) |
| Complexity | Medium |
| Objective | Provide intensive post-launch support, stabilize the system under real production load, rapidly resolve any critical issues, and transition to steady-state operations |

#### Scope

On-call support, accelerated incident response, hotfix pipeline, real user feedback collection,
performance monitoring, and operations handover to steady-state team.

#### SLA During Hypercare

| Severity | Definition | Response Time | Resolution Target |
|----------|------------|---------------|-------------------|
| P1 — Critical | System down / auth broken | 15 minutes | 2 hours |
| P2 — High | Major feature broken | 1 hour | 8 hours |
| P3 — Medium | Feature degraded | 4 hours | 2 business days |
| P4 — Low | Minor UI issue | Next business day | Next sprint |

#### Activities

**Architecture**

- Review production incidents for architectural root causes
- Identify any technical debt accumulated during construction

**Security**

- Monitor security alerts (failed auth spikes, unusual patterns)
- Respond to any security incidents per incident response plan

**DevOps**

- Hotfix pipeline: expedited review (1 reviewer) + automated gates + manual prod approval
- Daily deployment window if hotfixes required
- Monitor pipeline success rates

**Testing**

- Execute full regression suite before every hotfix deployment
- QA validation of each hotfix in staging before promotion

**Documentation**

- Daily hypercare status report to stakeholders
- Incident reports for any P1/P2 incidents
- Known issues log

**Compliance**

- Verify audit log operating correctly under real production data
- Confirm nightly AD sync and ServiceNow export running successfully

**Performance**

- Daily review of Azure Monitor performance dashboards
- Identify and address any performance regressions

**Observability**

- 24/7 Azure Monitor alert monitoring during hypercare
- Application Insights RUM review for user experience issues

#### Deliverables

- Daily hypercare status reports
- Incident reports (per P1/P2 incident)
- Hotfix releases (as needed)
- Performance baseline report (first 2 weeks production data)
- Operations handover document
- Hypercare exit report

#### Exit Criteria

- [ ] No P1 incidents in the last 5 business days
- [ ] No P2 incidents in the last 3 business days
- [ ] All @smoke tests consistently passing in production
- [ ] AD sync and ServiceNow export running successfully for 10+ consecutive nights
- [ ] Performance metrics stable (P95 < 300 ms)
- [ ] Operations handover document signed off
- [ ] Steady-state support team briefed and ready

#### Responsible Roles

Primary: Technical Lead · Backend Developers · DevOps Engineer · Platform Engineer
Supporting: QA Engineers · Solution Architect · Product Owner

---

### Phase 13 — Continuous Improvement

#### Overview

| Property | Value |
|----------|-------|
| Duration | Ongoing (30+ days, from Week 20) |
| Complexity | Low–Medium |
| Objective | Drive systematic improvement of the system based on real production data, user feedback, technical debt reduction, and evolving business requirements |

#### Scope

Performance optimization, user experience enhancements, technical debt reduction, Phase 2 feature
planning (Teams notifications, mobile, international holidays), and operational efficiency.

#### Activities

**Architecture**

- Quarterly architecture review: validate ADRs remain current
- Assess Phase 2 architectural requirements (Teams adaptive cards, multi-region, mobile)

**Security**

- Monthly dependency vulnerability scan
- Annual penetration test
- Key rotation schedule compliance

**DevOps**

- Pipeline optimization (reduce build time, improve test parallelism)
- Cost optimization via Azure Advisor recommendations and Infracost tracking
- Autoscaling fine-tuning based on real usage patterns

**Testing**

- Extend test coverage for edge cases discovered in production
- Expand performance test scenarios based on real usage patterns

**Documentation**

- Maintain living documentation (update ADRs, runbooks, user guides)
- Sprint retrospective action items

**Compliance**

- Periodic GDPR compliance review
- Annual audit log retrieval test (7-year retention validation)

**Performance**

- Monthly performance review against NFR baselines
- Query optimization based on Azure Monitor slow-query logs

**Observability**

- Monthly SLO review: availability ≥ 99.5%, job success ≥ 99%
- Evolve dashboards based on operational learnings

#### Phase 2 Roadmap Items

| Item | Priority | Estimated Complexity |
|------|----------|---------------------|
| Microsoft Teams notifications (adaptive cards) | High | Medium |
| Public holiday calendar by country | Medium | Low |
| Mobile-responsive improvements | Medium | Medium |
| Multi-language support (ES/EN) | Low | Medium |
| Advanced reporting (Power BI integration) | Low | High |

#### Deliverables

- Monthly performance and SLO report
- Sprint retrospective action items
- Phase 2 feature specifications (when prioritized)
- Updated documentation (living)
- Cost optimization report (quarterly)

#### Exit Criteria

Continuous — no exit; transitions to standard product management lifecycle.

#### Responsible Roles

Primary: Product Owner · Technical Lead
Supporting: All team members (on rotation)

---

## Deliverables Register

| # | Deliverable | Description | Responsible Role | Approval Authority | Project Phase |
|---|-------------|-------------|-----------------|-------------------|---------------|
| D-001 | Project Charter | Defines scope, objectives, team, budget, and governance | Product Owner | Sponsor / PO | Phase 0 |
| D-002 | Stakeholder Map & RACI | Identifies all stakeholders and responsibility assignments | Scrum Master | Product Owner | Phase 0 |
| D-003 | Ways of Working Document | Ceremonies, PR etiquette, Definition of Done, communication norms | Scrum Master | Team | Phase 0 |
| D-004 | Initial Risk Register | Top-10 project risks with mitigations | Scrum Master | Product Owner | Phase 0 |
| D-005 | Azure DevOps Project | Repositories, boards, pipelines (skeleton) | DevOps Engineer | Technical Lead | Phase 0 |
| D-006 | Business Requirements Document | Business goals, business rules, regulatory requirements | Business Analyst | Product Owner | Phase 1 |
| D-007 | Functional Requirements | User stories with acceptance criteria (F-001 – F-007) | Business Analyst | Product Owner | Phase 1 |
| D-008 | Non-Functional Requirements | NFR targets: latency, availability, scalability, compliance | Solution Architect | Product Owner | Phase 1 |
| D-009 | User Journey Maps | Journey maps for Employee, PM, DM, Administrator personas | UX/UI Designer | Product Owner | Phase 1 |
| D-010 | Persona Definitions | Detailed persona profiles for all 4 user types | Business Analyst | Product Owner | Phase 1 |
| D-011 | Requirements Traceability Matrix | Maps requirements to acceptance criteria and test cases | Business Analyst | Solution Architect | Phase 1 |
| D-012 | GDPR Data Flow Diagram | Data classification and flow for GDPR compliance | Security Engineer | Legal / PO | Phase 1 |
| D-013 | Solution Architecture Document | C4 diagrams (Context, Container, Component) | Solution Architect | Product Owner | Phase 2 |
| D-014 | Architecture Decision Records | ADRs for all significant technology decisions | Solution Architect | Tech Lead + Architect | Phase 2 |
| D-015 | Domain Model & Bounded Contexts | DDD bounded context map with aggregates | Solution Architect | Solution Architect | Phase 2 |
| D-016 | Entity Relationship Diagram | Physical and logical data model for Azure SQL | Data Architect | Solution Architect | Phase 2 |
| D-017 | OpenAPI 3.1 Specification | Contract-first API spec for all REST endpoints | Solution Architect | Technical Lead | Phase 2 |
| D-018 | STRIDE Threat Model | Threat analysis and mitigations for the full system | Security Engineer | Solution Architect | Phase 2 |
| D-019 | Authorization Matrix | Role → resource → operation mapping | Security Engineer | Product Owner | Phase 2 |
| D-020 | UI Wireframes | Static HTML wireframes for all key screens and states | UX/UI Designer | Product Owner | Phase 3 |
| D-021 | Design System | Tailwind CSS v4 token file and component catalogue | UX/UI Designer | Technical Lead | Phase 3 |
| D-022 | Accessibility Audit Report | WCAG 2.1 AA compliance report for all designed screens | UX/UI Designer | Product Owner | Phase 3 |
| D-023 | Terraform Modules | IaC for all 7 Azure resource types | Platform Engineer | Solution Architect | Phase 4 |
| D-024 | Azure DevOps Pipelines | Backend CI/CD, frontend CI/CD, IaC pipeline | DevOps Engineer | Technical Lead | Phase 4 |
| D-025 | Aspire AppHost Config | Local development service orchestration | Platform Engineer | Technical Lead | Phase 4 |
| D-026 | Azure Monitor Dashboards | Baseline dashboards and alert rules | Platform Engineer | Solution Architect | Phase 4 |
| D-027 | Checkov/tfsec Report | IaC security scan with zero critical findings | Platform Engineer | Security Engineer | Phase 4 |
| D-028 | Infrastructure Runbook | Provisioning, scaling, and DR procedures | Platform Engineer | Solution Architect | Phase 4 |
| D-029 | .NET 10 Solution Scaffold | Modular Monolith + CQRS + auth + OTel baseline | Technical Lead | Solution Architect | Phase 5 |
| D-030 | Vue 3 SPA Scaffold | Auth flow + routing + Pinia + design system integrated | Frontend Developer | Technical Lead | Phase 5 |
| D-031 | EF Core Initial Migration | Database schema v1 applied to dev environment | Data Architect | Technical Lead | Phase 5 |
| D-032 | NetArchTest Suite | Architecture conformance tests enforced on CI | Technical Lead | Solution Architect | Phase 5 |
| D-033 | Developer Onboarding Guide | Setup instructions for new team members | Technical Lead | Team | Phase 5 |
| D-034 | F-001 — Vacation Request | Complete feature: backend + frontend + tests | Backend Dev + Frontend Dev | QA Engineer | Phase 6 |
| D-035 | F-002 — Approval Workflow | Complete feature: backend + frontend + tests | Backend Dev + Frontend Dev | QA Engineer | Phase 6 |
| D-036 | F-003 — Calendar & Capacity | Complete feature: backend + frontend + tests | Backend Dev + Frontend Dev | QA Engineer | Phase 6 |
| D-037 | F-007 — Reporting & Admin | Complete feature: backend + frontend + tests | Backend Dev + Frontend Dev | QA Engineer | Phase 6 |
| D-038 | F-004 — AD Integration | AD sync service + integration tests | Backend Developer | QA Engineer | Phase 7 |
| D-039 | F-005 — ServiceNow Integration | ServiceNow export service + integration tests | Backend Developer | QA Engineer | Phase 7 |
| D-040 | F-006 — Notifications | Email notification service + templates + tests | Backend Developer | QA Engineer | Phase 7 |
| D-041 | Service Bus Topology | Topics, subscriptions, and Terraform configuration | Platform Engineer | Solution Architect | Phase 7 |
| D-042 | Integration Operations Runbook | How to monitor, re-run, and troubleshoot integrations | Backend Developer | Technical Lead | Phase 7 |
| D-043 | SAST Report | Static application security testing results | Security Engineer | Solution Architect | Phase 8 |
| D-044 | DAST Report | Dynamic application security testing results | Security Engineer | Solution Architect | Phase 8 |
| D-045 | SCA Dependency Audit | Software composition analysis report | Security Engineer | Technical Lead | Phase 8 |
| D-046 | Penetration Test Report | Pen test results and remediation evidence | Security Engineer | Product Owner | Phase 8 |
| D-047 | GDPR Compliance Checklist | Formal GDPR compliance validation | Security Engineer | Legal / PO | Phase 8 |
| D-048 | Security Sign-Off Document | Formal security approval for production release | Security Engineer | Product Owner | Phase 8 |
| D-049 | Test Strategy Document | Test approach, tools, thresholds, and responsibilities | QA Engineer | Solution Architect | Phase 9 |
| D-050 | Test Execution Report | Results across all test layers | QA Engineer | Technical Lead | Phase 9 |
| D-051 | k6 Performance Report | Load test results with P50, P95, P99 by endpoint | QA Engineer | Solution Architect | Phase 9 |
| D-052 | Defect Register | All defects with severity, status, resolution | QA Engineer | Product Owner | Phase 9 |
| D-053 | QA Sign-Off | Formal quality assurance approval for UAT entry | QA Engineer | Product Owner | Phase 9 |
| D-054 | UAT Test Plan | Structured test plan for user acceptance testing | Business Analyst | Product Owner | Phase 10 |
| D-055 | UAT Test Scripts | Per-persona test scripts based on acceptance criteria | Business Analyst | Product Owner | Phase 10 |
| D-056 | UAT Defect Log | All defects found during UAT | Business Analyst | Product Owner | Phase 10 |
| D-057 | UAT Completion Report | Summary of UAT results and sign-off recommendation | Business Analyst | Product Owner | Phase 10 |
| D-058 | Formal UAT Sign-Off | Signed approval by PO and business stakeholders | Product Owner | Sponsor | Phase 10 |
| D-059 | Go-Live Checklist | Pre-launch validation checklist (all categories) | DevOps Engineer | Technical Lead | Phase 11 |
| D-060 | Production Deployment | Successful production release (all components) | DevOps Engineer | Technical Lead | Phase 11 |
| D-061 | Go-Live Smoke Test Report | Test results on production environment | QA Engineer | Technical Lead | Phase 11 |
| D-062 | User Communication | Go-live announcement and user guide (per persona) | Business Analyst | Product Owner | Phase 11 |
| D-063 | Rollback Procedure | Documented and tested production rollback plan | DevOps Engineer | Technical Lead | Phase 11 |
| D-064 | Hypercare Status Reports | Daily reports during hypercare period | Scrum Master | Product Owner | Phase 12 |
| D-065 | Incident Reports | Per-incident P1/P2 root cause and resolution | Technical Lead | Product Owner | Phase 12 |
| D-066 | Operations Handover | Transition document to steady-state operations | Technical Lead | Product Owner | Phase 12 |
| D-067 | Monthly SLO Report | Availability, latency, job success metrics | Platform Engineer | Product Owner | Phase 13 |
| D-068 | Phase 2 Roadmap | Prioritized backlog for next release cycle | Product Owner | Sponsor | Phase 13 |

---

## Cross-Phase Mandatory Activities

The following mandatory activities apply to **every phase** of the project. Teams must not skip
any category regardless of phase complexity or timeline pressure.

### Architecture

| Activity | When | Owner |
|----------|------|-------|
| ADR review: validate all decisions comply with constitution | Start of each phase | Solution Architect |
| Architecture conformance check (NetArchTest) | Every merge to main | CI Pipeline |
| Module dependency review (no cross-module leakage) | Per Bolt iteration | Technical Lead |
| OpenAPI spec kept in sync with implementation | Per feature delivery | Backend Developer |

### Security

| Activity | When | Owner |
|----------|------|-------|
| SAST scan (blocking on Critical) | Every PR to main | CI Pipeline |
| SCA dependency audit (blocking on Critical CVE) | Every PR | CI Pipeline |
| Secret scan (no secrets in code) | Every commit | CI Pipeline (git-secrets) |
| Input validation on all API endpoints | Per feature delivery | Backend Developer |
| Authorization check on every protected endpoint | Per feature delivery | Backend Developer |
| Key Vault reference verification (no env var secrets) | Pre-every deployment | Security Engineer |

### DevOps

| Activity | When | Owner |
|----------|------|-------|
| Feature branch per Bolt (bolt/[feature]-[name]) | Per Bolt | Developer |
| PR with minimum 1 reviewer (Tech Lead or Architect) | Per PR | All Developers |
| Pipeline green before merge (no broken main) | Every merge | CI Pipeline |
| Release note / CHANGELOG entry per deployment | Per deployment | Technical Lead |
| Infracost report generated and reviewed | Per IaC PR | Platform Engineer |

### Testing

| Activity | When | Owner |
|----------|------|-------|
| Unit tests for all new code (TDD where possible) | Per feature | All Developers |
| Integration tests for every new API endpoint | Per feature | Backend Developer |
| @smoke E2E tests pass before every deployment | Pre-deployment | QA Engineer |
| Code coverage gate enforced (≥ 80% line) | Every build | CI Pipeline |
| Defect root cause analysis for every P1/P2 bug | Per incident | QA Engineer + Dev |

### Documentation

| Activity | When | Owner |
|----------|------|-------|
| CHANGELOG.md updated per sprint | Per sprint | Technical Lead |
| API documentation (Swagger/OpenAPI) updated | Per endpoint | Backend Developer |
| Architecture decisions recorded as ADRs | Per decision | Solution Architect |
| Runbooks updated for new operations procedures | Per operational change | Platform Engineer |
| README kept current | Per phase | Technical Lead |

### Compliance

| Activity | When | Owner |
|----------|------|-------|
| GDPR impact assessment for new data features | Per new PII field | Security Engineer |
| Audit log entries validated for new operations | Per state-changing operation | Backend Developer |
| 7-year retention policy checked on schema changes | Per migration | Data Architect |
| Right-to-erasure mechanism tested on new PII | Per UAT cycle | QA Engineer |

### Performance

| Activity | When | Owner |
|----------|------|-------|
| k6 smoke test on new endpoints | Per Bolt delivery | QA Engineer |
| Query execution plan review for new Dapper queries | Per feature | Data Architect |
| Cache hit rate monitored (L1 + Redis) | Weekly in production | Platform Engineer |
| Azure Monitor P95 latency review | Weekly | Platform Engineer |

### Observability

| Activity | When | Owner |
|----------|------|-------|
| OTel instrumentation added to all new handlers | Per feature | Backend Developer |
| Azure Monitor dashboard updated for new features | Per feature | Platform Engineer |
| Alert rules reviewed and tested | Per deployment | Platform Engineer |
| SLO review (availability ≥ 99.5%, job success ≥ 99%) | Monthly | Platform Engineer |
| Application Insights RUM review | Weekly | Frontend Developer |

---

*Bolt Framework v2.0.0 — VAC-MGT-2026 — Implementation Plan v1.0 — 2026-08-07*
