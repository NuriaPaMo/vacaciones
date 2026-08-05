# Brownfield Workflow — Legacy Modernization

> Workflow para modernizar código legacy (p. ej. COBOL, .NET Framework, Java antiguo) a un
> stack moderno, con tests de equivalencia y gobierno Bolt. Cliente: Copilot o Claude.

---

## Overview

```text
Init (brownfield) → Constitution → Legacy Analyst (assess/map/rules)
  → Feature/Gherkin (desde reglas) → Plan → [Bolt Loop con tests de equivalencia + gate] → Release → Retire
```

## Step-by-Step

### 1. Inicializar con el legacy

```bash
./init.sh --type brown --source ./legacy-cobol     # wizard → AI client (Copilot/Claude)
```

```powershell
.\Init.ps1 -ProjectType brown -SourceDirectory .\legacy-cobol -OutputDirectory .\my-modern-app
```

Crea `legacy/` (código viejo, para análisis — **no se modifica**), `migration/`, `.boltf/`,
`.claude/`/`.github` (según cliente), e inicializa la gobernanza git (subtree + `bolt-upstream`).

### 2. Constitution moderna — `@Bolt Constitution`

Define stack destino, estándares y constraints en `.boltf/memory/constitution.md`. DEBE incluir:

- Stack moderno y arquitectura objetivo.
- **Requisito de equivalencia**: todo comportamiento P0 del legacy debe quedar caracterizado.
- Estrategia de migración (strangler fig recomendada).

### 3. Discovery del legacy — `@Bolt Legacy Analyst`

Lee `legacy/` y produce (citando `fichero:línea`):

- `ASSESSMENT.md` (inventario, complejidad, deuda, dead code, esfuerzo) → `.boltf/analysis/<sistema>/`
- `TOPOLOGY.md` (call graph, data lineage, ruta crítica) → `docs/<sistema>/`
- `BUSINESS_RULES.md` + `DATA_OBJECTS.md` (reglas `RULE-NNN` en Given/When/Then) → `.boltf/analysis/<sistema>/`

> Si usas Claude con el plugin `code-modernization`, este agente puede delegar en
> `modernize-assess`/`modernize-map`/`modernize-extract-rules`. Si no, lo hace de forma nativa.

### 4. Mapa de features — `@Bolt Feature` → `@Bolt Specify` → `@Bolt Gherkin`

Convierte `BUSINESS_RULES.md` en specs versionados en `specs/<feature>/`, con los escenarios
Given/When/Then como criterios de aceptación (las reglas alimentan directamente Gherkin).

### 5. Plan de migración — `@Bolt Plan` (+ `@Bolt Architect`, `@Bolt ADR`)

Plan técnico, data model, contratos y **desglose en Bolts** (strangler fig), usando
`ASSESSMENT.md`/`TOPOLOGY.md` como contexto.

### 6. Implementar con equivalencia — por cada Bolt

1. **Tests de caracterización** (skill `skill-characterization-testing`, `@Bolt Testing` modo
   oráculo): fija el comportamiento legacy (golden master / parity) sobre las reglas P0.
2. `@Bolt Implement` escribe el equivalente moderno (idiomático, no port estructural).
3. **Gate de equivalencia** (`skill-bolt-quality-gates`): equivalence pass rate ≥ 95% (100% P0),
   100% de comportamiento P0 caracterizado, 0 discrepancias sin decidir.

```text
# Equivalencia (pseudo)
Given input X   When legacy(X) = 42.50   Then modern(X) ≈ 42.50  (RULE-007)
```

### 7. Validar, liberar, retirar

- `@Bolt Review` (+ verificar que no se pierde comportamiento) → `@Bolt Documentation`/`@Bolt ADR`.
- `@Bolt Release` despliega el reemplazo moderno.
- `@Bolt Retire` desmantela el módulo legacy (usa los candidatos a dead code del assessment).

---

## Contrato de handoff (qué alimenta a qué)

| Artefacto (Legacy Analyst / plugin) | Consumidor Bolt | Destino |
|---|---|---|
| `ASSESSMENT.md`, `TOPOLOGY.md` | `bolt-plan` / `bolt-architect`; dead code → `bolt-retire` | `.boltf/analysis/`, `docs/` |
| `BUSINESS_RULES.md` (Given/When/Then) | `bolt-feature` → `bolt-specify` → `bolt-gherkin` | `specs/<feature>/` |
| `DATA_OBJECTS.md` | `bolt-ddd` / data model de `bolt-plan` | `specs/`, `docs/` |
| `RULE-NNN` (P0) | `skill-characterization-testing` + **gate de equivalencia** | tests del módulo |
| Código modernizado | quality gates de Bolt **+ equivalencia** | `src/` |

Crea/actualiza un **issue de GitHub por feature/bolt** (ver `CLAUDE.md` / `copilot-instructions.md`).

## Diferencias con greenfield

| Aspecto | Greenfield | Brownfield |
|--------|-----------|------------|
| Init | `--type green` | `--type brown --source` |
| Carpeta legacy | — | `legacy/` (solo lectura) |
| Discovery | — | `@Bolt Legacy Analyst` (assess/map/rules) |
| Tests | features nuevas | **caracterización + equivalencia** |
| Gate extra | — | **gate de equivalencia** |
| Riesgo | menor | mayor — hay que preservar comportamiento |
