# Plan: Integración de Penpot en Bolt Framework (dual-client Claude + Copilot)

> 📖 Para **usar** la integración (no implementarla), ver la
> [Guía de uso de Penpot](penpot-usage-guide.md).

> Este documento vive en `docs/integrations/penpot-integration-plan.md` y se versiona desde este repositorio.

## Contexto

El Bolt Framework cubre el SDLC asistido por IA con artefactos duales (Copilot en
`.github/agents/*.agent.md` + Claude en `.claude/agents/*.md`, con metodología única en
`.claude/skills/*/SKILL.md`). Hoy el diseño UI vive en HTML estático: `bolt-mockup`
(low-fi) y `bolt-ux-design` (design system + HTML production-grade). **No existe ninguna
herramienta de diseño visual ni puente diseño→código.**

Penpot (open-source, MPL-2.0, self-hostable) cierra ese hueco: aporta una fuente de
verdad de diseño, export de design tokens (W3C DTCG → CSS/Tailwind) y un **MCP server
oficial** (en el core de Penpot desde finales de 2025) que permite a Claude/Copilot leer
el diseño directamente y generar código alineado.

**Objetivo:** integrar Penpot de forma operativa en ambos clientes, con instalación
self-hosted por defecto vía **Podman**, pregunta condicionada a proyectos con UI dentro
del flujo de constitution, y un agente/skill `bolt-penpot` que orqueste el workflow
diseño→código, incluyendo pipeline de tokens y gates de diseño (visión completa).

## Hechos verificados (no asumir, ya confirmados con la doc oficial)

- **Penpot self-hosted**: stack **multi-contenedor** (frontend, backend, exporter,
  postgres, redis) vía compose oficial:
  `https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml`.
  Web UI por defecto en **`http://localhost:9001`**. NO es "una imagen" → se instala con
  `podman compose up` / `podman-compose up`.
- **MCP local**: `http://localhost:4401/mcp`, transporte **http**, sin auth (usa la
  sesión activa del navegador); se arranca con `npx @penpot/mcp@stable`.
- **MCP self-hosted/remoto**: `https://<dominio>/mcp/stream?userToken=<MCP_KEY>`,
  transporte **http**. El MCP key se genera en `Account → Integrations → MCP Server`.
- **Tools del MCP**: `execute_code`, `high_level_overview`, `penpot_api_info`,
  `export_shape`, `import_image` (este último solo en modo local).
