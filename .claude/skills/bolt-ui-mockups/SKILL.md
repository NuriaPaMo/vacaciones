---
name: bolt-ui-mockups
description: >-
  Generate and refine static low-fidelity UI mockups for Bolt Framework features (frontend-only, backend+frontend, fullstack). Single-file HTML with Tailwind v4 CDN, no JS frameworks. Two modes — `generate` (initial wireframes from spec) and `refine` (iterate over user feedback). Produces accessible static deliverables for stakeholder review BEFORE planning and implementation. Triggers — "mockup", "wireframe", "boceto UI", "prototipo visual", "low-fi mockup", "diseñar pantalla", "refinar mockup", "generate mockups", "DISCOVERY mockups", "/bolt-mockup".
---

# Bolt UI Mockups — Methodology

Produce **low-fidelity, static HTML mockups** for Bolt Framework features that
involve UI. Mockups are a **DISCOVERY artifact**: they validate flows,
states and content with stakeholders BEFORE writing the technical plan
(`bolt-plan`) or any UI code (`bolt-implement`).

**Bolt Framework Stage**: DISCOVERY (post `bolt-feature`, pre `bolt-plan`)
**Responsible Agent**: `bolt-mockup` (dual-client shell)

## Preconditions

1. `specs/[XXX-feature-name]/requirements/requirements.md` exists and has
   at least one User Story with a UI touchpoint.
2. Scenario declared by `bolt-feature` is one of:
   `frontend-only | backend+frontend | fullstack` (i.e. **contains
   frontend**). For `backend-only` and `infra-only` → skip mockups
   entirely; return a one-line note explaining why.
3. `.boltf/memory/constitution.md` is readable (used to capture brand
   defaults: colours, typography, accessibility level).

## Modes

The skill operates in **two modes**, both invoked through the
`bolt-mockup` agent.

### Mode `generate` (default first run)

- Input: ruta a la spec (`specs/[XXX-feature-name]/`) y, opcionalmente,
  un sub-conjunto de user stories.
- Output: uno o varios ficheros HTML estáticos por **(flujo, paso,
  estado)** en `specs/[XXX-feature-name]/mockups/`.
- Acción: leer la spec, mapear cada User Story con UI a una secuencia
  de pantallas, decidir estados a maquetar (ver "States to mock") y
  generar los HTML.

### Mode `refine`

- Input: ruta a un mockup existente + lista de cambios solicitados por
  el usuario (texto libre, comentarios, capturas anotadas).
- Output: nuevas versiones de los HTML (sobrescritura) + entrada en
  `specs/[XXX-feature-name]/mockups/CHANGELOG.md` con resumen del
  cambio y fecha.
- Acción: aplicar los cambios sin re-generar pantallas no mencionadas;
  preservar la naming convention y los estados existentes.

## Fidelity policy

- **Low-fidelity, neutral palette** — fondo claro, paleta de grises
  (`zinc`/`slate`), bordes sólidos, sin glows ni efectos de marca. La
  paleta concreta puede ajustarse a los defaults declarados en la
  `constitution.md` del proyecto consumidor.
- **NO** branding final, NO ilustraciones, NO iconografía de marca, NO
  imágenes reales (usa un bloque gris con texto `[image]`).
- **NO** frameworks JS. Sólo HTML semántico + Tailwind v4 utilities.
- **JavaScript permitido**: sólo si es estrictamente necesario para mostrar
  una variación de estado (p. ej. toggle entre tabs maquetados); preferir
  duplicar el HTML en archivos `<state>` separados antes que añadir JS.
- **Componentes interactivos**: representarlos visualmente, no funcionalmente
  (un botón es `<button>` con clases Tailwind, sin handler).

## Technical constraints (obligatorio en CADA HTML generado)

