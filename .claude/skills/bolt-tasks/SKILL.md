---
name: bolt-tasks
description: "Generate actionable Bolt task lists from an implementation plan, reconciling with BDD scenarios, auto-splitting by weight heuristic, and mapping user stories to Bolts (2-3 day micro-iterations) with mandatory per-Bolt quality gates (linting, coverage ≥ 80%, mutation ≥ 70%). Produces `planning/tasks.md`. Triggers: 'generate tasks', 'break plan into tasks', 'task breakdown', 'bolt tasks', 'task list from plan', 'PLAN → EXECUTE preparation', '/bolt-tasks'."
---

# Bolt Tasks — Methodology

Transform an implementation plan into executable Bolt task lists following
the AI-DLC methodology. Reconcile plan with BDD scenarios to ensure full
coverage.

**Bolt Framework Stage**: PLAN → EXECUTE preparation
**Responsible Agent**: Bolt Executor (bolt-implement)

## Referenced skills

- `skill-bolt-quality-gates` — canonical gate definitions.
- `skill-bolt-testing-discipline` — TDD/BDD decision guidance.

## Prerequisites

Required in `specs/[XXX-feature-name]/`:

- `requirements/requirements.md` — Feature specification.
- `planning/plan.md` — Implementation plan (from bolt-plan).

Optional (enhance task generation):

- `specs/[XXX]/tests/*.feature` — Gherkin scenarios (from bolt-gherkin).
- `requirements/data-model.md` — Entity definitions.
- `contracts/` — API specifications.
- `planning/research.md` — Technical decisions.

## Available scripts

- Bash: `scripts/bash/check-prerequisites.sh`
- PowerShell: `scripts/powershell/Check-Prerequisites.ps1`

## Bolt concept

A **Bolt** is a micro-iteration of 2-3 days that produces:

- Complete, tested code increment.
- Independently deployable (when possible).
- Validated against acceptance criteria.

## Execution flow

### 1. Load context

Read from `specs/[XXX-feature-name]/`:

- `planning/plan.md` → Extract Bolts, tech stack, file structure.
- `requirements/requirements.md` → Extract user stories with priorities.
- `tests/*.feature` → BDD scenarios (si existen).
- `requirements/data-model.md` → Entities (if exists).
- `contracts/` → API endpoints (if exists).

### 2. Reconciliation plan ↔ gherkin

**MANDATORY when `specs/[XXX]/tests/*.feature` exists.**

Inputs:

- `planning/plan.md` → Bolts, endpoints, componentes planificados.
- `specs/[XXX]/tests/*.feature` → Scenarios BDD generados por bolt-gherkin.

Proceso:

1. Para cada endpoint/componente del plan:
   - Verificar que existe ≥1 scenario en los .feature files que lo cubra.
   - Si NO existe → crear tarea explícita: "Añadir scenario BDD para [X]"
     (asignar al Bolt correspondiente).
2. Para cada scenario `@smoke` de los .feature files:
   - Verificar que el plan contempla la implementación que lo sirve.
   - Si NO existe → WARNING: "Scenario [X] no tiene implementación planificada".
   - Decidir: ampliar plan (crear tarea extra) o marcar scenario como
     out-of-scope con justificación.
3. Documentar gaps al inicio de `tasks.md`:

```markdown
## Reconciliación plan ↔ gherkin

### Gaps detectados
- [endpoint/componente] sin cobertura BDD → Tarea T00X añadida en Bolt N
- [Scenario "X"] sin implementación planificada → [decisión tomada]

### Cobertura
- Endpoints planificados: [N] | Con BDD: [M] | Gap: [N-M]
- Scenarios @smoke: [S] | Con implementación: [T] | Gap: [S-T]
```

Si no existen .feature files, documentar: "Gherkin no generado para esta
feature. Cobertura BDD será responsabilidad de bolt-testing post-implement."

### 3. Map user stories to bolts

