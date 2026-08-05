<!-- ================================================================ -->
<!-- SCOPE: frontend -->
<!-- Generated: 2026-08-05 13:15:47 -->
<!-- Source: .boltf/scopes/frontend/memory/constitution.md -->
<!-- ================================================================ -->

# BOLT Framework Project Constitution — Scope: Frontend

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `frontend` — Frontend framework, architecture, mobile, authentication flows, E2E testing, and code standards.
> Articles marked with 🔄 are **common to all scopes** and always present.
> Sections marked with 🆕 are **proposed additions** not present in the original constitution.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article II: Application Configuration

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 2.2: Frontend Framework 🔴 CRITICAL

> **🔴 CRITICAL**: Frontend framework choice (React vs Angular vs Vue) = complete rewrite if changed

Select ONE:

- [ ] **Vue.js** - Version: [ ] 3.x
- [ ] **React** - Version: [ ] 18.x [ ] 19.x
- [ ] **Angular** - Version: [ ] 17.x [ ] 18.x [ ] 19.x [ ] 20.x 🟡 IMPORTANT
- [ ] **Blazor** - Type: [ ] Server [ ] WebAssembly [ ] Hybrid
- [ ] **None** - API only (headless)

### Section 2.3: Mobile Application 🔴 CRITICAL

> **🔴 CRITICAL**: Mobile platform choice (.NET MAUI vs React Native vs Flutter) = different codebase

Select ONE:

- [ ] **None** - No mobile app
- [ ] **.NET MAUI** - Cross-platform native
- [ ] **React Native** - Cross-platform with React
- [ ] **Flutter** - Cross-platform with Dart
- [ ] **Blazor Hybrid** - .NET MAUI + Blazor

### Section 2.4: Design Tooling 🆕 🟡 IMPORTANT

> **📋 Applies to**: Frontend scope ONLY
> **⏭️ Skip if**: No frontend scope
> **🔗 Provisions**: `bolt-penpot` agent + skill, Penpot MCP server (dual-client), and
> the design-token export pipeline (Penpot → Tailwind v4). Usage guide:
> `docs/integrations/penpot-usage-guide.md` · Plan: `docs/integrations/penpot-integration-plan.md`.

Select ONE visual design tool integration:

- [ ] **Penpot — self-hosted (local, Podman)** — Default. Run a local Penpot stack via
  `.boltf/scripts/powershell/Install-Penpot.ps1` / `.boltf/scripts/bash/install-penpot.sh`
  (Podman by default). MCP wired
  to the local instance; design tokens exported to `tokens.css`.
- [ ] **Penpot — remote/existing instance** — Connect to an existing/corporate Penpot
  (`https://<domain>`). Provide instance URL + MCP key; no local install.
- [ ] **None** — HTML mockups only (`bolt-mockup` / `bolt-ux-design`). No design tool, no
  Penpot MCP, no token pipeline.

> **Decision source**: prefilled from the wizard (`decisions.frontend.design-tool` in
> `.boltf/scopes.yaml`). Confirm or change here during constitution refinement.

#### Design Gate (DISCOVERY → PLAN)

> **Applies only when** `design-tool ∈ { penpot-local, penpot-remote }`.

Before `bolt-plan` produces the technical plan for a UI feature, an **approved Penpot
design** must exist that covers the required UI states (`default`, `empty`, `loading`,
`error`, `success` per the `bolt-ui-mockups` matrix). The `bolt-penpot` agent in
`validate` mode writes the evidence to `specs/[XXX-feature-name]/design/penpot-validate.md`.

- ✅ Gate passes → `bolt-plan` proceeds.
- ⛔ No approved design / missing states → `bolt-plan` warns and routes back to
  `bolt-penpot` (or `bolt-mockup` for low-fi) before planning.
- When `design-tool = none`, this gate is inactive (HTML mockups remain the artifact).

---

## Article III: Application Architecture

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 3.2: Frontend Architecture Style 🔴 CRITICAL

> **🔴 CRITICAL**: Micro-frontends vs SPA affects entire frontend structure and team organization

Select ONE:

- [ ] **Micro-frontends** - Module Federation, independent teams
- [ ] **Monolith SPA** - Single SPA application
- [ ] **Server-rendered (SSR/MPA)** - Server-side rendering
- [ ] **Static Site (SSG)** - Pre-built static pages
- [ ] **None** - API only

---

## Article VII: Identity & Access Management (Frontend)

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 7.3: Authentication Flows 🟡 IMPORTANT

| Scenario     | Flow                      | Enabled        |
| ------------ | ------------------------- | -------------- |
| SPA Frontend | Authorization Code + PKCE | [ ] Yes [ ] No |
| Mobile App   | Authorization Code + PKCE | [ ] Yes [ ] No |

### Section 7.4: Authorization Model 🟡 IMPORTANT

Select ONE:

- [ ] **RBAC** - Role-Based Access Control
- [ ] **Claims-Based** - Claims in JWT
- [ ] **Policy-Based** - .NET Authorization Policies / Node.js CASL
- [ ] **ABAC** - Attribute-Based Access Control

---

## Article X: Environments & Configuration 🔄 🟡 IMPORTANT

> **📋 Applies to**: ALL project types

### Section 10.1: Environment Strategy

