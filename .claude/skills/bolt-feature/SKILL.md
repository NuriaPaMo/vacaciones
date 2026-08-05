---
name: bolt-feature
description: "Create comprehensive Bolt Framework feature specifications (requirements.md) with user stories, use cases, acceptance criteria classified as `@smoke`, GitHub Issue creation (mandatory), and optional Work Management Tool sync. Auto-creates feature branch via `create-new-feature` script after user confirmation. Triggers: 'create feature', 'new feature spec', 'feature specification', 'user story spec', 'product owner workflow', '/bolt-feature'."
---

# Bolt Feature — Methodology

## When to use

- INCEPTION / DISCOVERY phase: turn a business idea into a complete feature
  specification before planning.
- Whenever a new bounded context, epic or major feature kicks off.

## Scenario detection (MANDATORY before generating the spec)

Read `.boltf/memory/constitution.digest.md` and declare the scenario explicitly:
`backend-only | frontend-only | infra-only | backend+frontend | fullstack`.

Template adaptation:

- `backend-only` → omit UI/UX & mockups; use system actors (Scheduler, Daemon).
- `frontend-only` → omit SQL DDL, API contract & relational entities; suggest
  UI components from the project's design system.
- `infra-only` → replace `Key Entities` with `Recursos Cloud`; add `SLOs`
  section (uptime, RTO, RPO); omit UI / business-domain user stories.
- `backend+frontend` / `fullstack` → full template.

## Available scripts

- Bash: `scripts/bash/create-new-feature.sh`
- PowerShell: `scripts/powershell/Create-NewFeature.ps1`

## Branch creation (with confirmation)

1. Extract feature name from user request:
   - "create user authentication feature" → `user-authentication`
   - "add shopping cart functionality" → `shopping-cart`
2. **Validar duplicados** antes de crear:

   ```bash
   ls specs/ | grep -i "[feature-name-slug]"
   ```

   Si existe un spec con nombre similar → STOP y preguntar al usuario si
   quiere actualizar el existente o crear uno nuevo.
3. **Confirmar nombre** con el usuario:
   "Voy a crear `feature/[name]` con spec en `specs/[XXX-name]/`. ¿Correcto?"
4. Si confirma → ejecutar script:

   ```bash
   ./.boltf/scripts/bash/create-new-feature.sh "[feature-name]" "main"
   ```

5. Si corrige → usar el nombre corregido.
6. Inform user: branch + directory created, switched to feature branch.
7. Continue with specification creation.

Razón del cambio: un nombre mal inferido arrastra todo el pipeline
(branches, directorios, issues). Confirmar cuesta 5 segundos; corregir
post-facto cuesta horas.

## Issue / Workitem creation (MANDATORY)

Independientemente del tracker configurado, **toda feature debe tener un
ticket asociado** en el issue tracker activo. Detecta el tracker desde
`.boltf/memory/constitution.md` (sección `work-management`) y usa el comando
correspondiente:

**GitHub Issues** (default):

```bash
gh issue create \
  --title "Feature: [Feature name]" \
  --body "Spec: specs/[XXX]/requirements/requirements.md" \
  --label "feature"
```

**Jira**:

```bash
jira issue create \
  --project [PROJ] \
  --type Story \
  --summary "Feature: [Feature name]" \
  --body "Spec: specs/[XXX]/requirements/requirements.md"
```

**Azure DevOps Boards**:

```bash
az boards work-item create \
  --title "Feature: [Feature name]" \
  --type Feature \
  --description "Spec: specs/[XXX]/requirements/requirements.md"
```

**Registrar el ID en el spec** (`specs/[XXX]/requirements/requirements.md`,
campo `Issue` de Metadata) con el prefijo del tracker:

| Tracker | Prefijo | Ejemplo |
|---|---|---|
| GitHub Issues | `gh#` | `gh#42` |
| Jira | `jira-<PROJECT>-` | `jira-CART-42` |
| Azure DevOps | `ado#` | `ado#42` |

Si hay sincronización cruzada (p. ej. GitHub ↔ Azure DevOps) → delegar a
`bolt-az-devops-sync` y registrar **ambos** IDs separados por ` / `
(ej. `gh#42 / ado#117`).

## Constitution check

After creating the branch, read `.boltf/memory/constitution.digest.md` to understand:

- Project domain and context.
- Tech stack constraints.
- Documentation standards.
- Compliance requirements.

## Execution flow

### Step 1 — Create feature branch (with confirmation, see above)

### Step 2 — Gather feature context

Extract from user input:

- Feature name/identifier.
- Business problem being solved.
- Target users/personas.
- Expected business value.

### Step 3 — Generate feature specification

Create `specs/[XXX-feature-name]/requirements/requirements.md` using this
template:

```markdown
# Feature: [Feature Name]

## Metadata

| Property | Value |
|----------|-------|
| Feature ID | F-[XXX] |
| Issue | <tracker-prefix><id> (e.g. gh#42, jira-CART-42, ado#42) |
| Author | [author] |
| Created | [date] |
| Status | Draft |
| Priority | P1/P2/P3 |
| Epic | [parent epic if any] |

## Business Context

### Problem Statement
### Business Value
### Target Users

| Persona | Description | Goals |
|---------|-------------|-------|

## User Stories

### US-001: [Story Title]

**As a** [role]
**I want** [capability]
**So that** [benefit]

**Priority**: P1
**Effort**: M
**Dependencies**: None

#### Acceptance Criteria

| ID | Criterion | Type | Smoke |
|----|-----------|------|-------|
| AC-001.1 | [Given/When/Then or declarative] | Functional | @smoke |
| AC-001.2 | [Criterion] | Functional | — |
| AC-001.3 | [Performance requirement] | Non-Functional | — |

#### Business Rules

- BR-001: [Business rule that applies]
```

### Step 4 — Smoke scenario classification (MANDATORY)

For every AC, evaluate `@smoke` using the matrix from the
`bolt-smoke-testing` skill. Quick reference:

| Marca `@smoke` | No marca `@smoke` |
|---|---|
| Happy path con resultado positivo | Casos de error y validación |
| Primera acción del bounded context | Bordes y edge cases |
| Flujo de autorización principal | Tests lentos o con setup complejo |
| Integración crítica entre servicios | Funcionalidades secundarias |

**Rule**: every P1 user story MUST have at least one AC marked `@smoke`.
Aim for 20-50 % of ACs marked smoke per US.

### Step 5 — Constitution alignment check

- [ ] Tech stack compatible
- [ ] Architecture principles followed
- [ ] Security requirements addressed
- [ ] Quality gates defined
- [ ] No constitution violations
- [ ] Smoke scenarios classified in all User Stories

### Step 6 — Work Management sync

Gestión mínima obligatoria: el GitHub Issue ya fue creado en el paso
"Issue creation".

Si `work-management` scope está configurado en constitution → delegar
sync completa (Azure DevOps/Jira) a `bolt-az-devops-sync`.

## Non-Functional Requirements template (literal)

Include these tables verbatim in the spec, omitting rows that don't apply
to the detected scenario.

### Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Response time P99 | < 500 ms | API response time |
| Throughput | 100 req/s | Peak load handling |

### Security

- [ ] Authentication required (specify method from constitution)
- [ ] Authorization rules defined
- [ ] Data encryption (at rest / in transit)
- [ ] Audit logging required

### Scalability

- Expected concurrent users: [X]
- Data growth rate: [X records / month]

### Availability

- Target uptime: 99.9 %
- Maintenance window: [schedule]

## Data Requirements

### New Entities

| Entity | Description | Key Fields |
|--------|-------------|------------|
| [Entity1] | [Purpose] | id, name, ... |

### Modified Entities

| Entity | Changes | Impact |
|--------|---------|--------|
| [Entity1] | [What changes] | [Other systems affected] |

## Integration Points

| System | Direction | Protocol | Purpose |
|--------|-----------|----------|---------|
| [System1] | Inbound / Outbound | REST / Event | [What data] |

## Out of Scope / Dependencies / Open Questions

Append to the spec:

- **Out of Scope**: explicitly excluded items.
- **Dependencies**: external systems / teams.
- **Open Questions**: items needing clarification (delegate to
  `bolt-clarify`).

## Mockup Generation (scenarios with `frontend`)

Si el escenario detectado contiene `frontend` (`frontend-only`,
`backend+frontend`, `fullstack`), tras generar `requirements.md`
**sugiere explícitamente** al usuario invocar el agente `bolt-mockup`
antes de pasar a `bolt-plan`:

- Los mockups validan flujos, contenido y estados con stakeholders ANTES
  de escribir el plan técnico, evitando re-trabajo durante la
  construcción.
- Output esperado: `specs/[XXX-feature-name]/mockups/<flow>-<step>-<state>.html`
  - `README.md` + `CHANGELOG.md` (ver skill `bolt-ui-mockups`).
- Si el escenario es `backend-only` o `infra-only` → no sugerir mockups.

Ejemplo de cierre de la spec cuando hay frontend:

```text
Spec generada en `specs/123-foo/`. Escenario detectado: backend+frontend.
Issue: #42
Siguiente paso recomendado:
  1. Invocar `bolt-mockup` (modo generate) para producir wireframes
     low-fi y validarlos con negocio.
  2. Iterar con `bolt-mockup` (modo refine) hasta acuerdo.
  3. Después → `bolt-plan` + `bolt-gherkin` (en paralelo).
```

## Quality gates

- requirements.md exists with all sections filled.
- Smoke classification complete.
- GitHub Issue created and referenced in Metadata.
- Work item created or step skipped explicitly.

## Related agents (next steps)

- → `bolt-mockup` (si escenario incluye `frontend`): generar mockups
  low-fi en `specs/[XXX]/mockups/` antes del plan.
- → `bolt-usecase`: generate detailed use cases from the feature.
- → `bolt-plan` + `bolt-gherkin` (en paralelo): plan técnico + BDD scenarios.
- → `bolt-clarify`: resolve ambiguities before planning.
- → `bolt-implement`: implement the feature spec.

## Referenced skills (conditional)

- `bolt-ui-mockups` (cuando el escenario incluye `frontend` y el usuario
  decide invocar `bolt-mockup` en este paso).
- `bolt-framework`, `markdown-formatting` (siempre).

## References

- `.github/prompts/bolt-business-analysis.prompt.md` — detailed business
  analysis guidance.
