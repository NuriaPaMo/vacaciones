# Decision Criticality Matrix

> **Generated**: 2026-02-28
> **Purpose**: Classify constitution decisions by impact level to prioritize Phase 2 questions
> **Scopes Analyzed**: backend, frontend, cloud-platform

---

## Criticality Levels

### 🔴 CRITICAL (Must Decide Now)

**Impact**: Architectural foundation - extremely difficult/expensive to change later
**When to Ask**: Phase 2A - First Priority
**User Can Skip**: ❌ No - Required decisions

### 🟡 IMPORTANT (Should Decide Soon)

**Impact**: Quality/Security/Process - changeable with moderate effort
**When to Ask**: Phase 2B - Second Priority
**User Can Skip**: ⚠️ With warning - Defaults will be applied

### 🟢 CONFIGURABLE (Can Decide Later)

**Impact**: Fine-tuning values - easily changeable via config
**When to Ask**: Phase 2C - Third Priority (Optional)
**User Can Skip**: ✅ Yes - Safe to use defaults

---

## Backend Scope Decisions

### Article II: Application Configuration

| Decision                                   | Article | Section | Criticality     | Rationale                                      |
| ------------------------------------------ | ------- | ------- | --------------- | ---------------------------------------------- |
| **Backend Language & Runtime**             | II      | 2.1     | 🔴 CRITICAL     | Changing from C# to Node.js = complete rewrite |
| .NET Version (8 LTS vs 10)                 | II      | 2.1     | 🟡 IMPORTANT    | Upgradable but affects support lifecycle       |
| API Style (Minimal APIs vs Controllers)    | II      | 2.1     | 🟡 IMPORTANT    | Refactorizable but affects project structure   |
| Node.js Version (20 LTS vs 22)             | II      | 2.1     | 🟢 CONFIGURABLE | Easy upgrade path                              |
| Node.js Framework (Express/Fastify/NestJS) | II      | 2.1     | 🟡 IMPORTANT    | Refactorizable but affects patterns            |

### Article III: Application Architecture

| Decision                              | Article | Section | Criticality  | Rationale                                          |
| ------------------------------------- | ------- | ------- | ------------ | -------------------------------------------------- |
| **Backend Architecture Style**        | III     | 3.1     | 🔴 CRITICAL  | Microservices vs Monolith affects entire structure |
| **CQRS Enabled**                      | III     | 3.3     | 🟡 IMPORTANT | Affects patterns but can add/remove later          |
| CQRS Pattern (Full/Simple/+ES)        | III     | 3.3     | 🟡 IMPORTANT | Conditional on CQRS Enabled                        |
| **Event Sourcing Enabled**            | III     | 3.4     | 🔴 CRITICAL  | Once committed, very hard to migrate away          |
| Event Store (EventStoreDB/Cosmos/SQL) | III     | 3.4     | 🟡 IMPORTANT | Conditional on Event Sourcing                      |

### Article IV: Communication

| Decision                | Article | Section | Criticality  | Rationale                                                  |
| ----------------------- | ------- | ------- | ------------ | ---------------------------------------------------------- |
| **Communication Style** | IV      | 4.1     | 🔴 CRITICAL  | Sync vs Async vs Hybrid defines integration approach       |
| REST API Enabled        | IV      | 4.2     | 🟡 IMPORTANT | Standard, but affects contracts                            |
| gRPC Enabled            | IV      | 4.2     | 🟡 IMPORTANT | Performance-critical, harder to change                     |
| GraphQL Option          | IV      | 4.2     | 🟡 IMPORTANT | Affects API design fundamentally                           |
| **Message Broker**      | IV      | 4.3     | 🔴 CRITICAL  | Service Bus vs RabbitMQ vs Event Hubs = different patterns |
| Background Processing   | IV      | 4.3     | 🟡 IMPORTANT | Hangfire vs Azure Functions affects deployment             |

### Article V: Data Storage

