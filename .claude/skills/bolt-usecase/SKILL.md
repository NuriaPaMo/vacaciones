---
name: bolt-usecase
description: "Generate detailed use cases in UML / Cockburn style from Bolt Framework feature specs. Produces `docs/legacy/specs/use-cases/UC-NNN.md` with actors, preconditions, main flow, alternative flows, postconditions, exceptions. Triggers: 'use case', 'Cockburn', 'UML use case', 'generate UC', 'detailed use case', '/bolt-usecase'."
---

# Bolt Use Case — Methodology

Translate user stories into detailed Cockburn-style use cases that bridge
the gap between high-level stories and Gherkin scenarios.

**Bolt Framework Stage**: ANALYZE
**Responsible Agent**: Use Case Author

## Scenario detection (MANDATORY)

Before generating any use case, read `.boltf/memory/constitution.digest.md` and declare
the **detected scenario** explicitly:
`backend-only | frontend-only | infra-only | backend+frontend | fullstack`.

Template adaptation per scenario:

- `backend-only` → primary actor = sistema/servicio (Scheduler, Daemon,
  Worker); main flow centrado en eventos de dominio, comandos y
  side effects de persistencia/mensajería; extensiones cubren fallos de
  consumer / poison messages / compensaciones.
- `frontend-only` → primary actor = usuario humano; main flow centrado en
  navegación entre pantallas, estados de UI (loading/empty/error) y
  validación cliente; extensiones cubren errores de red, timeouts, datos
  vacíos y permisos de cliente.
- `infra-only` → **NO** generar UC Cockburn tradicional. Sustituir por:
  - **Validation scenarios** estilo policy-as-code / infra-tests (p. ej.
    Terratest, Conftest + Rego) describiendo qué debe garantizar el módulo
    IaC (recursos creados, tags, NSGs, RBAC, SLOs).
  - Documentar como `IaC-NNN.md` (no `UC-NNN.md`) bajo
    `docs/legacy/specs/infra-scenarios/` (crear ruta si no existe).
- `backend+frontend` → flujo completo cliente ↔ API: main flow alterna
  pasos UI y pasos servidor; explicitar latencias y consistencias
  (eventual / fuerte) entre ambos.
- `fullstack` → añadir secuencia 3-capas (UI → API → Infra/Datastore) y
  documentar puntos de fallo cross-layer (timeouts, circuit breaker,
  retries, idempotencia).

Documenta el escenario detectado al inicio de cada UC en una metadata
inicial (`Scenario: backend-only`, etc.).

## Referenced skills (carga condicional según escenario)

- `infra-only` → al redactar validation scenarios, alinear con las
  convenciones IaC del stack de la constitution; **no** generar UC Cockburn.
- `backend` (cualquier escenario con backend) → mapear flujos a los
  handlers / comandos / eventos del stack backend definido en la
  constitution.
- `frontend` (cualquier escenario con frontend) → alinear los pasos UI con
  los componentes y rutas existentes del stack frontend.
- Si el flujo cruza UI ↔ API → considerar `mermaid-creator` para sequence
  diagram complementario.

## Output location

`docs/legacy/specs/use-cases/UC-NNN.md` (existing convention in this repo).
Excepción: `infra-only` → `docs/legacy/specs/infra-scenarios/IaC-NNN.md`.

## Cockburn template

```markdown
# UC-NNN: [Use Case Name]

## Scope
[System / module under analysis]

## Level
User goal / Subfunction / Summary

## Primary Actor
[Role / persona]

## Stakeholders and Interests
- [Stakeholder]: [What they care about]

## Preconditions
- [Condition 1]
- [Condition 2]

## Success Guarantee (Postconditions)
- [What is true after success]

## Minimal Guarantee
- [What is true even on failure]

## Main Success Scenario
1. [Step 1]
2. [Step 2]
3. ...

## Extensions (Alternative Flows)
- 2a. [Condition]: [Alternative]
- 3a. [Condition]: [Alternative]

## Special Requirements
- [NFR or constraint]

## Technology and Data Variations List
- [Variation 1]

## Frequency of Occurrence
[How often]

## Open Issues
- [Question]
```

## Process

1. Read user story from `requirements.md`.
2. Identify primary actor and supporting actors.
3. Trace main flow step-by-step.
4. For each step, ask "what can go wrong?" → extension flows.
5. Map to existing diagrams (sequence) when available.
6. Pick next available `UC-NNN`.

## Quality gates

- Every P1 user story has at least one UC.
- Each UC has at least one extension flow.
- Numbering consistent across `docs/legacy/specs/use-cases/`.

## Related agents (next steps)

- → `bolt-gherkin`: turn UC into Gherkin scenarios.
- → `bolt-architect`: produce sequence diagrams matching UCs.
- → `bolt-analyze`: verify UC ↔ spec ↔ tests alignment.
