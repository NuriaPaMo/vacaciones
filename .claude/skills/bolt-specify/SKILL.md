---
name: bolt-specify
description: "Transform natural language feature descriptions into structured Bolt Framework specifications. Generate `specs/[XXX-feature-name]/requirements/requirements.md` with FRs, NFRs, user stories, key entities, edge cases. Triggers: 'specify feature', 'create spec', 'turn description into spec', 'structured specification', 'PERCEIVE phase', 'ANALYZE phase', '/bolt-specify'."
---

# Bolt Specify — Methodology

Transform natural language feature descriptions into structured Bolt
Framework specifications.

**Bolt Framework Stage**: PERCEIVE + ANALYZE
**Responsible Agent**: Business Explorer

## Scenario detection (MANDATORY before generating the spec)

Read `.boltf/memory/constitution.digest.md` and declare scenario:
`backend-only | frontend-only | infra-only | backend+frontend | fullstack`.

Template adaptation:

- `backend-only` → omit UI/UX requirements; use system actors.
- `frontend-only` → omit SQL DDL, OpenAPI; suggest UI components per the
  constitution's stack; keep UX requirements.
- `infra-only` → replace `Key Entities` with `Recursos Cloud`; add SLOs;
  mention IaC; omit app user stories.
- `backend+frontend` / `fullstack` → full template.

## Prerequisites

1. Constitution exists at `.boltf/memory/constitution.md`.
2. Read constitution to understand tech stack and constraints.

## Available scripts

- Bash: `scripts/bash/create-new-feature.sh`
- PowerShell: `scripts/powershell/Create-NewFeature.ps1`

## Execution flow

### 1. Parse feature description

Extract:

- **Core Functionality**: what the feature does.
- **Actors**: who uses it.
- **Actions**: what actions are performed.
- **Data**: what data is involved.
- **Constraints**: limitations / requirements.

### 2. Generate feature branch

Semantic branch name pattern: `[NNN]-[short-name]` (e.g. `001-user-auth`).

Rules: scan existing branches for highest number; increment by 1; 2-4 word
short name in action-noun format.

### 3. Create spec directory

```text
specs/[XXX-feature-name]/
├── requirements/
│   └── requirements.md   # Feature specification (this agent)
├── contracts/
│   └── openapi.yaml      # API contracts (bolt-plan)
├── tests/
│   └── feature.feature   # Gherkin scenarios (bolt-gherkin)
└── planning/
    ├── plan.md           # Implementation plan (bolt-plan)
    ├── tasks.md          # Task list (bolt-tasks)
    └── research.md       # Technical research (bolt-plan)
```

### 4. Generate specification

```markdown
# Feature: [Feature Name]

## Overview
### Context
### Problem Statement
### Proposed Solution

## Functional Requirements
### FR-001: [Requirement Name]
**Priority**: P1/P2/P3
**Description**: ...
**Acceptance Criteria**:
- Given [context], when [action], then [outcome]

## Non-Functional Requirements
### NFR-001: [Requirement Name]
**Category**: Performance/Security/Scalability
**Requirement**: ...

## User Stories
### US-001: [Title]
**As a** ...
**I want to** ...
**So that** ...

## Key Entities
| Entity | Description | Key Attributes |

## Edge Cases
| Scenario | Expected Behavior |

## Out of Scope
## Open Questions
```

### 5. Constitution alignment check

- [ ] Tech stack compatible
- [ ] Architecture principles followed
- [ ] Security requirements addressed
- [ ] Quality gates defined
- [ ] No constitution violations

## Output summary

After creating the specification, output:

```markdown
## Specification Created
**Feature**: [XXX-feature-name]
**Location**: specs/[XXX-feature-name]/requirements/requirements.md
**Summary**: [N] FRs, [N] NFRs, [N] User Stories
**Next Steps**:
1. Use bolt-clarify if questions remain
2. Use bolt-plan for implementation planning
3. Use bolt-gherkin for BDD scenarios
**Commit Message**: `docs(specs): add specification for [feature-name]`
```

## Related agents (next steps)

- → `bolt-clarify`: resolve remaining ambiguities.
- → `bolt-plan`: create technical implementation plan.
- → `bolt-gherkin`: generate BDD scenarios from ACs.
- → `bolt-analyze`: verify spec consistency.

## References

- `.github/prompts/bolt-business-analysis.prompt.md`
- `.github/prompts/bolt-technical-discovery.prompt.md`