| Decision                          | Article | Section | Criticality     | Rationale                                     |
| --------------------------------- | ------- | ------- | --------------- | --------------------------------------------- |
| **Primary Database**              | V       | 5.1     | 🔴 CRITICAL     | SQL vs NoSQL migration is extremely expensive |
| **Data Access Pattern** (.NET)    | V       | 5.2     | 🟡 IMPORTANT    | EF Core vs Dapper affects project structure   |
| **Data Access Pattern** (Node.js) | V       | 5.2     | 🟡 IMPORTANT    | Prisma vs TypeORM affects models              |
| Repository Pattern                | V       | 5.2     | 🟡 IMPORTANT    | Affects testability and layering              |
| Unit of Work Pattern              | V       | 5.2     | 🟡 IMPORTANT    | Related to Repository Pattern                 |
| Migrations Tool                   | V       | 5.3     | 🟢 CONFIGURABLE | Easy to switch migration tools                |

### Article VI: Caching Strategy

| Decision                 | Article | Section | Criticality     | Rationale                                   |
| ------------------------ | ------- | ------- | --------------- | ------------------------------------------- |
| L1 In-Memory Enabled     | VI      | 6.1     | 🟡 IMPORTANT    | Affects performance architecture            |
| **L1 TTL Default**       | VI      | 6.1     | 🟢 CONFIGURABLE | Runtime configuration value                 |
| **L2 Distributed Cache** | VI      | 6.2     | 🟡 IMPORTANT    | Redis vs None affects scalability           |
| **L2 TTL Default**       | VI      | 6.2     | 🟢 CONFIGURABLE | Runtime configuration value                 |
| L3 CDN                   | VI      | 6.3     | 🟡 IMPORTANT    | Azure CDN vs Front Door affects global perf |
| **L3 TTL Default**       | VI      | 6.3     | 🟢 CONFIGURABLE | Runtime configuration value                 |
| Cache Patterns           | VI      | 6.4     | 🟢 CONFIGURABLE | Can mix patterns, easy to change            |

### Article VII: Identity & Access Management

| Decision                     | Article | Section | Criticality     | Rationale                                         |
| ---------------------------- | ------- | ------- | --------------- | ------------------------------------------------- |
| **Identity Provider (Prod)** | VII     | 7.1     | 🔴 CRITICAL     | Entra ID vs Auth0 vs Keycloak = entire auth stack |
| Identity Provider (Dev/Test) | VII     | 7.2     | 🟢 CONFIGURABLE | Dev-only, easy to mock                            |
| **Authentication Flows**     | VII     | 7.3     | 🟡 IMPORTANT    | PKCE vs Client Credentials affects security       |
| **Authorization Model**      | VII     | 7.4     | 🟡 IMPORTANT    | RBAC vs ABAC affects entire permission model      |

### Article XIII: Testing Standards

| Decision                    | Article | Section | Criticality     | Rationale                                |
| --------------------------- | ------- | ------- | --------------- | ---------------------------------------- |
| **Line Coverage Minimum**   | XIII    | 13.1    | 🟢 CONFIGURABLE | CI/CD threshold, easily adjustable       |
| **Branch Coverage Minimum** | XIII    | 13.1    | 🟢 CONFIGURABLE | CI/CD threshold, easily adjustable       |
| **Mutation Score Minimum**  | XIII    | 13.1    | 🟢 CONFIGURABLE | CI/CD threshold, easily adjustable       |
| Unit Test Framework         | XIII    | 13.2    | 🟡 IMPORTANT    | xUnit vs NUnit affects project setup     |
| Integration Test Framework  | XIII    | 13.2    | 🟡 IMPORTANT    | Testcontainers affects test infra        |
| E2E Test Framework          | XIII    | 13.2    | 🟡 IMPORTANT    | Playwright vs Cypress affects test suite |

### Article XIV: Code Standards

| Decision                      | Article | Section | Criticality     | Rationale                                |
| ----------------------------- | ------- | ------- | --------------- | ---------------------------------------- |
| Naming Conventions            | XIV     | 14.1    | 🟢 CONFIGURABLE | Enforced by linter, easy to change       |
| File-scoped namespaces (.NET) | XIV     | 14.2    | 🟢 CONFIGURABLE | Code style preference                    |
| Nullable reference types      | XIV     | 14.2    | 🟡 IMPORTANT    | Affects code safety, harder to add later |
| Indentation (spaces)          | XIV     | 14.2    | 🟢 CONFIGURABLE | Formatter setting                        |
| **Line Length**               | XIV     | 14.2    | 🟢 CONFIGURABLE | Linter setting                           |

