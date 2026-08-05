---
name: bolt-plan
description: "Create technical implementation plan from a Bolt Framework feature specification. Produces `planning/plan.md`, `planning/research.md`, `requirements/data-model.md`, `contracts/openapi.yaml` (contract-first from data-model) and a scenario-aware Bolt breakdown. Runs in parallel with bolt-gherkin. Triggers: 'create implementation plan', 'technical plan', 'bolt breakdown', 'plan from spec', 'REASON phase', 'architecture plan', '/bolt-plan'."
---

# Bolt Plan — Methodology

Transform a feature specification into a detailed technical implementation
plan, following the Bolt Framework AI-DLC methodology with Bolts
(micro-iterations).

**Bolt Framework Stage**: REASON + PLAN (paralelo con bolt-gherkin)
**Responsible Agent**: Solution Architect

## Ejecución paralela con bolt-gherkin

bolt-plan y bolt-gherkin se ejecutan simultáneamente desde la misma spec.
bolt-plan NO espera a que Gherkin termine, ni Gherkin espera al plan.

Ambos outputs se entregan a bolt-tasks para reconciliación.

Si bolt-plan detecta flujos que podrían no tener cobertura BDD (ej:
background jobs, event handlers sin UI trigger, scheduled tasks), documentarlos
en la sección "Risks" para que bolt-tasks verifique cobertura.

## Automatic execution

When user requests a plan, **automatically**:

1. Verify on `feature/*` branch (`git branch --show-current`).
2. Read constitution.
3. Read feature spec.
4. Generate `planning/plan.md`.
5. Hand off to `bolt-tasks` for task breakdown (que reconcilia con gherkin).

Do NOT ask for confirmation.

## Available scripts

- Bash: `scripts/bash/setup-plan.sh`
- PowerShell: `scripts/powershell/Setup-Plan.ps1`

## Conditional skill loading (per scenario)

After detecting the scenario, load the stack-specific skills that the
project's constitution declares for the matching scope (backend patterns,
frontend patterns, infra/IaC patterns, auth/security patterns). The exact
skill names come from the active scopes — load whichever the constitution
maps to each scope.

- Frontend + `specs/[XXX]/mockups/` exists → load also `bolt-ui-mockups`
  SKILL.md and apply the "Mockup ingestion" described below.

## Mockup ingestion (if present)

Si el escenario incluye `frontend` y existe la carpeta
`specs/[XXX-feature-name]/mockups/`:

1. Leer `mockups/README.md` para obtener el índice de flujos, asunciones
   y estados maquetados (incluye los omitidos).
2. Leer `mockups/CHANGELOG.md` para conocer la última iteración y modo
   (`generate` / `refine`).
3. Para cada flujo identificado, listar los HTMLs presentes (`<flow>-
   <step>-<state>.html`) y enlazarlos desde `planning/plan.md` como
   **referencia visual** del componente correspondiente.
4. Mapear cada flujo → componentes de UI + endpoints backend que lo
   soportarán; reflejar este mapping en la sección "Bolt Breakdown" del
   plan (cada Bolt cita el / los HTMLs que materializa).
5. Si hay estados maquetados que el plan no contempla (p. ej. `loading`
   sin endpoint asíncrono asociado) → levantarlos como hallazgo en la
   sección "Risks and Mitigations".
6. Si el escenario incluye `frontend` y `mockups/` **no** existe → dejar
   un aviso al usuario sugiriendo invocar `bolt-mockup` antes de
   continuar (no abortar, pero advertir riesgo de re-trabajo).

## Design Gate — Penpot (if design-tool active)

Si el escenario incluye `frontend` y
`decisions.frontend.design-tool ∈ {penpot-local, penpot-remote}` en
`.boltf/scopes.yaml`:

1. Verificar que existe `specs/[XXX-feature-name]/design/penpot-validate.md`
   (producido por `bolt-penpot` en modo `validate`) y que aprueba los estados
   requeridos por pantalla (`default`, `empty`, `loading`, `error`, `success`).