```html
<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>[Feature] — [Flow] — [Step] — [State]</title>
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
  </head>
  <body class="antialiased min-h-screen bg-zinc-50 text-zinc-900">
    <!-- annotation strip (siempre presente arriba) -->
    <header class="border-b border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
      <strong>Mockup · </strong>
      <span>
        Feature: <code>[XXX-feature-name]</code> ·
        Flow: <code>[flow]</code> · Step: <code>[step]</code> ·
        State: <code>[state]</code>
      </span>
    </header>
    <main class="mx-auto max-w-5xl p-6">
      <!-- contenido wireframe -->
    </main>
  </body>
</html>
```

Reglas:

- Tailwind v4 **vía CDN browser build**:
  `https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4` (no requiere build).
- Nunca incluir `<link rel="stylesheet">` adicional ni un build de Tailwind:
  todos los estilos vienen del CDN (más, opcionalmente, un bloque `<style>`
  inline mínimo si hace falta).
- Accesibilidad básica obligatoria: `lang`, `<title>`, headings jerárquicos
  (`h1` → `h2` → `h3`), `alt=""` en imágenes decorativas, `aria-label` en
  iconos sin texto, contraste mínimo AA.
- Tipografía: `system-ui, -apple-system, sans-serif`; no cargar fuentes
  externas.

## States to mock (mínimo obligatorio por pantalla)

Para cada paso de un flujo, generar al menos los siguientes estados (un
HTML por estado). Si un estado no aplica, documentarlo en `CHANGELOG.md`
con justificación.

| Estado | Cuándo se genera | Naming sugerido |
|--------|------------------|-----------------|
| `default` | Siempre | `<flow>-<step>-default.html` |
| `empty` | Si la pantalla muestra colecciones (lista, tabla, kanban) | `<flow>-<step>-empty.html` |
| `loading` | Si la pantalla depende de datos remotos | `<flow>-<step>-loading.html` |
| `error` | Siempre (errores del happy path y de validación) | `<flow>-<step>-error.html` |
| `success` | Si el paso confirma una acción del usuario (submit, save) | `<flow>-<step>-success.html` |

Estados adicionales recomendados según la spec: `disabled`, `read-only`,
`no-permissions`, `partial-data`. Documentar cualquier estado extra en el
`CHANGELOG.md`.

## Responsive baseline

- Diseñar **mobile-first** (≤ 640 px) y verificar visualmente que también
  funciona en `md` (768 px) y `lg` (1024 px) usando utilities Tailwind
  responsivas (`md:`, `lg:`).
- No generar HTMLs separados por breakpoint: un único HTML por estado debe
  responder usando clases responsive de Tailwind.
- Anotar en el header del mockup el viewport recomendado para revisión
  (`Optimised for: mobile / tablet / desktop`).

## Naming convention (output)

Ubicación: `specs/[XXX-feature-name]/mockups/`

```text
specs/001-user-registration/mockups/
├── CHANGELOG.md
├── README.md                              # índice de flujos generados
├── signup-step1-default.html
├── signup-step1-empty.html
├── signup-step1-error.html
├── signup-step1-loading.html
├── signup-step1-success.html
├── signup-step2-default.html
├── signup-step2-error.html
├── ...
└── verify-email-default.html
```

Reglas:

- `<flow>` → nombre del flujo en kebab-case derivado del título de la
  User Story (e.g. `signup`, `reset-password`, `verify-email`).
- `<step>` → `step1`, `step2`, …, o un nombre semántico corto
  (`review`, `confirmation`) cuando aporte claridad.
- `<state>` → uno de los listados arriba.
- Sin extensiones extra, sin sufijos de versión (el versionado va en
  `CHANGELOG.md` + git).

## Annotation symbols (within mockups)

Para que los stakeholders entiendan que es un wireframe, usar marcadores
visuales consistentes:

- `[image]` → placeholder de imagen (bloque gris con texto centrado
  `[image]`, borde sólido).
- `[icon]` → placeholder de icono (cuadro 24×24 con borde).
- `[chart]` → placeholder de gráfico (bloque gris grande con ejes
  simulados con `border`).
- `Lorem ipsum…` → contenido de texto de relleno (nunca contenido real).
- `<!-- TODO(content): … -->` → comentario HTML cuando falte contenido
  por confirmar con negocio.
