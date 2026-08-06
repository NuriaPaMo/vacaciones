# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the project, written in [MADR format](https://adr.github.io/madr/).

ADRs capture important architectural decisions along with their context, the alternatives considered, and the consequences of the chosen option.

## What is an ADR?

An ADR answers three key questions:

1. **CONTEXT** — Why are we deciding? (Problem, forces, constraints)
2. **DECISION** — What did we choose? (Chosen option, alternatives considered)
3. **CONSEQUENCES** — What happens because of it? (Positive, negative, neutral)

> ADRs are **immutable records**. Do not edit a past ADR to change its decision — instead, create a new ADR that supersedes it.

---

## Index

| ADR | Title | Category | Status | Date |
|-----|-------|----------|--------|------|
| [ADR-001](./ADR-001-backend-technology-stack.md) | Use C#/.NET 10 with Minimal APIs for Backend | TECH | Accepted | 2026-08-05 |
| [ADR-002](./ADR-002-backend-architecture-modular-monolith-cqrs.md) | Adopt Modular Monolith Architecture with Simple CQRS Using Native .NET Interfaces | ARCH | Accepted | 2026-08-05 |
| [ADR-003](./ADR-003-data-storage-and-access.md) | Use Azure SQL Database with EF Core (Writes) and Dapper (Reads) | DATA | Accepted | 2026-08-05 |
| [ADR-004](./ADR-004-frontend-technology-stack.md) | Use Vue 3.x with TypeScript, Vite, Pinia on Azure Static Web Apps | TECH | Accepted | 2026-08-05 |
| [ADR-005](./ADR-005-cloud-infrastructure-azure-container-apps-terraform.md) | Deploy Workloads to Azure Container Apps Using Terraform IaC | INFRA | Accepted | 2026-08-05 |
| [ADR-006](./ADR-006-cicd-observability-security-baseline.md) | Azure DevOps Pipelines with GitFlow, OTel→Azure Monitor, and GDPR-Compliant Security Baseline | INFRA | Accepted | 2026-08-05 |

---

## Categories

| Category | Tag | Description |
|----------|-----|-------------|
| Architecture | ARCH | Patterns, layers, bounded contexts, module boundaries |
| Technology | TECH | Framework, language, library selections |
| Data | DATA | Database, ORM, schema, migration strategy |
| Infrastructure | INFRA | Hosting, CI/CD, IaC, observability, security |
| Security | SEC | Auth, encryption, compliance |
| Integration | INT | APIs, protocols, third-party integrations |

---

## Decision Relationship Map

```
ADR-001 (C#/.NET 10)
  └── ADR-002 (Modular Monolith + Simple CQRS)
        └── ADR-003 (Azure SQL + EF Core + Dapper)

ADR-004 (Vue 3 + TypeScript + Vite + Pinia)

ADR-005 (Azure Container Apps + Terraform)
  ├── depends on ADR-001 (containerises .NET 10 backend)
  ├── depends on ADR-003 (provisions Azure SQL)
  └── depends on ADR-004 (provisions Azure Static Web Apps)

ADR-006 (CI/CD + Observability + Security)
  └── cross-cutting: applies to ADR-001 through ADR-005
```

---

## How to Add a New ADR

1. Determine the next sequential number from this index
2. Create a new file: `ADR-NNN-short-title.md`
3. Use the MADR template with the following sections:
   - Status (`Proposed` → `Accepted` or `Rejected`)
   - Date
   - Context
   - Decision Drivers
   - Considered Options (minimum 2–3)
   - Decision Outcome
   - Positive and Negative Consequences
   - Links (related ADRs, documentation)
4. Update this README index table
5. If superseding an existing ADR, update the old ADR's Status to `Superseded by ADR-NNN`

---

## References

- [MADR format specification](https://adr.github.io/madr/)
- [Documenting Architecture Decisions — Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [Architecture Decision Records — ThoughtWorks](https://www.thoughtworks.com/radar/techniques/lightweight-architecture-decision-records)
