---
name: bolt-implement
description: "Execute Bolt implementation following the task list with AI-DLC quality gates, micro-iteration branch discipline (`feature/[name]/bolt-[N]-[desc]`), lifecycle management (states, velocity tracking), and feedback loops (gate escalation, AC revision). Auto-detects scenario (backend/frontend/infra) and loads relevant patterns. Triggers: 'implement bolt', 'execute bolt', 'code the bolt', 'CONSTRUCTION phase', 'bolt N implementation', 'start coding', 'next bolt', 'micro-iteration', '/bolt-implement'."
---

# Bolt Implement — Methodology

Execute implementation following Bolt structure with quality gates, lifecycle
management, and feedback loops at each step.

**Bolt Framework Stage**: EXECUTE
**Responsible Agent**: Bolt Executor (absorbs former Micro Iterator role)

## Referenced skills

- `skill-bolt-branch-management` — BOLT branching pattern and feature branch
  verification.
- `skill-bolt-quality-gates` — linting, coverage, and mutation testing
  thresholds.
- `skill-bolt-testing-discipline` — TDD/BDD decision guidance.

### Conditional skill loading (per detected scenario)

Carga las skills de patrones técnicos que correspondan al stack declarado en
`.boltf/memory/constitution.md`. Las referencias concretas dependen del stack del
proyecto:

- **Backend** → skill de patrones de backend del stack (capas, repositorios,
  CQRS si aplica).
- **Frontend** → skill de patrones de frontend del stack + `playwright-e2e`.
  - Por cada componente nuevo que implemente un flujo de usuario visible,
    generar el test E2E correspondiente bajo `e2e/tests/<feature>/<component>.spec.ts`.
  - Si no existe todavía la implementación, generar un stub ejecutable que
    falle con `test.fail('TODO: implement E2E test')` para que el quality
    gate no sea silencioso.
- **Fullstack** → skills de patrones backend + frontend + `playwright-e2e`.
- **Infra** → skill de IaC/DevOps del stack antes de modificar infraestructura
  (provisioning, Bicep/Terraform).
- **Auth** → skill de patrones de seguridad/autenticación del stack.
- **Persistencia SQL** → inspeccionar el esquema real con las tools de base de
  datos disponibles antes de escribir migraciones (do NOT invent table
  structures).

## Scenario detection (MANDATORY before implementing)

Read `.boltf/memory/constitution.digest.md` and declare:
`backend-only | frontend-only | infra-only | backend+frontend | fullstack`.

Use the scenario to decide which layers to touch and which skills to load.

## Bolt lifecycle

### States

| State | Meaning | Action |
|-------|---------|--------|
| **Planned** | Tasks defined in tasks.md | Start Build |
| **In Progress** | Work ongoing | Continue tasks |
| **Complete** | All done + gates pass | Merge to feature branch |
| **Blocked** | Cannot proceed | Resolve blocker / escalate |
| **At Risk** | Behind schedule | Reduce scope (re-split) |

### Velocity tracking

Al cerrar cada Bolt, registrar en `planning/tasks.md`:

```markdown
## Velocity

| Bolt | Planned | Completed | Days | Notes |
|------|---------|-----------|------|-------|
| B-01 | 5 tasks | 5 tasks | 2 | On track |
| B-02 | 6 tasks | 4 tasks | 3 | Scope reduced |
```

Usar velocity histórica para validar sizing de Bolts futuros. Si la
velocity media es inferior al 70% de lo planificado en 2+ Bolts consecutivos,
sugerir al usuario recalibrar el sizing en bolt-tasks.

## MANDATORY: BOLT branch management

**Before implementing any BOLT, automatically create a dedicated branch.**

### Verify current branch

```bash
git branch --show-current
# Expected: feature/[feature-name]
# If on main/develop → STOP and create feature branch first
```

### Auto-create BOLT branch

```bash
# Pattern: feature/[feature-name]/bolt-[N]-[description]
CURRENT_BRANCH=$(git branch --show-current)
git checkout -b "${CURRENT_BRANCH}/bolt-[N]-[description]"
```

### Implementation rules

- Each BOLT = new branch (mandatory).
- Complete BOLT before merge to feature branch.
- Incremental PRs for review.
- Quality gates on each BOLT branch.

If NOT on a feature branch:

1. STOP — do not implement on main/develop.
2. Create feature branch:
   `./.boltf/scripts/bash/create-new-feature.sh "[feature-name]"`.
3. Then create BOLT branch following the pattern above.

## Issue / Workitem tracking por Bolt

Si la feature tiene >1 Bolt, crear un ticket por Bolt en el tracker activo
(detectado desde `.boltf/memory/constitution.md`, sección `work-management`).

**GitHub Issues** (default):

```bash
gh issue create \
  --title "Bolt [N]: [goal]" \
  --body "Branch: feature/[name]/bolt-[N]-[desc]" \
  --label "bolt"

# Al cerrar:
gh issue close [BOLT_ISSUE] --comment "Merged. Gates: PASS"
```

