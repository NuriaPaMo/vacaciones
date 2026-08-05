---
name: business-agent-poc-flow
description: >
  Flujo completo del Business Agent PoC: máquina de estados conversacional de 9 fases
  para descubrimiento funcional con usuarios de negocio. Incluye criterios de transición,
  bifurcación de salida hacia Bolt Framework o solución No-Code, y mapeo de artefactos
  del discovery a la estructura de repositorio Bolt. SIEMPRE cargar cuando se trabaje con
  cualquier agente del flujo: Business Elicitor, Business Visualizer, Business Researcher,
  Business Triage, Business Agent Coordinator.
---

# Business Agent PoC — Flujo Funcional

## Propósito del sistema

**Business Agent PoC** es un agente conversacional de IA que guía a usuarios de negocio
(Product Owners, líderes de área sin perfil técnico) en la definición funcional de una
aplicación. El output es:

- **Todos los caminos**: ZIP con documentación funcional (casos de uso, Gherkin, glosario,
  mockups HTML, informe de triage, propuesta de estrategia).
- **Caminos Bolt (BoltTeam / CopilotAutónomo)**: además, ZIP de scaffold con la estructura
  de repositorio Bolt Framework lista para continuar el desarrollo.

## Máquina de estados — 9 fases

```text
PROPÓSITO → FUENTES_DATOS → REGLAS_NEGOCIO → MOCKUPS → REVISIÓN
    → DOCUMENTACIÓN → RESEARCH → TRIAGE → COMPLETO
```

### Tabla de fases

| Fase | `SessionPhase` | Agente runtime | Qué captura / genera |
|------|---------------|----------------|----------------------|
| **Propósito** | `Proposito` | Business Elicitor | Parafrasea la idea, sector, audiencia, TipoAplicacion |
| **Fuentes de datos** | `FuentesDatos` | Business Elicitor | Entidades de datos, orígenes, destinos, integraciones |
| **Reglas de negocio** | `ReglasNegocio` | Business Elicitor | Reglas SI/ENTONCES (máx. 20), formato RN-001 |
| **Mockups** | `Mockups` | Business Visualizer | HTML+TailwindCSS: dashboard, formulario, listado |
| **Revisión** | `Revision` | Business Triage | Resumen completo, confirmación antes de documentar |
| **Documentación** | `Documentacion` | Business Triage | Casos de uso (Cockburn), Gherkin, glosario |
| **Research** | `Research` | Business Researcher | Propuesta de estrategia, evaluación 4 caminos |
| **Triage** | `Triage` | Business Triage | Decisión final, justificación, próximos pasos |
| **Completo** | `Completo` | Business Agent Coordinator | Bifurcación: ZIP docs / ZIP scaffold Bolt |

### Criterios de transición

- El LLM incluye `"phaseComplete": true` en el JSON estructurado de su respuesta.
- `StructuredOutputParser` lo detecta y llama a `session.AdvancePhase()` automáticamente.
- El usuario puede retroceder a cualquier fase anterior (excepto desde `Completo`).

## Contexto acumulado (JSON estructurado)

El agente mantiene este contexto creciente a lo largo de la sesión:

```json
{
  "proposito": "Reformulación del agente (no literal)",
  "sector": "Salud | Retail | Finanzas | Industria | ...",
  "audiencia": "Descripción de los usuarios principales",
  "tipoAplicacion": "Departamental | Helpdesk | Negocio | PoC",
  "fuentesDatos": [
    { "nombre": "...", "proposito": "...", "origen": "Interno|SistemaExterno|Api|Archivo", "destino": "..." }
  ],
  "reglasNegocio": [
    { "id": "RN-001", "condicion": "...", "accion": "...", "descripcion": "..." }
  ],
  "entidadesDatos": [
    { "nombre": "...", "descripcion": "...", "atributos": ["campo1", "campo2"] }
  ],
  "integraciones": [
    { "sistema": "...", "tipo": "API|SSO|BD|Servicio", "proposito": "...", "operaciones": ["op1"] }
  ],
  "preguntasAbiertas": [
    { "id": "Q1", "pregunta": "...", "categoria": "Reglas|Integraciones|UI|Seguridad" }
  ],
  "phaseComplete": false
}
```

## Bifurcación de salida post-Triage

El resultado del triage determina el flujo de salida:

```text
               ┌─ PowerPlatform (Alta) ──────────→ ZIP docs + recomendación LP. FIN.
               │
               ├─ M365ExistingTool (Alta) ───────→ ZIP docs + recomendación M365. FIN.
Triage result ─┤
               ├─ BoltTeam (Alta) ──────────────→ ZIP docs + ZIP scaffold Bolt. CONTINÚA.
               │
               └─ CopilotAutónomo (Alta) ────────→ ZIP docs + ZIP scaffold Bolt. CONTINÚA.
```

Cuando el camino es **BoltTeam** o **CopilotAutónomo**, el `@Business Agent Coordinator`
debe ofrecer el endpoint de scaffold y el handoff a `@Bolt Constitution`.

## Criterios de evaluación del Research (4 caminos)