Organize tasks by user story priority:

```text
US-001 (P1) → Bolt 1, Bolt 2
US-002 (P2) → Bolt 3
US-003 (P3) → Bolt 4
```

### 4. Bolt sizing validation (MANDATORY)

Asignar peso a cada tarea:

| Peso | Criterio | Ejemplos |
|------|----------|----------|
| **S** (Small) | < 2h | Config, boilerplate, single-file change, DTO |
| **M** (Medium) | 2-4h | New class/component, migration, integration point |
| **L** (Large) | 4-8h | New bounded context, complex algorithm, multi-file refactor |

Formato de tarea con peso:

```markdown
- [ ] T001 [S] Initialize project structure
- [ ] T002 [M] Implement repository for the core aggregate
- [ ] T003 [L] Implement command/handler pipeline
```

**Reglas de auto-split:**

- Si un Bolt tiene **>3 tareas L** → dividir automáticamente.
- Si un Bolt tiene **>8 tareas totales** → dividir automáticamente.
- Si un Bolt tiene **peso total > 5L equivalentes** → dividir.
  - Conversión: S = 0.25L, M = 0.5L, L = 1L.

Al dividir:

1. Respetar dependencias (no separar tareas que dependen entre sí).
2. Mantener coherencia funcional (un Bolt = un entregable verificable).
3. Renumerar Bolts afectados.
4. Documentar: "Bolt N original dividido en Bolt N + Bolt N+1. Razón: [peso excedido]".

**Validación contra velocity histórica:**

Si existe sección `## Velocity` en un tasks.md previo del mismo proyecto:

- Comparar peso planificado vs. velocity real.
- Si velocity media < 70% de lo planificado en 2+ Bolts anteriores:
  sugerir al usuario recalibrar sizing.

### 5. Tareas de step definitions (backend/fullstack)

**Aplica cuando bolt-gherkin ha generado stubs de step definitions BDD.**

Para cada `.feature` que tiene stubs de step definitions (en la ubicación
que use el framework de BDD del stack, p. ej.
`tests/[Module]/StepDefinitions/[Feature]Steps.*`):

- Crear tarea: "Implementar step definitions de [Feature]"
- Asignar al Bolt que implementa la funcionalidad correspondiente.
- Peso: **M** (los stubs ya existen, solo hay que rellenar el body).
- La tarea se ubica DESPUÉS de la implementación del código productivo
  y ANTES de los quality gates del Bolt.

### 6. Generate `planning/tasks.md`

Task format: `- [ ] [TaskID] [Size] [P?] [Story?] Description with file path`

- `[TaskID]`: sequential (T001, T002…).
- `[Size]`: S, M, or L (mandatory).
- `[P]`: parallelizable (optional).
- `[Story]`: user story reference (optional).

Per-bolt sections: Setup / Foundation / Model / Service / Infrastructure /
API / Step Definitions / Test / Quality Gates.

## Quality Gates per BOLT (MANDATORY)

⚠️ **CRITICAL**: These tasks MUST be generated for EVERY BOLT, not just as a
final checklist. Quality gates are trackeable tasks with IDs
(e.g. T023-QG, T024-QG).

| Task ID Pattern | Description | Command | Threshold |
|-----------------|-------------|---------|-----------|
| TXX-QG | Run linting | `npm run lint` / `dotnet format` | 0 errors |
| TXX-QG | Run all tests | `npm test` / `dotnet test` | 100 % pass |
| TXX-QG | Run coverage report | `npm run test:cov` | Generate report |
| TXX-QG | Verify line coverage | Check report | ≥ 80 % |
| TXX-QG | Verify branch coverage | Check report | ≥ 75 % |
| TXX-QG | Run mutation tests (Bolt-scope) | `dotnet stryker --project <Svc>.Application.csproj --project <Svc>.Domain.csproj` / `npx stryker run --mutate "src/app/features/<name>/**/*.ts"` | Generate report |
| TXX-QG | Verify mutation score | Check report | ≥ 70 % |
| TXX-QG-E2E | **[frontend/fullstack]** Generar stub `.spec.ts` en `src/frontend/e2e/tests/<feature>/` | crear archivo (puede ser stub que falle) | archivo existe |
| TXX-QG-E2E | **[frontend/fullstack]** Run E2E Playwright smoke | `npx playwright test --grep @smoke` | 0 failures, ≥1 test |

