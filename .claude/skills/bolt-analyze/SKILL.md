---
name: bolt-analyze
description: "Run consistency analysis across Bolt Framework artifacts (spec ↔ data model ↔ contracts ↔ implementation ↔ tests). Detects entity/operation drift, missing tests, divergent contracts. Produces an alignment report. Triggers: 'consistency analysis', 'verify alignment', 'spec vs impl', 'drift detection', 'VALIDATE phase', '/bolt-analyze'."
---

# Bolt Analyze — Methodology

Validate alignment between specifications, contracts, implementation, and
tests.

**Bolt Framework Stage**: VALIDATE
**Responsible Agent**: Quality Analyst

## Available scripts

- Bash: `scripts/bash/alignment-analysis.sh`
- PowerShell: `scripts/powershell/Get-AlignmentAnalysis.ps1`

## Files to analyze

| Type | Location | Purpose |
|------|----------|---------|
| Feature Spec | `specs/*/requirements/requirements.md` | Source of truth |
| User Stories | same | Acceptance criteria |
| Gherkin | `specs/*/requirements/*.feature` | BDD scenarios |
| API Contracts | `specs/*/contracts/*.yaml` | Interface definitions |
| Domain Models | `src/domain/` | Business logic |
| Use Cases | `src/application/` | Application services |
| Controllers | `src/presentation/` | API endpoints |
| Tests | `tests/` | Test coverage |

## Analysis workflow

### 1. Extract entities

From each source, extract entities, attributes, operations, relationships.

### 2. Cross-check

- Spec entity → data model? → DB schema? → DTO? → API? → tests?
- Each AC → at least one Gherkin scenario?
- Each endpoint in OpenAPI → controller method? → integration test?
- Each domain operation → use case? → handler? → unit test?

### 3. Detect drift

| Drift type | Example |
|------------|---------|
| Missing operation | Spec says `register` but no `RegisterUserHandler` |
| Schema mismatch | Spec field `email` is string, DB has `varchar(50)` |
| Missing test | Endpoint exists but no integration test |
| Orphan code | Class in `src/` not referenced by any spec |

### 4. Output report

```markdown
## Consistency Analysis: [Feature]

### Drift detected
| Artifact A | Artifact B | Mismatch | Severity |

### Missing tests
| Source artifact | Expected test |

### Orphan code
| File | Reason |

### Recommendations
1. ...
```

## Quality gates

- Zero drift between spec and implementation.
- Each AC covered by at least one test.
- Each contract endpoint has integration test.

## Related agents (next steps)

- → `bolt-implement`: fix inconsistencies in code.
- → `bolt-specify`: update spec if intended behavior changed.
- → `bolt-gherkin`: regenerate scenarios.
- → `bolt-review`: review consistency fixes before merge.
