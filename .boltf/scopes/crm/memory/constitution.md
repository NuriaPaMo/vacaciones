# BOLT Framework Project Constitution — Scope: CRM

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `crm` — Customer Relationship Management, Dynamics 365, Power Platform, Dataverse, and business process automation.
> Articles marked with 🔄 are **common to all scopes** and always present.
> Sections marked with 🆕 are **proposed additions** not present in the original constitution.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article VII: Identity & Access Management

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 7.1: Authentication Provider 🔴 CRITICAL

> **🔴 CRITICAL**: Authentication provider choice (Entra ID vs Auth0 vs Keycloak) = different integration patterns

Select ONE:

- [ ] **Microsoft Entra ID (Azure AD)** - Enterprise, recommended
- [ ] **Azure AD B2C** - Customer-facing
- [ ] **Auth0** - Multi-provider
- [ ] **Keycloak** - Self-hosted

### Section 7.2: Token Configuration 🟢 LOW-PRIO

> **🟢 LOW-PRIO**: Token lifetimes can be adjusted at runtime via provider configuration

| Setting                | Value                                              |
| ---------------------- | -------------------------------------------------- |
| Access Token Lifetime  | [ ] 5 min [ ] 15 min [ ] 60 min                    |
| Refresh Token Lifetime | [ ] 24h [ ] 7 days [ ] 30 days                     |
| Token Storage          | [ ] HTTP-only Cookie [ ] Memory [ ] Secure Storage |
| PKCE Required          | [ ] Yes [ ] No                                     |

### Section 7.3: Authorization Model 🟡 IMPORTANT

> **🟡 IMPORTANT**: Authorization model affects access control patterns but can be refactored

Select ONE:

- [ ] **RBAC** - Role-Based Access Control
- [ ] **ABAC** - Attribute-Based Access Control
- [ ] **ReBAC** - Relationship-Based (Zanzibar-style)
- [ ] **Hybrid RBAC + ABAC**

Auth Flows - Select per client type:

| Client              | Auth Flow                 |
| ------------------- | ------------------------- |
| SPA (Angular/React) | Authorization Code + PKCE |
| Mobile              | Authorization Code + PKCE |
| API-to-API          | Client Credentials        |
| CLI Tools           | Device Code Flow          |

### Section 7.4: API Security

| Feature            | Configuration                     |
| ------------------ | --------------------------------- |
| JWT Validation     | [ ] Azure AD [ ] Auth0 [ ] Custom |
| Scope-based access | [ ] Enabled [ ] Disabled          |
| API Key fallback   | [ ] Enabled [ ] Disabled          |

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

## Proposed Additions — CRM Gaps 🆕

> The original constitution has **no CRM-specific guidance**. The following are recommended
> Microsoft technologies and governance practices for CRM/Power Platform projects.

### Microsoft Dynamics 365

- **Dynamics 365 Sales / Customer Service / Field Service**: Select the appropriate Dynamics 365 module(s) for the CRM domain. Define which entities (Account, Contact, Opportunity, Case, etc.) are in-scope.
- **Dataverse Data Model**: All CRM data resides in Dataverse. Define entity relationships, custom entities, choice columns, and business rules. Follow Microsoft naming conventions (`prefix_entityname`).
- **Solution Architecture**: Use managed and unmanaged solutions for ALM. Define a solution layering strategy (base → customization → ISV) to avoid conflicts.
- **Business Process Flows**: Model sales/service processes as Business Process Flows in Dynamics 365 for guided user experiences.

### Power Platform ALM

- **Environments**: Map Power Platform environments to BOLT Framework environment strategy (Dev → UAT → Pre → Prod). Use environment variables for cross-environment configuration.
- **Solution Export/Import**: Automate solution promotion using Power Platform CLI (`pac solution`) or Azure DevOps Power Platform Build Tools.
- **Source Control**: Export solutions as unpacked (XML) into Git repository. Include solution metadata in CI/CD pipeline validation.
- **Environment Variables & Connection References**: Externalize all environment-specific settings. Never hardcode connection strings or environment URLs.

### Power Apps

- **Canvas Apps**: Use for task-specific, mobile-first experiences. Follow component library pattern for UI reuse.
- **Model-Driven Apps**: Use for data-heavy, form-based CRM interfaces built on Dataverse. Define site maps, views, forms, and dashboards.
- **Power Apps Component Framework (PCF)**: Use for custom UI controls when out-of-box controls are insufficient. Build with TypeScript + React.

### Power Automate

- **Cloud Flows**: Use for Dataverse triggers, approval workflows, and integration with Microsoft 365 services.
- **Desktop Flows (RPA)**: Use for legacy system integration where APIs are unavailable. Run via attended/unattended modes on Azure-hosted machines.
- **Flow Governance**: Use Data Loss Prevention (DLP) policies to control which connectors are allowed per environment. Require approval for premium connector usage.

### Power Pages & Copilot Studio

- **Power Pages**: Use for external-facing CRM portals (customer self-service, partner portals). Integrate with Dataverse web roles and table permissions for security.
- **Copilot Studio**: Build conversational AI agents for customer support. Integrate with Dynamics 365 knowledge articles and Dataverse queries.

### CRM-Specific Security

- **Dataverse Security Model**: Implement Business Units, Security Roles, Teams, and Field-Level Security. Follow least-privilege principles.
- **Entra ID Integration**: Use Microsoft Entra ID (Azure AD) for SSO. Map Entra ID groups to Dynamics 365 security roles for automated role assignment.
- **Row-Level Security**: Use Dataverse owner-based and organization-based access control. Define sharing rules for cross-team record access.

### CRM Testing

- **EasyRepro / Playwright**: Automated UI testing for model-driven apps. Use Playwright for canvas app testing.
- **FakeXrmEasy**: Unit testing for Dynamics 365 plugins and custom workflow activities.
- **Solution Checker**: Run Power Apps Solution Checker in CI/CD to detect performance, reliability, and security issues.

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