---

## Frontend Scope Decisions

### Article II: Application Configuration (Frontend)

| Decision               | Article | Section | Criticality  | Rationale                                  |
| ---------------------- | ------- | ------- | ------------ | ------------------------------------------ |
| **Frontend Framework** | II      | 2.2     | 🔴 CRITICAL  | React vs Angular vs Vue = complete rewrite |
| Framework Version      | II      | 2.2     | 🟡 IMPORTANT | Angular 17 vs 19 affects upgrade path      |
| Mobile Application     | II      | 2.3     | 🔴 CRITICAL  | MAUI vs React Native = different codebase  |

### Article III: Application Architecture (Frontend)

| Decision                        | Article | Section | Criticality | Rationale                                       |
| ------------------------------- | ------- | ------- | ----------- | ----------------------------------------------- |
| **Frontend Architecture Style** | III     | 3.2     | 🔴 CRITICAL | Micro-frontends vs SPA affects entire structure |

### Article VII: Identity (Frontend)

| Decision                | Article | Section | Criticality  | Rationale                  |
| ----------------------- | ------- | ------- | ------------ | -------------------------- |
| SPA Authentication Flow | VII     | 7.3     | 🟡 IMPORTANT | PKCE flow affects security |
| Mobile Auth Flow        | VII     | 7.3     | 🟡 IMPORTANT | Conditional on mobile app  |
| Authorization Model     | VII     | 7.4     | 🟡 IMPORTANT | Should match backend model |

### Article X: Environments & Configuration

| Decision                     | Article | Section | Criticality     | Rationale                              |
| ---------------------------- | ------- | ------- | --------------- | -------------------------------------- |
| **Environment Strategy**     | X       | 10.1    | 🟡 IMPORTANT    | Dev/UAT/Pre/Prod affects pipeline      |
| Environment Auto-Deploy      | X       | 10.1    | 🟢 CONFIGURABLE | Pipeline trigger, easy to change       |
| **Configuration Management** | X       | 10.2    | 🟡 IMPORTANT    | App Config vs Env Vars affects runtime |
| Secrets Management           | X       | 10.3    | 🟡 IMPORTANT    | Key Vault is standard, safe default    |
| Feature Flags Provider       | X       | 10.4    | 🟢 CONFIGURABLE | App Config vs LaunchDarkly, integrable |

### Article XI: CI/CD Pipeline

| Decision                | Article | Section | Criticality     | Rationale                                       |
| ----------------------- | ------- | ------- | --------------- | ----------------------------------------------- |
| **CI/CD Platform**      | XI      | 11.1    | 🟡 IMPORTANT    | GitHub Actions vs Azure DevOps affects workflow |
| Pipeline Stages Enabled | XI      | 11.2    | 🟡 IMPORTANT    | Security Scan, Mutation Tests affect quality    |
| **Coverage Threshold**  | XI      | 11.2    | 🟢 CONFIGURABLE | Pipeline gate value                             |
| **Mutation Threshold**  | XI      | 11.2    | 🟢 CONFIGURABLE | Pipeline gate value                             |
| Deployment Strategy     | XI      | 11.3    | 🟡 IMPORTANT    | Blue-Green vs Canary affects deployment         |
| **Branch Strategy**     | XI      | 11.4    | 🟡 IMPORTANT    | GitFlow vs Trunk-Based affects team workflow    |

### Article XII: Observability

| Decision                   | Article | Section | Criticality  | Rationale                                     |
| -------------------------- | ------- | ------- | ------------ | --------------------------------------------- |
| **Observability Strategy** | XII     | 12.1    | 🟡 IMPORTANT | Azure Monitor vs OTel affects telemetry stack |

---

## Cloud-Platform Scope Decisions

### Article VIII: Containers & Orchestration