- **Tokens**: `@penpot-export/cli` (npm) exporta CSS/SCSS/W3C JSON; plugin de Tailwind
  v3/v4 en Penpot Hub. La API REST de tokens aún NO está liberada (issue penpot#7916) →
  el pipeline va por el CLI, no por endpoint REST.

## Principios de arquitectura (decisiones clave)

1. **Este repo es la plantilla del framework.** `Init.ps1`/`init.sh` scaffoldean el
   proyecto destino. Toda la integración Penpot debe añadirse a los **artefactos fuente**
   (scopes, skills, agents, scripts) para que los proyectos generados la hereden.
2. **La instalación de Penpot NO corre inline en Init.ps1.** El wizard solo **registra la
   decisión**. Un script bootstrap **idempotente y opt-in** bajo `.boltf/scripts/` hace el
   `podman compose up` después. Init no debe levantar un stack de 5 contenedores.
3. **MCP dual-client = dos destinos.** El MCP de Penpot debe llegar a **ambos**:
   - Copilot → `.vscode/mcp.json` (vía el `mcp-tools/*.json` del scope frontend, patrón ya
     existente).
   - Claude → `.mcp.json` en raíz del proyecto destino. **Hoy ningún script fusiona
     `.mcp.json`** → el plan debe crear ese puente explícitamente (ver Fase 3). Este es el
     punto que más fácilmente se queda a medias.
4. **Todo Penpot es opt-in y UI-gated.** Solo se ofrece si el scope `frontend` está
   activo. Sin UI, ni preguntas ni provisión.
5. **Posicionamiento**: `bolt-penpot` **complementa**, no reemplaza, a `bolt-mockup`
   (low-fi rápido sin herramienta) ni a `bolt-ux-design` (design system autónomo). Penpot
   es para equipos con rol de diseño / fuente de verdad visual.

## Fases de implementación

Orden de ejecución. Fases 1–4 = núcleo operativo (los 4 requisitos). Fases 5–6 = resto de
la visión completa (mayor valor, mayor superficie).

---

### Fase 1 — Pregunta UI-gated en el flujo de constitution

Penpot se pregunta en **dos capas** (ambas existen hoy y deben quedar coherentes):

**1a. Wizard `Init.ps1` / `init.sh`** — añadir bloque condicionado a frontend, junto a la
selección de framework frontend (`Init.ps1` ~líneas 693–711; `init.sh` equivalente):

```powershell
# Penpot design tool (solo si frontend activo) — tras FrontendFramework
$d.DesignTool = "none"
if ($d.Scopes -contains "frontend") {
    $d.DesignTool = Read-Choice `
        -Title "Visual design tool integration (Penpot)" `
        -Options @(
            "Penpot self-hosted (Podman, local) — recommended",
            "Penpot remote/existing instance (provide URL+token later)",
            "None (HTML mockups only)"
        ) `
        -Values @("penpot-local", "penpot-remote", "none") `
        -Default 1
}
```

- Persistir la decisión en `scopes.yaml` (función `New-ScopesYaml`, sección `decisions`),
  p. ej. `decisions.frontend.design-tool: penpot-local`. Replicar en `init.sh`.
- **Reutiliza** las funciones existentes `Read-Choice`/`Read-MultiChoice`/`Read-YesNo`
  (`Init.ps1` líneas 84–236) — no crear nuevas.

**1b. Refinement del agente `bolt-constitution`** — la pregunta de diseño se confirma en la
constitution del scope frontend. Añadir un artículo nuevo en
`.boltf/scopes/frontend/memory/constitution.md` (p. ej. **Sección 2.4: Design Tooling**)
con opciones Penpot-local / Penpot-remoto / None, marcado *"Applies to: frontend scope
only"*. El agente ya presenta automáticamente los artículos del scope activo; no requiere
cambios de código en el skill, solo el artículo.

**Archivos:** `Init.ps1`, `init.sh`,
`.boltf/scopes/frontend/memory/constitution.md`,
`.boltf/scopes/frontend/scope.yaml` (provisión condicional, ver Fase 4).

---

### Fase 2 — Script bootstrap de Penpot con Podman (opt-in, idempotente)

Crear scripts cross-platform bajo `.boltf/scripts/`:

- `Install-Penpot.ps1` (Windows/pwsh) y `install-penpot.sh` (bash).

Responsabilidades (idempotentes — re-ejecutables sin romper nada):

1. Detectar `podman` y `podman-compose` (o `podman compose`); si falta, instruir
   instalación y salir con mensaje claro. **Podman por defecto**; permitir override a
   docker vía flag `-Runtime docker` solo si el usuario lo pide.
2. Descargar el `docker-compose.yaml` oficial de Penpot a
   `.boltf/penpot/docker-compose.yaml` si no existe (compose es compatible con Podman).
3. Levantar el stack: `podman compose -p penpot -f .boltf/penpot/docker-compose.yaml up -d`.
4. Esperar a que `http://localhost:9001` responda (health check con timeout).
5. Imprimir siguientes pasos: crear cuenta, generar MCP key en
   `Account → Integrations → MCP Server`, y ejecutar el script de wiring MCP (Fase 3).
6. Flags: `-Stop` / `-Down` para parar; `-Status` para estado.

> El script **no** lo invoca Init. Se ejecuta manualmente (o lo dispara `bolt-penpot` en
> modo `setup`) cuando `decisions.frontend.design-tool = penpot-local`.

**Verificación obligatoria (no testeable en plan-mode):** el camino podman-compose tiene
particularidades frente a Docker (red rootless, volúmenes, `podman compose` vs
`podman-compose`). Validar manualmente en la primera ejecución.

**Archivos:** `.boltf/scripts/powershell/Install-Penpot.ps1`, `.boltf/scripts/bash/install-penpot.sh`,
`.boltf/penpot/docker-compose.yaml` (descargado), `.boltf/penpot/.gitignore` (ignorar
volúmenes/datos locales).

---

### Fase 3 — Configuración MCP dual-client (Claude + Copilot)

**3a. Copilot (patrón existente):** añadir el server `penpot` a
`.boltf/scopes/frontend/mcp-tools/default.mcp.servers.json` y a `allowedServers` en
`default.mcp.settings.json`:

```jsonc
"penpot": {
  "type": "http",
  "url": "${input:penpot-mcp-url}"   // local: http://localhost:9001/mcp/stream?userToken=...
}                                      //  o http://localhost:4401/mcp (bridge npx)
```

Añadir el `input` correspondiente (`promptString`, password) en el bloque `inputs`.

**3b. Claude (puente que falta):** Claude lee `.mcp.json` en la raíz del proyecto destino,
y **hoy nada lo genera**. Crear script `Sync-McpConfig.ps1` + `sync-mcp-config.sh` en
`.boltf/scripts/` que:

- Lea los `mcp-tools/*.servers.json` de los scopes activos (según `scopes.yaml`).
- Genere/actualice **ambos** destinos del proyecto: `.vscode/mcp.json` (Copilot) y
  `.mcp.json` (Claude), traduciendo el formato si difiere (Claude usa `mcpServers`,
  Copilot usa `servers` + `inputs`).
- Sea idempotente (merge, no sobrescritura ciega de servers existentes).

> Este script resuelve un gap preexistente del framework (la fusión de `.mcp.json` no
> existía), no solo Penpot. Documentarlo como tal.

**3c. Documentación de descubrimiento:** registrar Penpot MCP en las tablas de
`CLAUDE.md` y `.github/copilot-instructions.md` donde se listan MCPs/artefactos.

**Decisión local vs remoto** (según respuesta del usuario): por defecto self-host local
(`localhost`), con variable/input que permite apuntar a instancia remota
(`https://<dominio>/mcp/stream?userToken=...`).

**Archivos:** `.boltf/scopes/frontend/mcp-tools/default.mcp.servers.json`,
`.boltf/scopes/frontend/mcp-tools/default.mcp.settings.json`,
`.boltf/scripts/powershell/Sync-McpConfig.ps1`, `.boltf/scripts/bash/sync-mcp-config.sh`,
`CLAUDE.md`, `.github/copilot-instructions.md`.

---

### Fase 4 — Agente + skill `bolt-penpot` (dual-client)

Seguir el patrón verificado (skill canónica + shell Claude minimal + shell Copilot
extendido con handoffs). El `name` del agente debe casar con el directorio del skill.

**4a. Skill canónica** `.claude/skills/bolt-penpot/SKILL.md` — frontmatter `name` +
`description` con triggers ("penpot", "design tool", "design tokens", "diseño→código",
"/bolt-penpot"). Modos:

- `setup` — guía instalación (dispara Fase 2) + wiring MCP (Fase 3) + generación de MCP key.
- `read` — vía MCP (`high_level_overview`, `export_shape`): extrae componentes, estados,
  tokens del archivo Penpot.
- `validate` — verifica que el diseño cubre los estados requeridos por la spec (default,
  empty, loading, error, success) — alineado con `bolt-ui-mockups`.
- `handoff` — exporta tokens (Fase 5) y produce brief para `bolt-implement`.
- `sync` — detecta drift entre tokens de Penpot y `tokens.css` del repo.

**4b. Shell Claude** `.claude/agents/bolt-penpot.md` — frontmatter minimal
(`name`, `description`, `tools: Read, Edit, Write, Grep, Glob, Bash, Skill, WebFetch, Task,
mcp__github__*, mcp__context7__*, mcp__penpot__*`, `model: sonnet`), cuerpo breve: "carga y
sigue la skill `bolt-penpot`", skills auxiliares (`bolt-ui-mockups`, `bolt-framework`),
próximos subagentes (`bolt-plan`, `bolt-implement`, `bolt-architect`).

**4c. Shell Copilot** `.github/agents/bolt-penpot.agent.md` — frontmatter con `tools`
(estilo VS Code), `model`, y `handoffs` hacia `Bolt Mockup`, `Bolt Plan`, `Bolt Implement`,
`Bolt Architect`, `Bolt Documentation`. Sección `Methodology` apuntando a la skill.

**4d. Provisión por scope:** añadir item en `.boltf/scopes/frontend/scope.yaml`
(`auto_provision` condicionado a `design-tool != none`) que copie la skill al proyecto
destino. Registrar el skill en la copia de `available-skills` si aplica.

**Archivos:** `.claude/skills/bolt-penpot/SKILL.md`, `.claude/agents/bolt-penpot.md`,
`.github/agents/bolt-penpot.agent.md`, `.boltf/scopes/frontend/scope.yaml`,
tablas en `CLAUDE.md`.

---

### Fase 5 — Pipeline de design tokens (Penpot → Tailwind v4)

- Documentar/instalar `@penpot-export/cli` como devDependency en proyectos frontend.
- Plantilla de config `.penpot-export.config.js` que exporte a `tokens.css`
  (CSS custom properties) compatible con el `@theme` de Tailwind v4 que ya consume
  `bolt-ux-design`.
- Script npm `tokens:export` y, opcionalmente, paso en CI (engancha con `bolt-cicd`).
- El modo `sync` de `bolt-penpot` (Fase 4a) consume este pipeline para detectar drift.

**Archivos:** plantilla `.penpot-export.config.js` bajo
`.boltf/scopes/frontend/templates/`, item de provisión en `scope.yaml`, doc en la skill.

---

### Fase 6 — Gate de diseño en DISCOVERY + sync con `bolt-ux-design`

**6a. Gate de revisión de diseño** (entre `bolt-mockup` y `bolt-plan`): añadir a la
constitution frontend un gate "Penpot design approved" (existe archivo Penpot aprobado que
cubre los estados requeridos). `bolt-plan` lo verifica antes de generar el plan cuando
`design-tool != none`. Documentar el handoff `bolt-penpot → bolt-plan`.

**6b. Modo `sync` en `bolt-ux-design`** — **coste elevado, flag explícito:**
`bolt-ux-design` **no tiene skill**; son ~700 líneas embebidas en el shell Copilot
(`.github/agents/bolt-ux-design.agent.md`) y **carece de shell Claude**. Enriquecerlo
implica: (i) editar el agente Copilot para añadir un modo `sync` (lee Penpot vía MCP →
actualiza `tokens.css` si hay drift → reporta inconsistencias), y (ii) opcionalmente
extraer la metodología a una skill `bolt-ux-design` y crear el shell Claude para paridad
dual-client (refactor mayor, recomendable pero separable). Evaluar si 6b se hace ahora o se
pospone como tarea independiente.

**Archivos:** `.boltf/scopes/frontend/memory/constitution.md` (gate),
`.claude/agents/bolt-plan.md` + `.github/agents/bolt-plan.agent.md` (verificación de gate),
`.github/agents/bolt-ux-design.agent.md` (modo sync), opcional nueva
`.claude/skills/bolt-ux-design/SKILL.md` + `.claude/agents/bolt-ux-design.md`.

---

## Resumen de archivos

**Nuevos:**

- `docs/integrations/penpot-integration-plan.md` (este plan, paso 0)
- `.boltf/scripts/powershell/Install-Penpot.ps1` + `.boltf/scripts/bash/install-penpot.sh`
- `.boltf/scripts/powershell/Sync-McpConfig.ps1` + `.boltf/scripts/bash/sync-mcp-config.sh`
- `.boltf/penpot/docker-compose.yaml` (+ `.gitignore`)
- `.claude/skills/bolt-penpot/SKILL.md`
- `.claude/agents/bolt-penpot.md`
- `.github/agents/bolt-penpot.agent.md`
- `.boltf/scopes/frontend/templates/.penpot-export.config.js`

**Modificados:**

- `Init.ps1`, `init.sh` (pregunta UI-gated + persistencia en scopes.yaml)
- `.boltf/scopes/frontend/memory/constitution.md` (artículo Design Tooling + gate)
- `.boltf/scopes/frontend/scope.yaml` (provisión condicional skill + tokens)
- `.boltf/scopes/frontend/mcp-tools/default.mcp.servers.json` + `.settings.json`
- `CLAUDE.md`, `.github/copilot-instructions.md` (tablas de descubrimiento)
- `.claude/agents/bolt-plan.md`, `.github/agents/bolt-plan.agent.md` (gate)
- `.github/agents/bolt-ux-design.agent.md` (modo sync — Fase 6b, coste alto)

## Verificación end-to-end

1. **Init UI-gated:** correr `Init.ps1` con scope frontend → aparece la pregunta Penpot;
   sin frontend → no aparece. Confirmar `decisions.frontend.design-tool` en `scopes.yaml`.
2. **Constitution:** ejecutar `bolt-constitution` en un proyecto con frontend → el artículo
   Design Tooling se presenta y la decisión queda en la constitution mergeada.
3. **Podman install:** `.boltf/scripts/powershell/Install-Penpot.ps1` → `podman ps` muestra los
   contenedores Penpot; `http://localhost:9001` carga el UI. Re-ejecutar = idempotente.
   Probar `-Stop`.
4. **MCP dual:** ejecutar `Sync-McpConfig.ps1` → existen `.mcp.json` (con `mcpServers.penpot`)
   y `.vscode/mcp.json` (con `servers.penpot`). En Claude Code: `claude mcp list` muestra
   penpot; invocar una tool (`high_level_overview`) responde. En Copilot: el server aparece
   y responde.
5. **bolt-penpot:** invocar el agente en ambos clientes; modo `read` extrae un componente
   de un archivo Penpot de prueba vía MCP.
6. **Tokens:** `npm run tokens:export` genera `tokens.css`; Tailwind v4 lo consume sin error.
7. **Gate:** `bolt-plan` se detiene/avisa si no hay diseño Penpot aprobado y `design-tool != none`.

## Riesgos / notas

- **podman-compose vs `podman compose`**: detectar cuál está disponible; sintaxis de red
  rootless puede requerir ajustes en el compose oficial (verificación manual obligatoria).
- **Endpoint MCP self-hosted**: confirmar en la primera ejecución si el self-host expone
  `/mcp/stream` en `:9001` o si conviene el bridge `npx @penpot/mcp@stable` (`:4401`).
  Documentar el que funcione; el plan deja ambos como candidatos verificables.
- **Fase 6b** (bolt-ux-design sync) es la de mayor coste por la deuda estructural del
  agente; separable de las Fases 1–5 si se quiere entregar antes el núcleo + tokens.
- Licencia Penpot **MPL-2.0**: uso comercial y self-host sin restricciones relevantes.
