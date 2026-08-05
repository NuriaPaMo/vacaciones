# Penpot + Bolt Framework — Guía de uso

> Cómo usar Penpot dentro del SDLC asistido por IA del Bolt Framework: fases,
> capacidades, modos de uso, configuración dual-client (Claude Code + GitHub Copilot)
> y el rol del humano en el bucle (HITL).
>
> Referencias: plan de integración → [penpot-integration-plan.md](penpot-integration-plan.md) ·
> metodología (fuente única) → [`.claude/skills/bolt-penpot/SKILL.md`](../../.claude/skills/bolt-penpot/SKILL.md)

---

## 1. Qué es y qué aporta

[Penpot](https://penpot.app) es una herramienta de diseño open-source (MPL-2.0,
self-hostable) que se integra en Bolt como **fuente de verdad visual** para features con
UI. Cierra el hueco entre diseño y código: el agente `bolt-penpot` lee el diseño real a
través del **MCP server de Penpot**, mantiene los **design tokens** sincronizados con el
repositorio y condiciona la planificación a un diseño aprobado.

**Posicionamiento** — Penpot **complementa**, no reemplaza:

| Artefacto | Cuándo | Herramienta |
|---|---|---|
| `bolt-mockup` | Wireframes low-fi rápidos, sin herramienta | HTML + Tailwind CDN |
| `bolt-ux-design` | Design system autónomo generado por IA | Markdown + `tokens.css` |
| **`bolt-penpot`** | **Equipos con rol de diseño / fuente de verdad visual** | **Penpot (MCP)** |

> Penpot es **opcional y opt-in**: solo se ofrece si el proyecto tiene scope `frontend`,
> y solo se activa si en la constitution se elige `penpot-local` o `penpot-remote`.

---

## 2. Capacidades

A través del MCP de Penpot, el agente dispone de:

| Capacidad | Herramienta MCP | Uso en Bolt |
|---|---|---|
| Visión general del fichero | `high_level_overview` | Mapear páginas/boards → flujos/pantallas |
| Exportar componente/forma | `export_shape` | Extraer specs de componentes |
| Metadatos / API | `penpot_api_info` | Contexto del fichero |
| Ejecutar código sobre el diseño | `execute_code` | Consultas avanzadas |
| Importar imagen (solo local) | `import_image` | Aportar assets a Penpot |

Más, vía CLI `@penpot-export/cli`: **export de design tokens** (CSS / SCSS / W3C-DTCG JSON)
hacia `tokens.css` compatible con Tailwind v4 `@theme`.

---

## 3. Dónde encaja en las fases del SDLC

```text
INCEPTION ──► DISCOVERY ──────────────────────────► CONSTRUCTION ──► …
   │             │                                       │
   │        bolt-feature                            bolt-implement
   │             │                                       ▲
   │        bolt-mockup (low-fi opcional)               │ tokens + brief
   │             │                                       │
   └─ constitution│  ┌───────────── bolt-penpot ────────┘
      (pregunta   │  │  setup → read → validate → handoff
       design-tool)▼  ▼              │
                bolt-penpot      [DESIGN GATE]
                (read/validate)      │
                     │               ▼
                     └──────────► bolt-plan  (solo si el gate aprueba)
```

- **INCEPTION / Constitution** — se pregunta si el proyecto integra Penpot
  (solo si hay UI). Decisión registrada en `.boltf/scopes.yaml` → `decisions.frontend.design-tool`.
- **DISCOVERY** — Penpot es la fuente de verdad del diseño. `bolt-penpot` lee y valida el
  diseño; el **Design Gate** impide planear una feature de UI sin un diseño aprobado.
- **CONSTRUCTION (temprana)** — `bolt-penpot handoff` exporta tokens y produce el brief
  para `bolt-implement`.
- **Mantenimiento** — `bolt-penpot sync` detecta drift entre Penpot y `tokens.css`.

---

## 4. Configuración inicial (una vez por proyecto)

### 4.1 Prerrequisito: decisión en la constitution

Durante `Init.ps1` / `init.sh`, si seleccionas el scope **frontend**, aparece:

```text
Visual design tool integration (Penpot)
  1. Penpot self-hosted (Podman, local) — recommended
  2. Penpot remote/existing instance (provide URL + token later)
  3. None (HTML mockups only)
```

Queda en `.boltf/scopes.yaml`:

```yaml
decisions:
  frontend:
    design-tool: penpot-local   # | penpot-remote | none
```

### 4.2 Instalar Penpot self-hosted (Podman por defecto)

> Penpot es un **stack multi-contenedor** (frontend, backend, exporter, postgres, redis),
> no una sola imagen. Se levanta con el compose oficial vía Podman.

**Opción A — desde el propio Init (opt-in).** Al terminar `Init.ps1` / `init.sh`, si
elegiste `penpot-local` y hay Podman instalado, el wizard pregunta *"Launch the Penpot
stack now via Podman?"*. Si aceptas, levanta el stack en ese momento (delega en el script
de abajo). Si no hay Podman o declinas, lo deja para más tarde con instrucciones.

> La instalación es **opt-in**: nunca arranca contenedores sin tu confirmación, y el
> cableado del MCP sigue siendo un paso posterior (requiere la MCP key, que generas tú en
> la UI — ver 4.3).

**Opción B — manualmente** (en cualquier momento):

```powershell
# Windows / PowerShell
.boltf/scripts/powershell/Install-Penpot.ps1            # up (por defecto)
.boltf/scripts/powershell/Install-Penpot.ps1 -Status    # estado
.boltf/scripts/powershell/Install-Penpot.ps1 -Stop      # parar (conserva datos)
```

```bash
# Linux / macOS / WSL
.boltf/scripts/bash/install-penpot.sh                    # up
.boltf/scripts/bash/install-penpot.sh --status
.boltf/scripts/bash/install-penpot.sh --stop
```

El script es **idempotente** y por defecto usa **Podman** (`-Runtime docker` para forzar
Docker). La UI queda en `http://localhost:9001`.

> ⚠️ Podman rootless y el compose oficial pueden requerir ajuste manual la primera vez.
> Verifica con `-Status` / `--status`.

Para `penpot-remote`: omite la instalación y usa la URL de tu instancia corporativa.

### 4.3 Generar la MCP key y cablear el MCP (dual-client)

1. Abre `http://localhost:9001`, crea cuenta y genera la key en
   **Account → Integrations → MCP Server**.
2. Cablea el MCP en **ambos** clientes. El modo seguro (por defecto) **no escribe el
   token en git**:

```powershell
# PowerShell — el token vive en el entorno, no en .mcp.json (que está trackeado)
$env:PENPOT_MCP_URL = 'http://localhost:9001/mcp/stream?userToken=<MCP_KEY>'
.boltf/scripts/powershell/Sync-McpConfig.ps1
```

```bash
# Bash — requiere jq
export PENPOT_MCP_URL='http://localhost:9001/mcp/stream?userToken=<MCP_KEY>'
.boltf/scripts/bash/sync-mcp-config.sh
```

Esto genera:

- `.vscode/mcp.json` → **GitHub Copilot** (formato `servers` + `inputs`, pide la URL por prompt).
- `.mcp.json` → **Claude Code** (formato `mcpServers`, referencia `${PENPOT_MCP_URL}`).

> 🔐 **Nunca comitees la MCP key.** El flag `-PenpotMcpUrl` / `--penpot-mcp-url` hornea la
> URL literal en `.mcp.json` (fichero trackeado) y solo debe usarse en setups locales no
> versionados — el script avisa cuando lo haces. Para `penpot-remote` usa **siempre** la
> variable de entorno.

3. Verifica que el endpoint MCP responde realmente (`/mcp/stream` en tu instancia, o el
   bridge `npx @penpot/mcp@stable` en `:4401`) antes de continuar.

---

## 5. Uso por modos del agente `bolt-penpot`

Invoca el agente en cualquiera de los dos clientes:

- **Claude Code**: `Task` con `subagent_type=bolt-penpot`, o `/bolt-penpot`.
- **GitHub Copilot**: `@Bolt Penpot <modo> [contexto]`.

| Modo | Qué hace | Salida |
|---|---|---|
| `setup` | Instala Penpot + cablea el MCP dual-client + verifica conexión | `.mcp.json`, `.vscode/mcp.json` |
| `read` | Extrae componentes, estados y tokens del fichero Penpot vía MCP | `specs/[XXX]/design/penpot-read.md` |
| `validate` | Comprueba que el diseño cubre los estados de UI requeridos | `specs/[XXX]/design/penpot-validate.md` |
| `handoff` | Exporta tokens (`tokens.css`) + brief de implementación | `specs/[XXX]/design/handoff.md` |
| `sync` | Detecta drift entre tokens de Penpot y `tokens.css` (muestra diff) | informe de diff |

