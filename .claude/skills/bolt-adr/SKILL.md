---
name: bolt-adr
description: "Create Architecture Decision Records (ADRs) in MADR format documenting significant technical decisions, context, considered options and consequences. Produces `docs/adr/ADR-NNN-title.md`. Triggers: 'create ADR', 'document decision', 'architecture decision record', 'MADR', 'why did we choose', 'technical decision log', '/bolt-adr'."
---

# Bolt ADR — Methodology

Document architecturally significant decisions using MADR (Markdown Any
Decision Records) format.

**Bolt Framework Stage**: ANY (decisions can happen at any time)
**Responsible Agent**: Decision Logger

## When to create an ADR

- A framework / library / database / pattern is chosen for the project.
- A significant trade-off is made (consistency vs availability, monolith
  vs services, sync vs async).
- A workaround or constraint affects future evolution.
- A decision overrides or amends the constitution.

Avoid ADRs for trivia (variable names, file structure that follows
convention).

## ADR structure (MADR)

Use the canonical skill `skill-bolt-adr` for the full MADR template. Core
sections:

```markdown
# ADR-NNN: Title

## Status
Proposed / Accepted / Deprecated / Superseded by ADR-XXX

## Context and Problem Statement
What's the issue we're addressing?

## Decision Drivers (optional)
- Driver 1 ...
- Driver 2 ...

## Considered Options
- Option 1: ...
- Option 2: ...
- Option 3: ...

## Decision Outcome
Chosen: "Option N", because ...

### Consequences
- Good: ...
- Bad: ...

## More Information (optional)
Links, prototypes, references.
```

## Process

1. Pick next available `ADR-NNN` number (zero-padded).
2. Create `docs/adr/ADR-NNN-slug.md`.
3. Fill MADR template.
4. Update `docs/adr/README.md` (index).
5. If decision affects constitution, propose amendment via
   `bolt-constitution`.

## Quality gates

- Status, Context, Considered Options, Decision Outcome present.
- Consequences include at least one negative trade-off (no decision is
  free).
- Linked from the artifact that prompted it.

## Related agents (next steps)

- → `bolt-constitution`: amend constitution if decision conflicts.
- → `bolt-architect`: cross-reference architecture docs.
- → `bolt-analyze`: re-run consistency after ADR adoption.