**Jira**:

```bash
jira issue create \
  --project [PROJ] \
  --type Sub-task \
  --parent [FEATURE_ISSUE] \
  --summary "Bolt [N]: [goal]" \
  --body "Branch: feature/[name]/bolt-[N]-[desc]"

# Al cerrar:
jira issue move [BOLT_ISSUE] "Done" --comment "Merged. Gates: PASS"
```

**Azure DevOps Boards**:

```bash
az boards work-item create \
  --title "Bolt [N]: [goal]" \
  --type Task \
  --description "Branch: feature/[name]/bolt-[N]-[desc]"

# Vincular como hijo del feature work-item:
az boards work-item relation add \
  --id [BOLT_WORKITEM] \
  --relation-type parent \
  --target-id [FEATURE_WORKITEM]

# Al cerrar:
az boards work-item update --id [BOLT_WORKITEM] \
  --state "Closed" \
  --discussion "Merged. Gates: PASS"
```

**Registrar el ID en `planning/tasks.md`** bajo la cabecera del Bolt
correspondiente, usando el prefijo del tracker:

```markdown
## Bolt [N] — [goal]
**Tracker**: gh#43 | jira-CART-43 | ado#118
**Branch**: feature/[name]/bolt-[N]-[desc]
```

Si hay sincronización cruzada (p. ej. GitHub ↔ Azure DevOps) → registrar
**ambos** IDs separados por ` / ` (ej. `gh#43 / ado#118`) y delegar la
sync a `bolt-az-devops-sync`.

Si la feature tiene 1 solo Bolt: el issue/workitem de la feature es
suficiente; no crear ticket adicional.

## Available scripts

- Bash: `scripts/bash/quality-gates.sh`
- PowerShell: `scripts/powershell/Quality-Gates.ps1`

## Prerequisites

Required in `specs/[XXX-feature-name]/`:

- `planning/tasks.md`
- `planning/plan.md`
- `requirements/requirements.md`

Required in project root: `.boltf/memory/constitution.md`.

## Execution flow

### 0. Verify branch (mandatory)

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ ! "$CURRENT_BRANCH" =~ ^feature/ ]]; then
    echo "ERROR: Not on a feature branch!"
    exit 1
fi
```

### 0b. Infra delegation (when scenario includes infra)

Si el escenario detectado incluye `infra` o `infra-only`, **delegar la
implementación de IaC al subagente `bolt-infra`** (que carga las skills de
IaC/DevOps del stack). Razón: ese agente está optimizado para provisioning
(Bicep/Terraform) con `what-if` y validación de capacidad. bolt-implement
gestiona código de aplicación.

### 0c. Mockup reference (when scenario includes frontend)

Si `specs/[XXX]/mockups/` existe y el bolt actual es de frontend:

1. Leer la pantalla del mockup correspondiente al bolt (por naming
   `<flow>-<step>-<state>.html` o por el README de mockups).
2. Extraer anotaciones `<!-- @annotation: ... -->`, `<!-- @state: ... -->`,
   `<!-- @validation: ... -->` y trasladarlas a TODOs/comments del
   componente de UI generado.
3. Respetar jerarquía y estados visibles; **no inventar** componentes que el
   mockup no muestra; **no omitir** los que sí están.
4. Si el mockup parece inconsistente con `feature.md` → registrar en
   `Notes` del bolt y proponer invocar `bolt-mockup` (modo refine) antes de
   continuar.

### 1. Load context

```bash
cat .boltf/memory/constitution.digest.md
cat specs/[XXX-feature-name]/planning/tasks.md
ls specs/[XXX-feature-name]/contracts/
```

### 2. Build phase (core work)

Para cada tarea del Bolt actual:

1. Write test (if TDD — per `skill-bolt-testing-discipline`).
2. Write code.
3. Run tests.
4. Refactor if needed.
5. Mark task complete in `tasks.md`.

### 3. Update progress

After completing tasks, update `tasks.md`:

```markdown
- [x] T001 [S] Initialize project structure
- [x] T002 [S] Configure linting
- [ ] T003 [M] Set up CI/CD pipeline <- Current
```

### 4. Work Management sync

Gestionar GitHub Issue del Bolt directamente (estado + commit SHA).
Si `work-management` scope está configurado en constitution → delegar sync
completa (Azure DevOps/Jira) a `bolt-az-devops-sync`.

## OBLIGATORIO: Verificación de regresiones post-Bolt

**Antes de mergear a la feature branch**, ejecutar la suite de tests afectados y comparar contra
la baseline para garantizar que no hay regresiones introducidas por el Bolt.

### Backend (PowerShell)

```powershell
# Ejecutar suite completa del servicio afectado
dotnet test Backend.sln --logger "console;verbosity=minimal" 2>&1 |
  Tee-Object -FilePath test-output\test-run-bolt-check.txt