| Environment | Purpose                      | Enabled | Auto-Deploy              |
| ----------- | ---------------------------- | ------- | ------------------------ |
| **dev**     | Development, rapid iteration | [ ] Yes | [ ] On commit to develop |
| **uat**     | User Acceptance Testing      | [ ] Yes | [ ] On PR merge          |
| **pre**     | Pre-production, staging      | [ ] Yes | [ ] Manual trigger       |
| **prod**    | Production                   | [ ] Yes | [ ] Manual approval      |

### Section 10.2: Configuration Management 🟡 IMPORTANT

Select strategy:

- [ ] **Azure App Configuration** - Centralized, feature flags (recommended)
- [ ] **Environment Variables** - Container/App Service config
- [ ] **appsettings.{Environment}.json** (.NET) / **.env files** (Node.js)
- [ ] **Combination** - App Config + Key Vault (recommended)

### Section 10.3: Secrets Management 🟡 IMPORTANT

| Secret Type        | Storage         |
| ------------------ | --------------- |
| Connection Strings | Azure Key Vault |
| API Keys           | Azure Key Vault |
| Certificates       | Azure Key Vault |

Local Development Secrets:

- [ ] **User Secrets** (.NET) - `dotnet user-secrets`
- [ ] **.env files** (Node.js) - gitignored
- [ ] **Local Key Vault** - Azure Key Vault dev instance

### Section 10.4: Feature Flags 🟢 LOW-PRIO

Feature Flag Provider:

- [ ] **None**
- [ ] **Azure App Configuration** - Native integration
- [ ] **LaunchDarkly** - Enterprise features
- [ ] **Unleash** - Open-source

---

## Article XI: CI/CD Pipeline 🔄 🟡 IMPORTANT

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

### Section 11.3: Deployment Strategy 🟡 IMPORTANT

Select ONE:

- [ ] **Rolling Update** - Gradual replacement
- [ ] **Blue-Green** - Azure Deployment Slots / K8s
- [ ] **Canary** - Gradual traffic shift
- [ ] **Feature Flags** - Deploy dark, enable via flags

### Section 11.4: Branch Strategy 🟡 IMPORTANT

Select ONE:

- [ ] **GitFlow** - feature/, develop, release/, main
- [ ] **GitHub Flow** - feature/, main
- [ ] **Trunk-Based** - Short-lived branches, main

---

## Article XII: Observability 🔄 🟡 IMPORTANT

> **📋 Applies to**: ALL project types

### Section 12.1: Observability Strategy 🟡 IMPORTANT

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

## Article XIII: Testing Standards (Frontend)

> **📋 Applies to**: Application Development, Full Stack

### Section 13.1: Testing Philosophy

> **Coverage-First approach validated by Mutation Testing**

| Metric          | Minimum | Recommended | Tool               |
| --------------- | ------- | ----------- | ------------------ |
| Line Coverage   | >= 80%  | >= 90%      | istanbul (Node.js) |
| Branch Coverage | >= 75%  | >= 85%      | istanbul (Node.js) |
| Mutation Score  | >= 70%  | >= 80%      | Stryker Mutator    |

### Section 13.2: Testing Frameworks (Frontend)

| Type              | Framework                           |
| ----------------- | ----------------------------------- |
| Unit Tests        | Jest / Vitest                       |
| Component Tests   | Testing Library (React/Vue/Angular) |
| E2E Tests         | Playwright / Cypress                |
| Visual Regression | Playwright / Chromatic              |
| Performance Tests | Lighthouse CI / Web Vitals          |

---

## Article XIV: Code Standards

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 14.1: Naming Conventions

#### For Node.js/TypeScript (Frontend)

| Element    | Convention       | Example            |
| ---------- | ---------------- | ------------------ |
| Files      | kebab-case       | `order-service.ts` |
| Components | PascalCase       | `OrderDetail.tsx`  |
| Interfaces | I + PascalCase   | `IOrderService`    |
| Functions  | camelCase        | `getOrderById`     |
| Variables  | camelCase        | `orderId`          |
| Constants  | UPPER_SNAKE_CASE | `MAX_RETRIES`      |

### Section 14.2: Code Formatting

| Setting     | Value                 |
| ----------- | --------------------- |
| Indentation | 2 spaces              |
| Line Length | 100 characters        |
| Semicolons  | [ ] Yes [ ] No        |
| Quotes      | [ ] Single [ ] Double |
| Tooling     | ESLint + Prettier     |

---

## Article XVI: Security Policies 🔄

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

## Proposed Additions — Frontend Gaps 🆕

> The original constitution does not cover the following frontend-specific concerns.
> These are recommended Microsoft/Azure alternatives based on current best practices.

- **Accessibility (WCAG 2.2)**: Enforce via axe-core + Playwright accessibility audits; Azure Static Web Apps supports custom headers for a11y compliance.
- **Performance Budgets**: Use Lighthouse CI in pipelines; monitor Core Web Vitals via Azure Application Insights Real User Monitoring (RUM).
- **Design System / Component Library**: Consider Fluent UI 2 (React) or Fluent UI Blazor for consistent Microsoft design language.
- **Static Hosting**: Azure Static Web Apps for SPA/SSG; Azure CDN or Azure Front Door for global distribution.
- **Client-Side Error Tracking**: Azure Application Insights JavaScript SDK for automatic exception and dependency tracking.
- **PWA Support**: Service worker caching strategy; Azure CDN for offline-first asset delivery.

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


---

**Scope Constitution for frontend** | Generated by Bolt Framework Init.ps1 on 2026-08-05 13:15:47