| Decision                   | Article | Section | Criticality     | Rationale                                               |
| -------------------------- | ------- | ------- | --------------- | ------------------------------------------------------- |
| **Container Strategy**     | VIII    | 8.1     | 🔴 CRITICAL     | Docker vs None (PaaS) affects deployment                |
| **Orchestration Platform** | VIII    | 8.2     | 🔴 CRITICAL     | AKS vs Container Apps vs App Service = infra foundation |
| K8s Package Manager        | VIII    | 8.3     | 🟡 IMPORTANT    | Helm vs Kustomize affects deployment                    |
| Ingress Controller         | VIII    | 8.3     | 🟡 IMPORTANT    | NGINX vs AGIC affects networking                        |
| KEDA Enabled               | VIII    | 8.4     | 🟡 IMPORTANT    | Event-driven autoscaling affects scalability            |
| KEDA Scalers               | VIII    | 8.4     | 🟢 CONFIGURABLE | Conditional on KEDA enabled                             |
| Dapr Enabled               | VIII    | 8.4     | 🟡 IMPORTANT    | Service mesh affects architecture                       |
| Dapr Building Blocks       | VIII    | 8.4     | 🟢 CONFIGURABLE | Conditional on Dapr enabled                             |

### Article VIII-B: Infrastructure Scope

| Decision                 | Article | Section | Criticality     | Rationale                                            |
| ------------------------ | ------- | ------- | --------------- | ---------------------------------------------------- |
| **Infrastructure Scope** | VIII-B  | 8B.1    | 🔴 CRITICAL     | Landing Zone vs Workload defines entire IaC approach |
| Landing Zone Components  | VIII-B  | 8B.2    | 🟡 IMPORTANT    | Conditional on Infrastructure Scope                  |
| Landing Zone Pattern     | VIII-B  | 8B.2    | 🟡 IMPORTANT    | ALZ vs CAF vs Custom affects governance              |
| Networking Model         | VIII-B  | 8B.2    | 🟡 IMPORTANT    | Hub-Spoke vs Mesh affects connectivity               |
| Workload Components      | VIII-B  | 8B.3    | 🟡 IMPORTANT    | Which Azure resources to provision                   |
| Deployment Strategy      | VIII-B  | 8B.4    | 🟢 CONFIGURABLE | Repo structure, organizational choice                |

### Article VIII-C: .NET Aspire

| Decision            | Article | Section | Criticality  | Rationale                                     |
| ------------------- | ------- | ------- | ------------ | --------------------------------------------- |
| **Aspire Adoption** | VIII-C  | 8C.1    | 🟡 IMPORTANT | Affects local dev experience, removable later |

---

## Summary Statistics

### By Criticality Level

| Level           | Count  | Percentage | Description                                 |
| --------------- | ------ | ---------- | ------------------------------------------- |
| 🔴 CRITICAL     | **17** | 26%        | Must decide - extremely difficult to change |
| 🟡 IMPORTANT    | **35** | 54%        | Should decide - moderate effort to change   |
| 🟢 CONFIGURABLE | **13** | 20%        | Can defer - easy runtime/config changes     |
| **TOTAL**       | **65** | 100%       | Total decision points across 3 scopes       |

### By Scope

| Scope              | 🔴 Critical | 🟡 Important | 🟢 Configurable | Total  |
| ------------------ | ----------- | ------------ | --------------- | ------ |
| **backend**        | 8           | 21           | 9               | 38     |
| **frontend**       | 3           | 10           | 3               | 16     |
| **cloud-platform** | 6           | 4            | 1               | 11     |
| **TOTAL**          | **17**      | **35**       | **13**          | **65** |

### Critical Decisions Breakdown

**Backend Critical (8)**:

