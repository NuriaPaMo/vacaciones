# BOLT Framework Project Constitution — Scope: Work Management

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `work-management` — Synchronization of features, use cases, bolts, tasks, and dependencies with work management systems (Azure DevOps, GitHub Projects, Jira).
> Articles marked with 🔄 are **common to all scopes** and always present.
> Sections marked with 🆕 are **proposed additions** not present in the original constitution.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

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

## Article XI: CI/CD Pipeline 🔄 ⭐

> **📋 Applies to**: ALL project types
> **⭐ Especially relevant** for work-management: pipeline triggers, branch strategy, and deployment stages map directly to BOLT Framework artefact lifecycle.

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

## Article XIX: Governance 🔄 ⭐

> **📋 Applies to**: ALL project types
> **⭐ Especially relevant** for work-management: amendment workflows, AI agent compliance, and audit trail align directly with work item traceability.

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

## Proposed Additions — Work Management Gaps 🆕

> The original constitution has **no work management or project tracking guidance**. The following
> are recommended practices and Microsoft/Azure technologies for BOLT Framework artefact synchronization.

### BOLT Framework Artefact-to-Work-Item Mapping

Define the canonical mapping between BOLT Framework Methodology artefacts and work management system entities:

| BOLT Artifact               | Azure DevOps                 | GitHub Projects               | Jira                              |
| --------------------------- | ---------------------------- | ----------------------------- | --------------------------------- |
| **Feature** (`specs/XXX-*`) | Epic                         | Tracked Issue (label: `epic`) | Epic                              |
| **Use Case**                | User Story                   | Issue (label: `user-story`)   | Story                             |
| **Requirement**             | Requirement (child of Story) | Sub-Issue                     | Sub-task                          |
| **Bolt** (micro-iteration)  | Iteration / Sprint           | Milestone                     | Sprint                            |
| **Task** (from planning/)   | Task (child of Story)        | Issue (label: `task`)         | Task                              |
| **Dependency**              | Predecessor/Successor link   | Dependency field              | Issue Link (blocks/is-blocked-by) |
| **Bug**                     | Bug                          | Issue (label: `bug`)          | Bug                               |
| **ADR**                     | Wiki page (linked to Epic)   | Discussion / linked Issue     | Confluence page                   |

### Work Management Platform Selection

Select ONE primary platform:

- [ ] **Azure DevOps Boards** — Full ALM: Boards, Backlogs, Sprints, Queries, Dashboards. Best for Azure-centric teams.
- [ ] **GitHub Projects v2** — Native GitHub integration: custom fields, views, workflows automations. Best for GitHub-centric teams.
- [ ] **Jira (Atlassian)** — Enterprise project management: advanced workflows, Confluence integration. Best for multi-tool enterprises.
- [ ] **Hybrid** — GitHub for code + Azure DevOps for work tracking (via Azure Boards GitHub integration).

### Synchronization Strategy

#### Spec → Work Item (Push)

When a BOLT Framework agent creates or updates a feature spec (`specs/XXX-feature-name/`):

1. **Auto-create** Epic/Feature work item with title, description, and acceptance criteria from `feature.md`.
2. **Auto-create** child User Stories from `requirements/` files.
3. **Auto-create** Tasks from `planning/tasks.md` with effort estimates.
4. **Link** work items to the spec directory via artifact links.
5. **Set** iteration/sprint assignment based on Bolt schedule.

#### Work Item → Spec (Pull)

When work items are updated externally (status changes, re-prioritization):

1. **Sync** status changes back to spec metadata.
2. **Update** planning/tasks.md completion state.
3. **Alert** on scope changes that affect feature specification.

#### Bidirectional Conflict Resolution

- **Spec is source of truth** for requirements and acceptance criteria.
- **Work management system is source of truth** for scheduling, assignment, and effort tracking.
- Conflicts are flagged as warnings for human resolution.

### Azure DevOps Boards Configuration

- **Process Template**: Agile (recommended) or Scrum. Map BOLT Framework phases to iteration paths.
- **Custom Fields**: Add `bolt_feature_id` (text), `bolt_phase` (picklist: Inception/Discovery/Construction/Transition/Production/Retirement), `bolt_number` (integer).
- **Work Item Queries**: Pre-built shared queries for:
  - "Current Bolt Tasks" — tasks in active iteration, grouped by feature.
  - "Feature Traceability" — Epic → Stories → Tasks → Commits → PRs → Deployments.
  - "Phase Dashboard" — Work items by BOLT Framework phase, showing progress and blockers.
- **Dashboards**: Burndown per Bolt, velocity across Bolts, feature completion status, dependency heatmap.
- **Area Paths**: Map to scope names (`backend`, `frontend`, `cloud-platform`, etc.) for cross-scope filtering.
- **Iteration Paths**: Map to Bolts: `Bolt-001`, `Bolt-002`, etc. with start/end dates.

### GitHub Projects v2 Configuration

- **Custom Fields**: `Bolt Feature ID` (text), `Bolt Phase` (single-select), `Bolt` (iteration), `Scope` (single-select), `Priority` (single-select).
- **Views**: Board view per Bolt, Table view for backlog, Roadmap view for feature timeline.
- **Automations**: Auto-set status when PR is merged, auto-assign to Bolt when issue is labeled, auto-close when all sub-issues resolve.
- **Labels**: `feature`, `user-story`, `task`, `bug`, `adr`, `scope:backend`, `scope:frontend`, etc.

### Traceability & Audit

End-to-end traceability chain:

```text
Feature Spec (specs/XXX/)
  → Work Item (Epic/Story/Task)
    → Branch (feature/XXX-*)
      → Commits (linked to work item)
        → Pull Request (linked to work item)
          → CI/CD Pipeline (deployment to environment)
            → Release (tagged, linked to Bolt)
```

- All work item state transitions MUST be logged.
- Bolt Framework agents MUST reference work item IDs in commit messages and PR descriptions.
- Branch naming convention: `feature/XXX-short-desc` where `XXX` matches the feature spec number.

### Dependency Management

- **Intra-feature**: Tasks within a feature linked with predecessor/successor relationships.
- **Cross-feature**: Features linked with "depends on" / "is depended by" relationship types.
- **Cross-scope**: Dependencies spanning scopes (e.g., backend ← frontend) tracked with custom tags and cross-scope queries.
- **Visualization**: Azure DevOps Delivery Plans or GitHub Projects Roadmap view for timeline dependencies. Use dependency graph queries to detect cycles.

### Reporting & Metrics

| Metric                    | Source                                       | Cadence     |
| ------------------------- | -------------------------------------------- | ----------- |
| **Bolt Velocity**         | Completed story points per Bolt              | Per Bolt    |
| **Feature Lead Time**     | Spec creation → Production deployment        | Per Feature |
| **Cycle Time**            | Work item activated → Closed                 | Weekly      |
| **WIP Limit**             | Active tasks per scope                       | Continuous  |
| **Dependency Health**     | Blocked items / total items                  | Daily       |
| **Traceability Coverage** | Work items with linked commits & PRs / total | Per Bolt    |

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
