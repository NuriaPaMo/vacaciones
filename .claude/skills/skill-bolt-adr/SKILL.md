---
name: skill-bolt-adr
description: "Create Architecture Decision Records (ADRs) using MADR (Markdown Any Decision Records) format for documenting architectural decisions. Use when choosing frameworks, databases, design patterns, or any significant technical decisions. Triggers => 'ADR', 'architecture decision', 'decision record', 'MADR', 'document decision', 'why did we choose', 'technical decision', 'architecture choice', 'decision log', 'document architecture', 'design decision'."
---

# Architecture Decision Records

## When to Use

- Documenting framework/database/architecture pattern choices
- Technology selections with long-term impact
- NOT for code conventions (use constitution) or dev tools

## Quick Start

```powershell
# Get next ADR number
$Num = .\.claude\skills\bolt-adr\scripts\Get-NextAdrNumber.ps1

# Create ADR file
$Path = "docs/adr/ADR-$('{0:D4}' -f $Num)-adopt-postgresql.md"
```

## MADR Template

```markdown
# ADR-NNNN: [Title in imperative form]

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## Context

What problem are we solving? Why now?

## Decision

We will [decision in imperative form].

## Rationale

Why this option over alternatives?

## Alternatives Considered

- **Option A**: [Brief description] - Rejected because [reason]
- **Option B**: [Brief description] - Rejected because [reason]

## Consequences

### Positive

- [Benefit 1]

### Negative

- [Cost/risk 1]

## Implementation Notes

[Optional: How to apply this decision]
```

## Use Mermaid for Diagrams

```markdown
## Context

\\\mermaid
graph TB
A[Current System] --> B[Problem]
B --> C[Decision Point]
\\\
```

Types: `graph`, `sequenceDiagram`, `classDiagram`, `erDiagram`

## Examples

- Architecture: [examples/diagram-architecture-comparison.md](examples/diagram-architecture-comparison.md)
- Integration: [examples/diagram-integration-sequence.md](examples/diagram-integration-sequence.md)
- Data Model: [examples/diagram-data-model.md](examples/diagram-data-model.md)

## References

- [MADR Format](https://adr.github.io/madr/)
- Templates: `.claude/skills/skill-bolt-adr/templates/`
- Scripts: `.claude/skills/skill-bolt-adr/scripts/`
