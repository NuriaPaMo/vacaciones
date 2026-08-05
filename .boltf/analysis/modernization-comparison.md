# Modernización: Bolt Framework vs. plugin `code-modernization`

> Comparación honesta y basada en evidencia entre el proceso de modernización **nativo de
> Bolt Framework** y el del **plugin de Claude Code `code-modernization`** (Anthropic), con
> palancas de mejora para uno, el otro y la integración de ambos.
>
> Fecha: 2026-06-01 · Ámbito: capacidad de modernización de legacy / brownfield.

## Veredicto en una frase

**Son complementarios, no competidores.** El plugin es fuerte justo donde Bolt es débil
(arqueología de legacy + tests de equivalencia) y Bolt aporta lo que al plugin le falta
(gobierno, ciclo de vida, CI/quality gates, dual-client, trazabilidad a issues). Bolt **solo**
no es apto para una modernización seria; el plugin **solo** moderniza pero sin gobierno continuo.

## Hallazgos críticos

- **Punto débil #1 de Bolt**: ausencia de **tests de caracterización/equivalencia**. Solo
  existe un *ejemplo* en `.claude/skills/bolt-framework/examples/brownfield-workflow.md`
  (parity test), sin skill ni agente. Sin esto no se puede *demostrar* que el comportamiento
  legacy se preserva — el riesgo central de toda modernización. El plugin lo resuelve de raíz
  con el agente `test-engineer` (legacy como oráculo, tests ejecutables desde el día 1).
- **Punto débil #1 del plugin**: no tiene **gobierno ni CI continuo** — no hay constitution,
  ni quality gates, ni sincronización de issues, ni versionado en `specs/`; y `modernize-map`
  exige que el usuario escriba el parser de topología. Además es **Claude-only**.
- **Bolt es greenfield-first**: el modo brownfield solo crea `legacy/` + `migration/`; no hay
  ningún agente que lea/inventaríe el legacy ni que extraiga reglas del código.

## Comparación

| Dimensión | Bolt Framework | Plugin code-modernization |
|---|---|---|
| Discovery legacy (inventario, complejidad, dead code, COCOMO) | 🔴 Ninguno nativo | 🟢 `modernize-assess` + `legacy-analyst` |
| Mapa (call graph, data lineage, critical path) | 🔴 Ninguno | 🟢 `modernize-map` (script + Mermaid) |
| Reglas de negocio desde código (Given/When/Then) | 🟡 `bolt-specify`/`bolt-gherkin` parten de requisitos nuevos, no del código | 🟢 `modernize-extract-rules` + confianza + SME flags |
| Plan / Brief | 🟡 `bolt-plan` (de specs nuevas) | 🟢 `modernize-brief` con gate HITL + strangler-fig + behavior contract |
| Tests de caracterización/equivalencia | 🔴 Solo ejemplo en `brownfield-workflow.md` | 🟢 `test-engineer` (legacy como oráculo) — su mayor fortaleza |
| Transform / Reimagine | 🟡 `bolt-implement` + TDD (forward) | 🟢 `modernize-transform` (módulo, equivalencia probada) / `modernize-reimagine` (greenfield multiagente, 2 HITL) |
| Seguridad | 🟡 `bolt-security` (forward) | 🟢 `modernize-harden` (scan + patch revisable + doble revisión) |
| Gobierno (constitution, quality gates, issues, ADRs) | 🟢 Fuerte | 🔴 No tiene |
| Ciclo de vida completo (release/ops/retire) | 🟢 Sí (`bolt-release`/`bolt-ops`/`bolt-retire`) | 🔴 Acaba en el código modernizado |
| Dual-client (Copilot + Claude) | 🟢 Sí | 🔴 Claude-only |
| Layout de artefactos | `specs/`, `src/`, `.boltf/` | `analysis/`, `modernized/` (propio) |

Leyenda: 🟢 sólido/profundo · 🟡 parcial · 🔴 ausente.

## Fortalezas y debilidades

### Bolt Framework

- **Fortalezas**: gobierno (constitution + quality gates), ciclo de vida completo, dual-client,
  sincronización de issues de GitHub, ADRs, `bolt-retire`, escaneo de seguridad, estructura
  brownfield (`legacy/` + `migration/`).
- **Debilidades**: sin arqueología de legacy, sin extracción de reglas desde código, sin
  tests de caracterización/equivalencia, sin call-graph/data-lineage, sin assessment de portfolio,
  quality gates que solo miden calidad de código nuevo (no paridad legacy↔moderno).