2. ✅ Gate aprobado → continuar con el plan, citando el diseño Penpot como
   referencia visual (igual que la "Mockup ingestion").
3. ⛔ Falta el informe o hay estados sin cubrir → **advertir** y sugerir invocar
   `bolt-penpot` (validate) — o `bolt-mockup` para low-fi — antes de planear (no
   abortar, pero marcar el riesgo en "Risks and Mitigations").
4. Si `design-tool = none` → el gate no aplica; rigen los mockups HTML.

## Prerequisites

1. `specs/[XXX-feature-name]/requirements/requirements.md` exists.
2. `.boltf/memory/constitution.md` exists.
3. Must be on a feature branch (`feature/*`).

## Execution flow

### 0a. Detect scenario (MANDATORY FIRST)

Read `.boltf/memory/constitution.digest.md`, determine active scopes. Declare scenario:
`backend-only | frontend-only | infra-only | backend+frontend | fullstack`.

Adaptation rules:

- `backend-only` → omit UI sections; use the backend patterns skill from
  the constitution.
- `frontend-only` → omit API contracts, SQL DDL, CQRS; use the frontend
  patterns skill from the constitution.
- `infra-only` → omit domain model, API contracts, app tests; use the
  infra/IaC patterns skill from the constitution.
- `backend+frontend` → both backend & frontend; omit infra except local
  orchestration.
- `fullstack` → all relevant skills.

Document detected scenario at the top of the generated plan.

### 0b. Verify feature branch

```bash
BRANCH=$(git branch --show-current)
[[ "$BRANCH" =~ ^feature/ ]] || { echo "ERROR: Not on feature branch"; exit 1; }
```

### 1. Load context

Read:

- `.boltf/memory/constitution.md` → tech stack, principles, gates.
- `specs/[XXX-feature-name]/requirements/requirements.md` → FRs, NFRs, US.

### 2. Constitution compliance check

```markdown
## Constitution Check
| Principle | Status | Notes |
|-----------|--------|-------|
```

**STOP if critical violations found.** Request constitution amendment or
spec revision.

### 3. Technical context analysis

Document: stack selection, dependencies, integration points, unknown items
marked `NEEDS RESEARCH`.

### 4. Phase 0 — Research (delegación automática)

Para cada item marcado `NEEDS RESEARCH`:

1. Invocar automáticamente `bolt-researcher` con el contexto del item.
2. Esperar resultado.
3. Documentar decisión en `planning/research.md`.

Si bolt-researcher no puede resolver → marcar como BLOCKED y crear
GitHub Issue etiquetado `needs-research` con la pregunta específica:

```bash
gh issue create \
  --title "Research needed: [topic]" \
  --body "Context: [feature]. Question: [specific question]. Blocker for: plan Phase 0." \
  --label "needs-research"
```

Output `planning/research.md`.

### 5. Phase 1 — Data model design

**OMIT if scenario = `frontend-only` or `infra-only`.**

Produce `requirements/data-model.md` with entities, fields, relationships,
invariants, DDL.

### 6. Phase 2 — API contract design (contract-first)

**OMIT if scenario = `frontend-only` (sin BFF) or `infra-only`.**

Proceso contract-first derivado del data-model:

1. Leer `requirements/data-model.md` (generado en Phase 1).
2. Para cada entidad del modelo con exposición externa (marcada en data-model
   o inferida de los user stories):
   - Generar schema OpenAPI con campos, tipos y validaciones derivados del
     modelo.
   - Generar paths CRUD estándar (GET list, GET by id, POST, PUT, PATCH,
     DELETE) salvo que la spec indique lo contrario.
3. Para operaciones no-CRUD (commands, queries específicos):
   - Derivar del user story correspondiente.
   - Request schema = campos necesarios según AC.
   - Response schema = proyección de la entidad según lo que el AC espera ver.
