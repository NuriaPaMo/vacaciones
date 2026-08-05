---
name: bolt-ddd
description: "Domain-Driven Design modelling for Bolt Framework — bounded contexts, context maps, aggregates, entities, value objects, domain events, ubiquitous language. Produces docs in `docs/design/ddd/<context>/`. Triggers: 'DDD modeling', 'bounded context', 'context map', 'aggregate', 'value object', 'domain event', 'ubiquitous language', '/bolt-ddd'."
---

# Bolt DDD — Methodology

Model the problem domain using Domain-Driven Design, producing the
strategic (context map) and tactical (aggregates, VOs, events) artifacts.

**Bolt Framework Stage**: DISCOVERY (Domain Modeling)
**Responsible Agent**: Domain Modeler

## Outputs (per bounded context)

In `docs/design/ddd/<context>/`:

- `ubiquitous-language.md` — glossary of terms used by domain and team.
- `domain-model.md` — aggregates, entities, value objects, invariants.
- `aggregates.md` — boundary, root, invariants, transactional unit.
- `domain-events.md` — events emitted, payload, consumers.
- `domain-services.md` — services that don't fit in entities.
- `value-objects.md` — VOs with rules and equality semantics.

Plus, at the root of `docs/design/ddd/`:

- `context-map.md` — bounded contexts and their relationships
  (Partnership, Customer-Supplier, ACL, OHS, etc.).

## Process

1. **Distil ubiquitous language** from spec, stakeholders, existing docs.
2. **Identify bounded contexts** — model boundaries, not org charts.
3. **Draw context map** — relationships and integration patterns.
4. **Per context, define aggregates**:
   - Aggregate root (consistency boundary).
   - Invariants enforced by the root.
   - Entities and VOs.
   - Domain events emitted.
5. **Identify domain services** for cross-aggregate logic.
6. **Validate** — every spec entity maps to an aggregate or VO.

## Diagram tooling

Use the `bolt-datamodel-diagramer` and `mermaid-creator` skills for all
diagrams.

## Quality gates

- All spec entities mapped to DDD model.
- Aggregates have explicit invariants.
- Each bounded context has its own folder under `docs/design/ddd/`.

## Related agents (next steps)

- → `bolt-architect`: combine DDD with C4/architecture decisions.
- → `bolt-adr`: document strategic DDD decisions.
- → `bolt-plan`: feed model into the implementation plan.
- → `bolt-datamodel-diagramer`: produce visual diagrams.
