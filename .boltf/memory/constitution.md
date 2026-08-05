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

> **⚠️ IMPORTANT**: Define the active scopes FIRST. This determines which articles and scope constitutions apply. The project type (Infrastructure / Application / Full Stack) is automatically derived from the selected scopes.

### Section 1.1: Active Scopes

Select ONE or MORE scopes. Each active scope injects its own constitution sections and activates the corresponding articles. Scopes are **combinable** — a typical project activates 2-4 scopes.

|     | Scope              | Description                                                  | Activates                                                                                             |
| --- | ------------------ | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| [ ] | **backend**        | Server-side APIs, services, domain logic                     | Articles II §2.1, III §3.1/3.3/3.4, IV, V, VI, VII, VIII, XIII §13.1-13.3, XIV, XV (A-D), XVII, XVIII |
| [ ] | **frontend**       | Web/mobile UI, SPA, design system                            | Articles II §2.2-2.3, III §3.2, VII §7.3-7.4, XIII (E2E), XIV, XV (frontend)                          |
| [ ] | **cloud-platform** | Infrastructure, Landing Zones, IaC, platform engineering     | Articles VIII, IX, XII §12.3, XIII §13.4, XV (E-F)                                                    |
| [ ] | **data**           | Databases, ETL/ELT, analytics, data governance               | Articles V, VI                                                                                        |
| [ ] | **integration**    | API management, messaging, external system connectors        | Articles IV, XVII, XVIII                                                                              |
| [ ] | **ai**             | AI/ML models, agents, prompt engineering, responsible AI     | Article XIX §19.2 (emphasis) + AI-specific extensions                                                 |
| [ ] | **crm**            | Dynamics 365, Power Platform, Dataverse, business automation | Article VII                                                                                           |

> **Note**: The `work-management` scope (Azure DevOps, GitHub Projects, Jira synchronization) is **transversal** and managed separately. It does not appear here because it applies to all projects regardless of scope selection.

#### Common Scope Combinations

| Project Profile                     | Recommended Scopes                                                 |
| ----------------------------------- | ------------------------------------------------------------------ |
| REST API microservices              | `backend` + `cloud-platform` + `integration`                       |
| Full-stack web application          | `backend` + `frontend` + `data`                                    |
| AI-powered application              | `backend` + `ai` + `data`                                          |
| Enterprise CRM solution             | `crm` + `integration` + `data`                                     |
| Data platform / analytics           | `data` + `cloud-platform`                                          |
| Landing Zone / platform engineering | `cloud-platform`                                                   |
| Complete enterprise solution        | `backend` + `frontend` + `cloud-platform` + `data` + `integration` |

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

#### Base Constitution (always apply)

- [ ] Project scope and selected scopes match Article I / Section 1.1
- [ ] Environment config per Article X
- [ ] CI/CD per Article XI
- [ ] Observability per Article XII
- [ ] Security policies per Article XVI
- [ ] Governance compliance per Article XIX

#### Scope-Specific (apply per selected scopes)

> Load the relevant scope constitution(s) from `.boltf/scopes/<scope>/memory/constitution.md`

| Scope               | Key Checks                                                                                                                                                                                                                                                                                                                 |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **backend**         | Language/Runtime (Art. II), Architecture (Art. III), CQRS (§3.3), Communication (Art. IV), Data Storage (Art. V), Caching (Art. VI), Identity (Art. VII), Containers (Art. VIII), Testing (Art. XIII), Code Standards (Art. XIV), Project Structure (Art. XV), Legacy & Migration (Art. XVII), API Management (Art. XVIII) |
| **frontend**        | Framework (§2.2), Mobile (§2.3), Architecture (§3.2), Auth Flows (§7.3), Authorization (§7.4), Testing (Art. XIII), Code Standards (Art. XIV), Legacy & Migration (Art. XVII)                                                                                                                                              |
| **cloud-platform**  | Containers & Orchestration (Art. VIII), IaC (Art. IX), Infra Monitoring (§12.3), Infra Testing (§13.4), Project Structure Templates (Art. XV)                                                                                                                                                                              |
| **data**            | Data Storage (Art. V), Caching (Art. VI)                                                                                                                                                                                                                                                                                   |
| **integration**     | Communication (Art. IV), Containers/Dapr (Art. VIII), Legacy & Migration (Art. XVII), API Management (Art. XVIII)                                                                                                                                                                                                          |
| **ai**              | Scope-specific AI/ML decisions                                                                                                                                                                                                                                                                                             |
| **crm**             | Identity & Access (Art. VII), CRM-specific integrations                                                                                                                                                                                                                                                                    |
| **work-management** | Artefact mapping, sync strategy, traceability                                                                                                                                                                                                                                                                              |

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
