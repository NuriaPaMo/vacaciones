---
name: bolt-clarify
description: "Structured questioning to resolve ambiguities and underspecified areas in Bolt Framework specs. Categories: functional, data, business rules, integration. Produces a Clarification Summary table and updates the spec. Triggers: 'clarify requirements', 'ambiguous spec', 'underspecified', 'vague user story', 'missing acceptance criteria', 'UNDERSTAND phase', '/bolt-clarify'."
---

# Bolt Clarify — Methodology

Drive structured questioning to resolve ambiguities identified during
specification or analysis phases.

**Bolt Framework Stage**: UNDERSTAND (clarification loop)
**Responsible Agent**: Business Explorer

## When to use

| Trigger                     | Source         |
|-----------------------------|----------------|
| Vague requirement           | `bolt-specify` |
| Missing acceptance criteria | `bolt-analyze` |
| Conflicting requirements    | Analysis report|
| Technical ambiguity         | `bolt-plan`    |
| Stakeholder misalignment    | Review feedback|

## Question categories

### 1. Functional clarification

For vague user stories or requirements:

```markdown
## Clarification: [Requirement ID]

**Original Statement**: "[vague requirement text]"
**Ambiguity Type**: Missing behavior specification

### Questions
1. **Actor**: Who performs this action? (End user / Admin / System / External)
2. **Trigger**: What initiates this action? (User click / Schedule / Event / Condition)
3. **Expected Outcome**: What should happen?
4. **Error Scenarios**: What can go wrong?
5. **Edge Cases**: Empty input, max values, etc.
```

### 2. Data clarification

For unclear data requirements:

- Required fields and mandatory flags.
- Validation rules (min/max, format, pattern).
- Relationships (1:1 / 1:N / N:N, cascade).
- Historical data needs (no history / soft delete / full audit).
- Default values.

### 3. Business rule clarification

For complex business logic:

- Rule definition: WHEN / THEN / ELSE.
- Exceptions.
- Priority on conflict.
- Time sensitivity (real-time / batch / async).
- Audit needs.

### 4. Integration clarification

For external system interactions:

- Direction (we → them / they → us / bidirectional).
- Protocol (REST / GraphQL / Event / File / DB).
- Authentication (API Key / OAuth2 / mTLS / Other).
- Error handling: retry, fallback, alerting.
- SLA: availability, latency, throughput.

## Output format

```markdown
## Clarification Summary

**Feature**: [Feature name]
**Session Date**: [Date]

### Resolved Items
| ID | Question | Resolution | Updated In |
|----|----------|------------|------------|

### Remaining Questions
| ID | Question | Blocker Level | Owner |
|----|----------|---------------|-------|

### Specification Updates
- [ ] `specs/[feature]/requirements/requirements.md`
- [ ] `specs/[feature]/requirements/data-model.md`

**Next Steps**:
1. Update specifications with resolved items
2. Schedule follow-up for remaining questions
3. Proceed with planning once all blockers resolved
```

## Quality gates

- Each detected ambiguity generates at least one question.
- Every resolution updates the spec (or an ADR if architectural).
- Blocker-level questions have a named owner.

## Visual ambiguities

Si la ambigüedad afecta layout, jerarquía de información, flujo entre
pantallas o estados de UI (default/empty/loading/error/success), responder
con un **mockup HTML low-fi** además de prosa:

- Si `specs/<feature>/mockups/` no existe → cargar `bolt-ui-mockups` en modo
  `generate` y producir el mínimo viable de pantallas para resolver la
  ambigüedad.
- Si ya existe → cargar `bolt-ui-mockups` en modo `refine` y aplicar el
  cambio puntual sobre la pantalla afectada.
- Devolver al usuario el enlace al HTML como evidencia clarificadora y
  registrar la decisión visual en la tabla de Resoluciones.

No aplicar a escenarios `backend-only` / `infra-only` salvo confirmación
explícita del usuario (admin panel ad-hoc, revisión con stakeholder).

## Related agents (next steps)

- → `bolt-specify`: incorporate clarifications into the spec.
- → `bolt-plan`: adjust plan based on clarifications.
- → `bolt-analyze`: re-run consistency analysis after updates.
- → `bolt-mockup`: iterar mockup si la clarificación visual lo requiere.

## References

- `.github/prompts/bolt-business-analysis.prompt.md`
