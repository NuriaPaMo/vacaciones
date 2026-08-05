---
mode: agent
description: '🛠️ Modernización de legacy con Bolt Framework (discovery → transform). Orquesta con agentes Bolt nativos; los pasos modernize-* son aceleradores opcionales de Claude Code.'
tools:
  - filesystem
  - terminal
---

# Modernización de legacy con Bolt Framework

> **Nota sobre `modernize-*`**: los pasos `modernize-assess/map/extract-rules/brief/harden/transform/reimagine`
> pertenecen a un **plugin de Claude Code** y NO están disponibles en GitHub Copilot.
> En Copilot se orquesta con **agentes Bolt nativos** (equivalencias indicadas abajo).
> Si quieres usar `modernize-*` también desde Copilot, *vendoriza* su metodología como
> Agent Skills del proyecto en `.claude/skills/` (las skills son dual-client).

## Parámetros (rellena antes de ejecutar)

- LEGACY_PATH:   <ruta al código legacy>
- TARGET_STACK:  <stack destino>
- ALCANCE:       <"un-modulo" (prueba acotada) | "completo">
- ESTRATEGIA:    <"transform" (reescritura por módulo) | "reimagine" (greenfield)>
- IDIOMA:        <Español (España) | English>
- RIESGO:        <criterio para elegir el primer módulo>

## Rol y método

Actúa como orquestador del **Bolt Framework** (`@Bolt Framework`) para modernizar el sistema
en LEGACY_PATH hacia TARGET_STACK, usando el ciclo de vida Bolt (gobernanza, constitution,
specs, quality gates). Toda interacción y documentación en IDIOMA.

**Reglas:**

- Trabaja por fases; **párate en cada checkpoint HITL** y espera validación.
- No reescribas nada sin tests de equivalencia que fijen el comportamiento legacy.
- Respeta la constitution (`.boltf/memory/constitution.md`) y las quality gates. Versiona
  todo en `specs/`, `docs/adr/`, `migration/`. Crea/actualiza el issue de GitHub por feature/bolt.

## Pipeline (agente Bolt nativo · equivalente Claude opcional)

### Fase 1 — INCEPTION

1. Verifica brownfield (`legacy/`, `.boltf/`). Si falta: `./init.sh --type brown --source LEGACY_PATH`.
2. `@Bolt Constitution` → constitution con TARGET_STACK, estándares, constraints.
   ⏸ **CHECKPOINT 1**.

### Fase 2 — DISCOVERY

3. `@Bolt Legacy Analyst` (lectura del legacy: inventario, complejidad, deuda, dead code,
   esfuerzo + mapa + reglas). Informe en `.boltf/analysis/`.  · *Claude: `modernize-assess`/`map`/`extract-rules`*.
4. Si ALCANCE="un-modulo": propón módulo según RIESGO. ⏸ **CHECKPOINT 2**.
5. `@Bolt Architect` + skills `mermaid-creator` / `bolt-datamodel-diagramer` (call graphs,
   data lineage → diagramas en `docs/`).  · *Claude: `modernize-map`*.
6. Extrae reglas de negocio (Given/When/Then) leyendo el legacy y crea specs:
   `@Bolt Feature` → `@Bolt Specify` → `@Bolt Gherkin` en `specs/<feature>/`; `@Bolt Analyze`
   valida.  · *Claude: `modernize-extract-rules` + `business-rules-extractor`*.
   ⏸ **CHECKPOINT 3**.

### Fase 3 — PLAN

7. `@Bolt Plan` (+ `@Bolt Architect`, `@Bolt ADR`): plan técnico, data model, contratos API y
   **desglose en Bolts**, reconciliado con `@Bolt Tasks`.  · *Claude: `modernize-brief`*.
   ⏸ **CHECKPOINT 4**.
8. (Opcional) `@Bolt Security` (hallazgos a remediar).  · *Claude: `modernize-harden` + `security-auditor`*.

### Fase 4 — CONSTRUCTION (por cada Bolt)

9. Tests de **caracterización/equivalencia** que fijan el comportamiento legacy
   (`@Bolt Testing` modo oráculo + skill `skill-characterization-testing`; `skill-tdd-red-green-refactor`,
   `skill-playwright-e2e`). · *Claude: agente `test-engineer`*.
10. `@Bolt Implement` + disciplina TDD (`tdd-red`/`tdd-green`/`tdd-refactor`).
    · *Claude: `modernize-transform` (módulo) o `modernize-reimagine` (greenfield)*.
11. Quality gates (cobertura, mutación, arquitectura) **+ gate de equivalencia** (pass ≥ 95%,
    100% comportamiento P0 caracterizado) + `@Bolt Review`.
    · *Claude: `architecture-critic`*.  ⏸ **CHECKPOINT 5** (por Bolt).

### Fase 5 — TRANSITION

12. `@Bolt Documentation` + `@Bolt ADR`; `@Bolt Release` si procede.
13. Registra en `migration/` lo modernizado y candidatos a retirada para `@Bolt Retire`.

## Entregable de cada checkpoint

Resumen de lo hecho, rutas de artefactos y la decisión necesaria para continuar.
Empieza por la **Fase 1**.
