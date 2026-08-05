---
name: bolt-retire
description: "Plan and execute controlled retirement of systems, features or entire projects in Bolt Framework — assessment → planning → communication → migration → archive → decommission. Triggers: 'retirement', 'decommission', 'sunset feature', 'deprecate service', 'shutdown system', 'end of life', 'RETIREMENT phase', '/bolt-retire'."
---

# Bolt Retire — Methodology

Plan and execute controlled retirement of systems, features, or projects.

**Bolt Framework Stage**: RETIREMENT
**Responsible Agent**: Retirement Coordinator

## Available scripts

- Bash: `scripts/bash/plan-retirement.sh`
- PowerShell: `scripts/powershell/Plan-Retirement.ps1`

## Philosophy

> "Every system has a lifecycle. Retirement is not failure — it's a
> natural phase that deserves the same care as birth."

```text
PLAN → COMMUNICATE → MIGRATE → ARCHIVE → DECOMMISSION
```

## When to retire

| Signal | Indicator | Action |
|--------|-----------|--------|
| **Obsolescence** | Technology no longer supported | Plan migration |
| **Replacement** | New system serves same purpose | Plan transition |
| **Low Usage** | < 5 % of peak usage | Evaluate necessity |
| **High Cost** | Cost > Value delivered | Cost-benefit analysis |
| **Technical Debt** | Unmaintainable codebase | Rebuild or retire |
| **Business Change** | No longer serves business need | Document and retire |

## Retirement types

| Type | Scope | Complexity | Duration |
|------|-------|------------|----------|
| **Feature** | Single capability | LOW | Days-Weeks |
| **Service** | Single microservice | MEDIUM | Weeks-Months |
| **System** | Multiple services | HIGH | Months |
| **Project** | Entire project | VERY HIGH | Months-Year |

## Process

### Phase 1 — Assessment

```yaml
assessment:
  scope:
    type: [feature|service|system|project]
    name: "[name]"
    components: [list]
  impact:
    users:
      active: [count]
      affected: [count]
    systems:
      dependent: [list]
      integrated: [list]
    data:
      volume: [size]
      retention: [period]
  timeline:
    announcement: [date]
    deprecation: [date]
    migration_deadline: [date]
    shutdown: [date]
```

### Phase 2 — Planning

#### Stakeholder communication

| Audience | Channel | Timing | Message |
|----------|---------|--------|---------|
| Internal teams | Email + Slack | T-90 days | Detailed plan |
| External users | Email + Blog | T-60 days | Impact + alternatives |
| Partners | Direct contact | T-60 days | Migration support |

#### Migration path

| Component | Source | Target | Migration tool |
|-----------|--------|--------|----------------|
| Users | System A | System B | Auto-migrate |
| Data | DB A | DB B | ETL script |
| Integrations | API v1 | API v2 | Adapter |

#### Deprecation schedule

| Date | Milestone | Actions |
|------|-----------|---------|
| T-90 | Announcement | Notify all stakeholders |
| T-60 | Deprecation | Add deprecation warnings |
| T-30 | Feature freeze | No new features |
| T-14 | Final warning | Urgent migration reminder |
| T-7 | Read-only mode | Disable writes |
| T-0 | Shutdown | Decommission |

### Phase 3 — Migration

- Provide auto-migrate tooling where possible.
- Surface migration progress dashboard.
- Maintain side-by-side (old + new) until migration cutover.

### Phase 4 — Archive

- Export data to long-term storage per retention policy.
- Snapshot code repo with `archive/` branch / tag.
- Document architecture for posterity in `docs/archived/`.

### Phase 5 — Decommission

- Stop services / delete cloud resources.
- Revoke credentials / certificates.
- Remove DNS entries.
- File final ADR documenting the retirement.

## Quality gates

- Migration path defined for every affected user / dataset / integration.
- T-90/T-60/T-30 communications sent on time.
- Data exported per retention policy.
- Final ADR filed.
- Cloud resources confirmed removed (no orphaned spend).

## Related agents (next steps)

- → `bolt-release`: create final archive release before shutdown.
- → `bolt-analyze`: impact analysis on dependent systems.
- → `bolt-adr`: document retirement decision (final ADR).
- → `bolt-status`: final project status snapshot.