> ⚠️ **Regla**: En bolts de escenario `frontend-only` o `fullstack`, los tasks TXX-QG-E2E son
> **OBLIGATORIOS**. Si `npx playwright test --grep @smoke` devuelve 0 tests → FALLO de gate
> (no silencioso). Los `.feature` en `specs/` son documentación BDD; los `.spec.ts` en
> `src/frontend/e2e/tests/` son los tests ejecutables.

### Mutation testing setup (first BOLT only)

Node/TypeScript:

```bash
npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner @stryker-mutator/typescript-checker
npx stryker init
# Bolt-scope invocation (default):
npx stryker run --mutate "src/app/features/<feature-name>/**/*.ts"
# Full-scope (release gate only):
npx stryker run
```

.NET:

```bash
dotnet tool install -g dotnet-stryker
dotnet stryker init
# Bolt-scope invocation (default — auto-detected from branch):
dotnet stryker --project <Svc>.Application.csproj --project <Svc>.Domain.csproj
# Feature-scope (PR gate):
dotnet stryker --project <Svc>.Application.csproj --project <Svc>.Domain.csproj --project <Svc>.Api.csproj
# Full-scope (release gate only):
dotnet stryker
```

> ℹ️ **Scoped execution is the default** at Bolt-close. Scripts `Quality-Gates.ps1 -BoltScope <Svc>` /
> `quality-gates.sh --bolt-scope <svc>` auto-detect scope from the git branch. Full-solution
> runs (`dotnet stryker` / `npx stryker run` without scope) are reserved for release gates.

### Quality gate failure policy

- Coverage < 80 % → BOLT cannot be marked complete.
- Mutation score < 70 % → tests need improvement before proceeding.
- Any test failure → fix before next task.
- **E2E (frontend/fullstack)**: 0 tests ejecutables en `src/frontend/e2e/tests/` → BOLT no puede cerrarse.

## Progress tracking

| Bolt | Tasks | Weight (L-equiv) | Completed | Status |
|------|-------|-------------------|-----------|--------|
| Bolt 1 | [N] | [X.XX] | 0 | ⬜ Not Started |
| Bolt 2 | [N] | [X.XX] | 0 | ⬜ Not Started |

**Total Progress**: 0 / [Total] tasks (0 %).

## Work Management sync

Gestión mínima obligatoria: actualizar GitHub Issue de la feature con link a
`tasks.md` generado.

Si `work-management` scope está configurado en constitution → delegar sync
completa (Azure DevOps/Jira) a `bolt-az-devops-sync`.

## Output summary

```markdown
## Task List Generated
**Feature**: [XXX-feature-name]
**File**: specs/[XXX]/planning/tasks.md
**Summary**:
- Total Bolts: [N]
- Total Tasks: [N]
- Weight distribution: [X]S + [Y]M + [Z]L = [W]L equivalent
- Auto-splits applied: [N or "None"]
- Reconciliation gaps: [N or "None"]
- Estimated Duration: [X] days
**Next Steps**:
1. Review task breakdown
2. Use bolt-analyze to validate consistency
3. Use bolt-implement to start Bolt 1
```

## Related agents (next steps)

- → `bolt-analyze`: validate consistency across artifacts.
- → `bolt-implement`: start executing Bolt 1.
- → `skill-bolt-quality-gates`: reuse the canonical quality gates definition.

## References

- `.github/prompts/bolt-planning.prompt.md`