1. Backend Language & Runtime (C# vs Node.js)
2. Backend Architecture Style (Microservices vs Monolith)
3. Event Sourcing Enabled (Yes/No)
4. Communication Style (Sync/Async/Hybrid)
5. Message Broker (Service Bus vs RabbitMQ vs Event Hubs)
6. Primary Database (SQL vs NoSQL)
7. Identity Provider (Entra ID vs Auth0 vs Keycloak)

**Frontend Critical (3)**:

1. Frontend Framework (React vs Angular vs Vue)
2. Mobile Application (MAUI vs React Native vs Flutter vs None)
3. Frontend Architecture Style (Micro-frontends vs SPA)

**Cloud-Platform Critical (6)**:

1. Container Strategy (Docker vs None/PaaS)
2. Orchestration Platform (AKS vs Container Apps vs App Service)
3. Infrastructure Scope (Landing Zone vs Workload vs Both)

---

## Phase 2 Workflow Recommendation

### Phase 2A: Critical Decisions (Must Ask - ~17 questions)

**Cannot skip** - These define architectural foundation

1. Backend Language & Runtime
2. Backend Architecture Style
3. Frontend Framework
4. Frontend Architecture Style
5. Primary Database
6. Communication Style
7. Message Broker (if async)
8. Event Sourcing Enabled
9. Identity Provider (Production)
10. Container Strategy
11. Orchestration Platform
12. Infrastructure Scope
13. Mobile Application
14. [etc - all 🔴 CRITICAL]

### Phase 2B: Important Decisions (Should Ask - ~35 questions)

**Can skip with warning** - Defaults will be applied

- CQRS Enabled
- Data Access Pattern
- Authorization Model
- CI/CD Platform
- Testing Frameworks
- Observability Strategy
- [etc - all 🟡 IMPORTANT]

### Phase 2C: Configurable Values (Optional - ~13 questions)

**Safe to skip** - Easy to change later via config

- Cache TTL values
- Coverage thresholds
- Code formatting rules
- Indentation spaces
- Line length
- [etc - all 🟢 CONFIGURABLE]

---

## Recommendations for Agent Improvement

### 1. Prioritized Question Flow

```text
Phase 2A: Ask ALL 🔴 CRITICAL (required)
  ↓
User can choose:
  A. Continue to IMPORTANT questions
  B. Apply smart defaults for IMPORTANT+CONFIGURABLE
  C. Review what defaults will be applied
  ↓
Phase 2B: Ask 🟡 IMPORTANT (recommended)
  ↓
User can choose:
  A. Continue to CONFIGURABLE questions
  B. Apply defaults for CONFIGURABLE
  ↓
Phase 2C: Ask 🟢 CONFIGURABLE (optional)
```

### 2. Smart Defaults for Skipped Questions

**IMPORTANT Defaults**:

- CQRS: Disabled (can add later if needed)
- Repository Pattern: Yes (testability benefit)
- Unit of Work: Yes (with Repository Pattern)
- Authorization Model: RBAC (most common)
- CI/CD Platform: GitHub Actions (if using GitHub)
- Observability: Azure Monitor (native integration)

**CONFIGURABLE Defaults**:

- Cache TTL L1: 15 minutes
- Cache TTL L2: 60 minutes
- Cache TTL L3: 4 hours
- Line Coverage: 80%
- Branch Coverage: 75%
- Mutation Score: 70%
- Line Length: 120 characters
- Indentation: 4 spaces (.NET), 2 spaces (TypeScript)

### 3. Conditional Decision Handling

Some decisions are conditional on others:

```text
IF Event Sourcing Enabled == Yes
  THEN Ask: Event Store selection (🟡 IMPORTANT)

IF CQRS Enabled == Yes
  THEN Ask: CQRS Pattern (🟡 IMPORTANT)

IF Orchestration Platform == AKS
  THEN Ask: K8s Package Manager (🟡 IMPORTANT)
  THEN Ask: Ingress Controller (🟡 IMPORTANT)

IF KEDA Enabled == Yes
  THEN Ask: KEDA Scalers (🟢 CONFIGURABLE)
```

### 4. Progress Indicators by Phase

```text
Phase 2A Progress: [████░░░░░░] 4 of 17 CRITICAL decisions
Phase 2B Progress: [██░░░░░░░░] 5 of 35 IMPORTANT decisions
Phase 2C Progress: [██████░░░░] 8 of 13 CONFIGURABLE decisions
```

---

**End of Analysis**