| Camino | Nombre | Criterio de adecuación **Alta** |
|--------|--------|---------------------------------|
| `PowerPlatform` | Power Platform | Complejidad Baja + Integraciones Ninguna/Pocas |
| `M365ExistingTool` | Herramienta M365 existente | Funcionalidad cubierta por SharePoint, Lists, Forms, Teams o Planner sin personalización |
| `BoltTeam` | Equipo Bolt (Desarrollo) | Complejidad Media/Alta o múltiples integraciones externas |
| `CopilotAutonomo` | Copilot Autónomo | Complejidad Baja + Integraciones Pocas/Ninguna + patrones conocidos |

### Reglas de investigación para Business Researcher

1. **Siempre evalúa los 4 caminos** — nunca descartes sin justificación.
2. **M365 primero**: si la funcionalidad puede cubrirse con una herramienta M365 existente
   (SharePoint Lists, Microsoft Forms, Teams + Power Automate, Planner), señálalo como
   la opción de **menor coste y menor tiempo** antes de proponer desarrollo.
3. **Power Platform**: evalúa si las reglas de negocio caben en flujos Power Automate y si
   las pantallas son alcanzables con Power Apps.
4. **Umbral Bolt vs Copilot Autónomo**: si `reglasNegocio.count > 10` OR
   `integraciones externas > 3` → BoltTeam; si ≤ 5 reglas AND ≤ 1 integración → CopilotAutónomo.
5. El output debe ser el artefacto `research/strategy-proposal.md` con formato Markdown:
   - Tabla comparativa de los 4 caminos (Adecuación, Coste relativo, Tiempo, Riesgos)
   - Recomendación principal con justificación
   - Próximos pasos para el camino recomendado

## Técnicas de elicitación (Business Elicitor)

### Reglas fundamentales

- **PARAFRASEAR siempre**: nunca repetir textualmente las palabras del usuario.
- **Sector-aware**: adapta ejemplos, terminología y preguntas al sector configurado.
- **Una pregunta a la vez**: no bombardear con 5 preguntas seguidas.
- **Confirmar antes de avanzar**: antes de `phaseComplete: true`, resume lo capturado.
- **Lenguaje de negocio**: evitar jerga técnica (no mencionar APIs, DTOs, microservicios).

### Formato de reglas de negocio

```text
SI [condición observable] ENTONCES [acción del sistema]
Ejemplo: SI el pedido supera 500 € ENTONCES notificar al responsable de área
```

### Tipos de aplicación (guía de clasificación)

| Tipo | Señales |
|------|---------|
| **Departamental** | "para mi equipo", "uso interno", "solo nosotros" |
| **Helpdesk** | "para clientes", "soporte", "incidencias" |
| **Negocio** | "core del negocio", "facturación", "operaciones" |
| **PoC** | "demo para dirección", "prueba de concepto", "validar idea" |

## Estructura del scaffold Bolt Framework

Cuando el camino es Bolt (BoltTeam o CopilotAutónomo), el scaffold ZIP tiene esta estructura:

```text
[nombre-app-slug]/
├── .boltf/
│   └── memory/
│       └── constitution.md          ← pre-inicializado con datos del discovery
├── specs/
│   └── 001-[nombre-app]/
│       ├── feature.md               ← generado desde propósito + audiencia
│       ├── requirements/
│       │   ├── requirements.md      ← reglas de negocio + fuentes de datos
│       │   └── use-cases/
│       │       └── casos-de-uso.md  ← artefacto de documentación
│       ├── tests/
│       │   └── escenarios.feature   ← artefacto Gherkin
│       ├── mockups/
│       │   └── [mockup-*.html]      ← mockups generados
│       └── planning/                ← vacío, listo para @Bolt Plan
└── docs/
    └── research/
        └── strategy-proposal.md    ← artefacto de research
```

### Contenido de `constitution.md` pre-inicializado

El `constitution.md` del scaffold se genera con los datos del discovery:

```markdown
# Constitution — [Título de la sesión]

## Proyecto
- **Nombre**: [título slug]
- **Propósito**: [proposito de la sesión]
- **Sector**: [sector]
- **Tipo**: [tipoAplicacion]
- **Audiencia**: [audiencia]

## Stack tecnológico (por definir con @Bolt Constitution)
- A definir según complejidad y preferencias del equipo

## Dominio identificado
- **Entidades**: [lista de entidadesDatos]
- **Reglas de negocio**: [count] reglas capturadas
- **Integraciones**: [lista de integraciones]

## Estado inicial
- Fase: INCEPTION — Discovery funcional completado
- Siguiente paso: Ejecutar @Bolt Constitution para completar la configuración
```

## Notas de implementación para desarrolladores

- **`CopilotAgentClient.PhaseToAgent`**: el mapeo en el código debe apuntar a los nombres
  exactos de los agentes de dominio (campo `name:` del frontmatter de cada `.agent.md`).
- **`SystemMessageMode.Append`**: los agentes de dominio coexisten con el system prompt
  construido por `SystemPromptBuilder` — no lo reemplazan.
- **Endpoint scaffold**: `GET /api/sessions/{sessionId}/artifacts/scaffold` devuelve el ZIP
  de estructura Bolt Framework. Solo disponible cuando `CurrentPhase == Completo`.
- **Typo conocido**: en `CopilotAgentClient.cs` existe `"Bolt Consitution"` (falta una 's').
  Corregido en el mapeo a `"Business Agent Coordinator"` para la fase `Completo`.