**Estados de UI obligatorios** que valida `validate` (matriz compartida con `bolt-ui-mockups`):

| Estado | Cuándo se exige |
|---|---|
| `default` | Siempre |
| `empty` | La pantalla muestra colecciones (lista, tabla, kanban) |
| `loading` | La pantalla depende de datos remotos |
| `error` | Siempre |
| `success` | El paso confirma una acción (submit, save) |

### El Design Gate

Cuando `design-tool ∈ {penpot-local, penpot-remote}`, `bolt-plan` **no planea** una
feature de UI hasta que exista `specs/[XXX]/design/penpot-validate.md` con los estados
aprobados:

- ✅ Gate aprobado → `bolt-plan` continúa, citando el diseño como referencia visual.
- ⛔ Falta o incompleto → avisa y deriva a `bolt-penpot validate` (o `bolt-mockup` low-fi).
- `design-tool = none` → el gate no aplica; rigen los mockups HTML.

### Pipeline de design tokens

```bash
npm install -D @penpot-export/cli     # una vez
npm run tokens:export                  # Penpot → tokens.css (CSS custom properties)
```

Config en `.penpot-export.config.js` (provisionado en el scope frontend). El `tokens.css`
resultante lo consume Tailwind v4 vía `@theme` — el mismo fichero que usa `bolt-ux-design`.

---

## 6. Rol del humano en el bucle (HITL)

Penpot introduce puntos de decisión donde la IA **no debe** actuar sola. El humano es
responsable de:

| Punto HITL | Fase | Por qué el humano decide |
|---|---|---|
| **Elegir integrar Penpot** | Constitution | Decisión estratégica del equipo (¿hay rol de diseño?). |
| **Diseñar en Penpot** | DISCOVERY | El diseño visual lo crea el diseñador; la IA lo lee, no lo inventa. |
| **Aprobar el diseño (Design Gate)** | DISCOVERY → PLAN | El diseño debe estar validado por una persona antes de planear. |
| **Resolver el drift de tokens (`sync`)** | Mantenimiento | La IA **muestra el diff, nunca sobrescribe**; el humano decide adoptar, mantener override o cambiar el design system. |
| **Custodiar la MCP key** | Setup | El secreto lo gestiona el humano (variable de entorno); nunca se comitea. |
| **Verificar el endpoint MCP en vivo** | Setup | Confirmar que la instancia expone el MCP antes de fiarse del flujo. |

Principio rector: **la IA acelera, el humano aprueba.** Los modos `read` / `validate` /
`handoff` producen artefactos revisables (markdown bajo `specs/[XXX]/design/`); el modo
`sync` es explícitamente no destructivo (diff, no overwrite); y el Design Gate convierte la
aprobación humana en un requisito formal del flujo.

---

## 7. Seguridad y operación

- La **MCP key** y el **access token** de Penpot son secretos: variable de entorno, nunca
  en git. Copilot los pide por prompt (`password: true`).
- Los datos locales de Penpot viven bajo `.boltf/penpot/` y están **git-ignored** (incluido
  el `docker-compose.yaml` descargado).
- **Licencia** Penpot: MPL-2.0 — uso comercial y self-host sin restricciones relevantes.
- La **API REST de tokens** de Penpot aún no está liberada (penpot#7916): el pipeline va por
  el CLI `@penpot-export`, no por endpoint REST.

---

## 8. Resolución de problemas

| Síntoma | Acción |
|---|---|
| La UI no responde en `:9001` | `Install-Penpot.ps1 -Status` / `--status`; revisa logs `podman -p penpot logs`. |
| `podman compose` no existe | Instala `podman-compose` (`pip install podman-compose`) o usa `-Runtime docker`. |
| `sync-mcp-config.sh` falla | Falta `jq` — instálalo. |
| Claude no ve el MCP | Verifica `${PENPOT_MCP_URL}` en el entorno y reinicia Claude Code. |
| Copilot no ve el MCP | Comprueba `.vscode/mcp.json` y reinicia VS Code. |
| El MCP no responde | Confirma `/mcp/stream` en tu instancia, o usa el bridge `npx @penpot/mcp@stable` (`:4401`). |
