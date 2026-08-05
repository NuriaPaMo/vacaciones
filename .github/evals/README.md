# Evals de agentes Bolt

Mecanismo de evaluación A/B para medir el beneficio de los cambios en los agentes
Bolt.

Reutiliza la infraestructura `skill-creator`
(`.claude/skills/skill-creator/scripts/`) adaptada a agentes en lugar de skills.

## Estructura

```text
.github/evals/
├── README.md                      ← este fichero
└── agents/
    └── <agent-name>/evals.json
```

Cada agente con evals tiene su propio directorio bajo `agents/` con un fichero
`evals.json`. Los `evals.json` concretos son específicos del proyecto consumidor
(dependen de su stack y dominio) y se definen por proyecto.

## Diferencias con el formato `skill-creator`

| Campo skill-creator | Campo agent eval | Notas                                                  |
| ------------------- | ---------------- | ------------------------------------------------------ |
| `skill_name`        | `agent_name`     | Nombre del agente (sin `.agent.md`)                    |
| `with_skill`        | `after_improvements` | Configuración tras aplicar las mejoras del PR      |
| `without_skill`     | `before_improvements` | Configuración con los agentes en estado baseline   |

Cada test case puede añadir un campo extra `scenario` con uno de:
`backend-only`, `frontend-only`, `infra-only`, `fullstack`.

## Ciclo A/B

### 1. Baseline (antes de modificar agentes)

```powershell
# Desde la raíz del repo, sobre rama main o snapshot pre-cambios
python -m .github.skills.skill-creator.scripts.run_loop `
  --target .github/evals/agents/<agent-name> `
  --configuration before_improvements `
  --runs 3
```

Repetir para cada agente. Resultados se guardan en
`.github/evals/results/iteration-baseline/`.

### 2. Aplicar cambios (este PR)

Aplica las modificaciones de los agentes en tu rama de trabajo.

### 3. Post-cambios

```powershell
python -m .github.skills.skill-creator.scripts.run_loop `
  --target .github/evals/agents/<agent-name> `
  --configuration after_improvements `
  --runs 3
```

### 4. Agregación y delta

```powershell
python -m .github.skills.skill-creator.scripts.aggregate_benchmark `
  .github/evals/results/iteration-1 `
  --skill-name <agent-name>
```

Genera `benchmark.json` con `pass_rate.mean ± stddev` para cada configuración
y `delta` entre `before_improvements` y `after_improvements`.

### 5. Visualización

```powershell
python .claude/skills/skill-creator/eval-viewer/generate_review.py `
  .github/evals/results/iteration-1 `
  --skill-name <agent-name> `
  --benchmark .github/evals/results/iteration-1/benchmark.json
```

## Criterios de éxito

| Métrica | Umbral | Aplica a                                  |
| ------- | ------ | ----------------------------------------- |
| `delta(pass_rate)` por escenario `backend-only`, `frontend-only`, `infra-only` | `>= +0.30` | agentes existentes |
| `pass_rate` en escenario `fullstack`                                           | `>= 0.80` (no regresión) | agentes existentes |
| `pass_rate` baseline                                                            | `>= 0.70`  | agentes nuevos (todos los escenarios) |

## Verificación manual complementaria

Los evals automáticos no capturan todo. Verificar también a mano que cada agente
respeta el escenario detectado (p. ej. que un agente no genere artefactos de una
capa que no corresponde al escenario declarado, y que las fases condicionales por
escenario se incluyan u omitan correctamente).

## Referencias

- Formato JSON detallado: `.claude/skills/skill-creator/references/schemas.md`
- Workflow completo: `.claude/skills/skill-creator/SKILL.md`