### Plugin code-modernization

- **Fortalezas**: secuencia disciplinada (assess → map → extract-rules → brief[HITL] →
  transform/reimagine, + harden), agentes especialistas (`legacy-analyst`,
  `business-rules-extractor`, `security-auditor`, `architecture-critic`, `test-engineer`),
  captura de reglas con confianza y SME flags, equivalencia integrada, dos caminos
  (strangler-fig y greenfield), seguridad de primera clase, soporte de portfolio, handoff de
  conocimiento (`CLAUDE.md` en `reimagine`).
- **Debilidades**: `map` exige escribir el parser de topología a mano; sin baseline de
  rendimiento en el behavior contract; parallel-run del strangler-fig mencionado pero no
  orquestado; portfolio sequencing sin dependencias inter-sistema; tests scaffolded son stubs;
  sin gobierno/CI; **Claude-only**; artefactos en su propio layout (`analysis/`, `modernized/`).

## Cómo mejorar

### Mejorar Bolt (lo más rentable)

1. **Cerrar el gap de equivalencia** (máxima prioridad): skill dual-client
   `skill-characterization-testing` + modo "oráculo legacy" en `bolt-testing`. Reduce la
   dependencia 100% de un plugin Claude-only para lo más crítico.
2. **Quality gate de equivalencia** en `skill-bolt-quality-gates`: p. ej. "equivalence pass
   rate ≥ 95%" y "legacy behavior coverage".
3. **Discovery brownfield nativo** (assess/map ligero) o **vendorizar** la metodología del
   plugin a `.claude/skills/` (dual-client, gobernada y versionada por el framework).
4. **Agente `bolt-legacy-analyst`** (lectura/arqueología) — hoy inexistente.

### Mejorar el plugin

1. **Modo gobernado**: emitir a layout Bolt (`specs/` desde `BUSINESS_RULES.md`, awareness de
   constitution) además de `analysis/`/`modernized/`.
2. **Baseline de rendimiento** en el behavior contract.
3. **Parsers de topología** listos para stacks comunes (no "escríbete el script").
4. **Dependencias inter-sistema** en el portfolio sequencing.
5. **Orquestar parallel-run** durante el strangler-fig.

### Mejorar ambos = la integración (mayor valor real)

Definir el **contrato de handoff** y hacerlo explícito en `/modernize-legacy` y
`brownfield-workflow.md`:

| Paso plugin | Artefacto | Destino / consumidor Bolt |
|---|---|---|
| `assess` / `map` | `ASSESSMENT.md`, `TOPOLOGY.*` | `.boltf/analysis/` + `docs/` |
| `extract-rules` | `BUSINESS_RULES.md` (G/W/T) | input de `bolt-gherkin` → `specs/<feature>/` |
| `brief` | `MODERNIZATION_BRIEF.md` | reconciliar con `bolt-plan` (desglose en Bolts) |
| `transform` / `reimagine` | `modernized/` | `src/` bajo quality gates de Bolt **+ gate de equivalencia** |
| dead code de `assess` | candidatos a retirada | `bolt-retire` |

Más: **un issue de GitHub por fase/Bolt** (ya en el modelo dual-client).

## Recomendación

Mantener el plugin como **motor de modernización** (no reinventarlo) y subir a Bolt:
**(1)** skill de caracterización/equivalencia, **(2)** quality gate de equivalencia, y
**(3)** el contrato de handoff explícito. Eso convierte `/modernize-legacy` de "narrado" a
**gobernado de verdad**, y deja a Copilot cubierto vía vendorización de la metodología.

## Evidencia (rutas)

- Brownfield init: `init.sh` (≈ líneas 915-920), `Init.ps1` (≈ 950-954) — crean `legacy/` + `migration/`.
- Sin agentes/skills de legacy en `.claude/agents/` ni `.github/agents/` (34 agentes, ninguno de arqueología/equivalencia).
- Único parity test (ejemplo): `.claude/skills/bolt-framework/examples/brownfield-workflow.md`.
- Quality gates: `.claude/skills/skill-bolt-quality-gates/SKILL.md` (cobertura/mutación/lint; sin equivalencia).
- Orquestador dual-client creado: `.claude/commands/modernize-legacy.md` y `.github/prompts/modernize-legacy.prompt.md`.
- Plugin: `C:\Users\<user>\.claude\plugins\marketplaces\claude-plugins-official\plugins\code-modernization\` (7 skills `modernize-*` en `commands/`, 5 agentes en `agents/`, `README.md`).