# Contar suites con error en baseline vs ejecución actual
$baseline = (Get-Content test-output\test-run-latest.txt |
               Select-String "^Con error!").Count
$current  = (Get-Content test-output\test-run-bolt-check.txt |
               Select-String "^Con error!").Count

if ($current -gt $baseline) {
    Write-Error "REGRESIÓN DETECTADA: $current suites con error vs $baseline en baseline. BLOQUEAR merge."
}
```

### Frontend

```bash
npm test --run 2>&1 | tee test-output/test-run-bolt-check-frontend.txt
```

### Tabla de decisión

| Resultado               | Acción                                                     |
|-------------------------|------------------------------------------------------------|
| Sin nuevos fallos       | ✅ Proceder con merge                                      |
| Nuevos fallos detectados | 🔴 STOP — corregir antes de merge                         |
| Tests eliminados        | ⚠️ Verificar si es intencional; documentar en el Bolt     |

### Protocolo si se detectan regresiones

1. **STOP** — no ejecutar el merge.
2. Actualizar estado del Bolt a `Blocked` en `tasks.md`.
3. Abrir GitHub Issue:

   ```bash
   gh issue create \
     --title "Regresión detectada en Bolt-[N] de [feature]: [descripción corta]" \
     --body "Tests fallidos: [lista]. Introducidos por cambios en [archivos]." \
     --label "regression,bolt-blocked"
   ```

4. Corregir las regresiones (pueden pertenecer al Bolt actual o ser deuda técnica).
5. Re-ejecutar quality gates + verificación de regresiones.
6. Solo proceder con merge cuando `$current -le $baseline`.

---

## Integration phase

Al completar un Bolt:

1. Mergear bolt-branch → feature branch (**NO a main**).

   ```bash
   git checkout feature/[feature-name]
   git merge feature/[feature-name]/bolt-[N]-[desc]
   ```

2. Feature → main solo cuando TODOS los Bolts de la feature están completos
   y bolt-review ha aprobado.

## Terminal commands

- Create projects: `dotnet new`, `npm create vite`.
- Install packages: `dotnet add package`, `npm install`.
- Run tests: `dotnet test`, `npm test`.
- Build: `dotnet build`, `npm run build`.

## Output — Bolt completion

```markdown
## Bolt [N] Complete
**Status**: Complete
**Tasks Completed**: [N]/[M]
**Days**: [X]
**Files Created/Modified**: [list]
**Quality Gates**:
- [ ] Linting: PASS/FAIL
- [ ] Tests: PASS/FAIL ([coverage]%)
- [ ] Mutation: PASS/FAIL ([score]%)
- [ ] Build: PASS/FAIL
**Skipped ACs**: [list or "None"]
**Next Steps**:
1. Review with bolt-review
2. Proceed to Bolt [N+1]
```

## Quality gates

- All tasks of the Bolt checked (SKIPPED tasks documented with issue link).
- Linting, tests and build PASS.
- Coverage ≥ 80 %, mutation ≥ 70 % (per `skill-bolt-quality-gates`).
- Mutation testing runs **Bolt-scope** by default (Application + Domain layers only).
  Full-solution run is reserved for release gates. Use `-BoltScope full` to force it.

## Feedback loop — quality gate failures

Si los quality gates fallan:

- **1er fallo**: fix normal, re-run gates.
- **2do fallo consecutivo** en el MISMO Bolt:
  1. STOP implementación.
  2. Evaluar: ¿el Bolt está mal dimensionado? ¿El approach es incorrecto?
  3. Opciones (sugerir al usuario):
     a) Reducir scope: mover tareas pendientes a un Bolt N+1 nuevo.
     b) Replanning: invocar bolt-plan para revisar el approach del Bolt.
     c) Escalar: crear issue `bolt-blocked` con contexto del fallo.
  4. NO continuar con el mismo approach que falló 2 veces.

## Feedback loop — AC inviable

Si durante implementación se descubre que un AC no puede satisfacerse
(dependencia faltante, contradicción con otro AC, limitación técnica):

1. NO bloquear el Bolt completo.
2. Crear GitHub Issue automáticamente:

   ```bash
   gh issue create \
     --title "Spec revision needed: [AC-ID] de [Feature]" \
     --body "AC inviable: [razón]. Descubierto en Bolt [N]." \
     --label "spec-revision-needed"
   ```

3. Marcar la tarea asociada como SKIPPED (no DONE) en tasks.md.
4. Continuar con las tareas viables del Bolt.
5. Documentar en el cierre del Bolt: "AC-XXX skipped, ver issue #YYY".

## Related agents (next steps)

- → `bolt-testing`: generate test suite for the implementation.
- → `bolt-review`: code review on the BOLT.
- → `bolt-analyze`: verify consistency with spec.
- → `bolt-infra`: delegate IaC implementation when scenario includes infra.

## References

- `.github/prompts/bolt-code-generation.prompt.md`
- `.github/prompts/bolt-micro-iteration.prompt.md`