4. **Validación**: todo campo del schema DEBE existir en data-model.md.
   Si no existe → error, volver a Phase 1 y ampliar el modelo.

Output: `contracts/openapi.yaml` — contrato ejecutable, no placeholder.

### 7. Phase 3 — Architecture design

Document component diagram, sequence diagrams for key flows, integration
architecture, error handling strategy.

### 8. Phase 4 — Bolt planning

Derive bolts from scenario. Guide table (adapt to the constitution's stack):

| Escenario | Bolts sugeridos |
|-----------|-----------------|
| `backend-only` | bolt-1-domain, bolt-2-application (handlers/use-cases), bolt-3-infrastructure (persistence/repos), bolt-4-api (endpoints + integration tests) |
| `frontend-only` | bolt-1-shell (routing/layout), bolt-2-components (UI), bolt-3-state (state mgmt/services), bolt-4-e2e (E2E tests) |
| `infra-only` | bolt-1-network, bolt-2-data, bolt-3-compute, bolt-4-pipeline (CI/CD + dry-run/what-if) |
| `backend+frontend` | combine relevant backend + frontend bolts |
| `fullstack` | combine all 3 + final integration bolt |

> Número y alcance de bolts varían por feature; adaptar según `plan.md`.

Each bolt branch convention: `feature/[feature-name]/bolt-[N]-[descripcion]`.

For each bolt document: objetivo, entregables, criterios de aceptación,
duración estimada.

⚠️ `bolt-implement` AUTO-CREATES branches following this pattern.

### 8b. Phase IaC (only if scenario includes `infra`)

Document the infrastructure modules and provisioning order in the IaC tool
declared by the constitution. Generic ordering:

| Module | Purpose | Dependencies |
|--------|---------|--------------|
| `networking` | Network, subnets, private endpoints | — |
| `secrets` | Secrets and certificates | networking |
| `data` | Databases / storage | networking, secrets |
| `compute` | App/container hosting | networking, secrets |
| `config` | Application configuration | secrets |
| `monitoring` | Telemetry + logs | — |

Validate each module with the IaC tool's dry-run / plan / what-if before a
real deploy.

## Output — `planning/plan.md` (full skeleton)

```markdown
# Implementation Plan: [Feature Name]

## Overview
| Property | Value |
|----------|-------|
| Feature | [name] |
| Estimated Duration | [X] days |
| Bolts | [N] |
| Priority | [P1/P2/P3] |
| Scenario | [detected scenario] |

## Constitution Alignment

| Principle | Status | Notes |
|-----------|--------|-------|
| [Principle 1] | ✓ PASS / ✗ FAIL | [Notes] |

## Technical Context

### Stack Selection (from Constitution)
- Frontend: [FRAMEWORK] + [LANGUAGE]
- Backend: [FRAMEWORK] + [LANGUAGE]
- Database: [DATABASE]
- Infrastructure: [CLOUD] + [IAC]

### Dependencies
- [Library 1]: [Version] — [Purpose]
- [Library 2]: [Version] — [Purpose]

### Integration Points
- [System 1]: [Protocol] — [Purpose]

## Data Model Summary
[Link to `requirements/data-model.md`]

## API Summary
[Link to `contracts/openapi.yaml`]

## Bolt Breakdown

### Bolt 1: [Name]
- **Goal**: ...
- **Deliverables**: ...
- **Acceptance criteria**: ...
- **Estimated duration**: 1-3 days
- **Branch**: `feature/[feature-name]/bolt-1-[description]`

### Bolt N: ...

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk] | H/M/L | H/M/L | [Strategy] |
| Flujos sin cobertura BDD | [?] | M | bolt-tasks verificará en reconciliación |

## Dependencies
- [External dependency]
- [Team dependency]

## Next Steps
1. Use bolt-tasks to generate detailed task list (reconciles with gherkin)
2. Begin Bolt 1 implementation with bolt-implement
```

## Output — `planning/research.md` (skeleton per NEEDS RESEARCH item)

```markdown
# Technical Research

## [Topic 1]

### Decision
[What was chosen]

### Rationale
[Why chosen]

### Alternatives Considered
- [Alternative 1]: [Pros / Cons]
- [Alternative 2]: [Pros / Cons]

### Risks
- [Risk]: [Mitigation]
```

## Output — `contracts/openapi.yaml`

```yaml
openapi: 3.0.3
info:
  title: [Feature] API
  version: 1.0.0
  description: Contract-first API derived from data-model.md
paths:
  /api/[resource]:
    get:
      summary: List [resources]
      operationId: list[Resources]
      tags: [[Resource]]
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/[Resource]Response'
    post:
      summary: Create [resource]
      operationId: create[Resource]
      tags: [[Resource]]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/[Resource]Request'
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/[Resource]Response'
  /api/[resource]/{id}:
    get:
      summary: Get [resource] by ID
      operationId: get[Resource]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Success
        '404':
          description: Not found
components:
  schemas:
    [Resource]Request:
      type: object
      required: [field1]
      properties:
        field1:
          type: string
    [Resource]Response:
      type: object
      properties:
        id:
          type: string
          format: uuid
        field1:
          type: string
```

## Output — `requirements/data-model.md` (template)

````markdown
# Data Model

## Entities

### [Entity Name]

| Field | Type | Required | Constraints | Exposed (API) |
|-------|------|----------|-------------|---------------|
| id | UUID | Yes | Primary Key | Yes |
| [field] | [type] | [yes/no] | [constraints] | [Yes/No] |

**Relationships**:
- Has many [Related Entity]
- Belongs to [Parent Entity]

**Invariants**:
- [Business rule that must always be true]

## Database Schema

```sql
CREATE TABLE [table_name] (
  id UUID PRIMARY KEY,
  ...
);
```
````

## Work Management sync

Gestión mínima obligatoria: registrar el plan como comentario/sub-item bajo
el ticket de la feature en el tracker activo (detectado desde
`.boltf/memory/constitution.md`, sección `work-management`).

**GitHub Issues** (default):

```bash
gh issue comment [FEATURE_ISSUE] \
  --body "Plan generated: specs/[XXX]/planning/plan.md | Bolts: [N] | Duration: [X] days"
```

**Jira**:

```bash
jira issue comment [FEATURE_ISSUE] \
  --body "Plan generated: specs/[XXX]/planning/plan.md | Bolts: [N] | Duration: [X] days"
```

**Azure DevOps Boards**:

```bash
az boards work-item update --id [FEATURE_WORKITEM] \
  --discussion "Plan generated: specs/[XXX]/planning/plan.md | Bolts: [N] | Duration: [X] days"
```

Si el tracker asigna un ID propio al comentario/sub-item (Jira sub-task,
Azure DevOps child work-item), **registrarlo en `planning/plan.md`** bajo
la sección `Overview` añadiendo una fila:

```markdown
| Plan tracker ref | <tracker-prefix><id> (ej. gh#43, jira-CART-43, ado#118) |
```

Si `work-management` scope está configurado en constitution → delegar sync
completa al agente de sincronización de work-management configurado.

## Quality gates

- Plan documents detected scenario explicitly.
- Constitution check has no critical violations (or amendment requested).
- All `NEEDS RESEARCH` items resolved with rationale in `research.md`.
- OpenAPI schemas traceable 1:1 to data-model entities (no orphan fields).

## Related agents (next steps)

- → `bolt-tasks`: break the plan into actionable tasks (reconciles with gherkin).
- → `bolt-analyze`: review architecture and consistency.
- → `bolt-architect`: deep architecture/ADR work if needed.
- → `bolt-implement`: execute Bolt micro-iterations.

## References

- `.github/prompts/bolt-architecture.prompt.md`
- `.github/prompts/bolt-planning.prompt.md`