- En el annotation strip listar cualquier asunción hecha (e.g. "Asume
  usuario autenticado", "Datos mock 10 filas").

## Output contract (qué entrega esta skill)

Por cada ejecución (modo `generate` o `refine`) producir:

1. Los ficheros HTML en `specs/[XXX-feature-name]/mockups/` siguiendo
   naming convention y estados obligatorios.
2. `specs/[XXX-feature-name]/mockups/README.md` con:
   - Tabla de flujos generados (flow ↔ user story ↔ estados maquetados).
   - Instrucciones para abrir los HTML (doble click o `python -m
     http.server`).
   - Decisiones de diseño tomadas (asunciones).
   - Estados omitidos y justificación.
3. `specs/[XXX-feature-name]/mockups/CHANGELOG.md` con una entrada por
   ejecución (fecha, modo, ficheros afectados, resumen).
4. Bloque de resumen al usuario indicando: nº de flujos, nº de pantallas
   totales, estados cubiertos, y los handoffs sugeridos
   (`bolt-plan` para consumir los mockups, `bolt-mockup refine` para
   iterar).

## Deliverables checklist (antes de cerrar la ejecución)

- [ ] Escenario verificado (contiene `frontend`); si no, abortar.
- [ ] Spec leída (requirements.md).
- [ ] Constitution leída (colores/typografía/a11y baseline).
- [ ] Por cada User Story con UI: al menos `default` + un estado de error
      (`error` o `validation`).
- [ ] HTMLs incluyen el `<script>` CDN de Tailwind v4 exacto.
- [ ] Annotation strip presente en cada HTML.
- [ ] `README.md` y `CHANGELOG.md` generados / actualizados.
- [ ] Naming convention respetada.
- [ ] Sin frameworks JS; HTML válido.
- [ ] Mockups commiteables (sin paths absolutos, sin secretos, sin
      contenido real de cliente).

## Do / Don't

**Do**

- Usar una paleta **neutral de baja fidelidad** (grises) consistente en
  todos los HTMLs del feature.
- Reutilizar las mismas clases de utilidad en todos los HTMLs del feature.
- Listar asunciones explícitamente en el annotation strip.
- Anotar transiciones entre pantallas en `README.md` (flow diagram en
  Mermaid si ayuda).
- Pedir feedback concreto por estado / pantalla, no en bloque.

**Don't**

- No generar **logos** reales ni branding final.
- No introducir lógica funcional (no JS de negocio, no fetch).
- No usar librerías de componentes distintas de Tailwind v4 CDN.
- No invertir tiempo en píxel-perfect: el objetivo es validar
  contenido/flujo, no aspecto final.
- No saltarse estados obligatorios (especialmente `error` y `empty`).
- No commitear datos reales de cliente como ejemplo.

## Review framing (cuando entregues al usuario)

Cuando termines, presenta los mockups con esta estructura:

```markdown
## Mockups generados — `[XXX-feature-name]`

**Modo**: generate | refine
**Flujos**: N · **Pantallas totales**: M

| Flujo | Pasos | Estados maquetados |
|-------|-------|--------------------|
| signup | step1, step2 | default, empty, loading, error, success |

**Asunciones**:
- ...

**Estados omitidos**:
- ...

**Siguiente paso recomendado**:
- Revisar los HTMLs (`open specs/.../mockups/signup-step1-default.html`).
- Devolver feedback por estado / pantalla.
- Cuando el conjunto esté validado → invocar `bolt-plan` (consumirá los
  mockups como referencia visual para el plan técnico).
```

## Related skills / agents

- Upstream: `bolt-feature` (genera spec y declara escenario).
- Downstream: `bolt-plan` (consume mockups como input visual), `bolt-implement`
  (referencia visual durante construcción).
- Refinamiento: invocar `bolt-mockup` agent con modo `refine`.
- Para diagramas que complementen los mockups: `mermaid-creator`.

## References

- Tailwind CSS v4 browser build:
  <https://tailwindcss.com/docs/installation/play-cdn>
- WCAG 2.1 AA contrast guidelines (aplicar a la paleta de grises usada).
