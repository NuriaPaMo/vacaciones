---
name: bolt-penpot
description: >-
  Integrate Penpot (open-source design tool, self-hosted via Podman or remote) into the Bolt Framework design→code workflow for frontend features. Five modes — `setup` (install Penpot + wire MCP dual-client), `read` (extract components, states and tokens from a Penpot file via MCP), `validate` (check the design covers the required UI states), `handoff` (export design tokens + produce an implementation brief for bolt-implement), and `sync` (detect drift between Penpot tokens and tokens.css). Complements bolt-mockup (low-fi HTML) and bolt-ux-design (design system); does not replace them. Triggers — "penpot", "design tool", "design tokens", "diseño a código", "design to code", "exportar tokens", "leer diseño", "sincronizar tokens", "setup penpot", "/bolt-penpot".
---

# Bolt Penpot — Methodology

Bridge **Penpot** (open-source, MPL-2.0, self-hostable design tool) into the Bolt
Framework so that AI agents can read the **real design** and generate aligned code,
keep **design tokens** in sync with the codebase, and gate planning on an approved
design. Penpot is wired to **both clients** (Claude Code via `.mcp.json`, GitHub
Copilot via `.vscode/mcp.json`) through the Penpot MCP server.

**Bolt Framework Stage**: DISCOVERY (design source-of-truth, post `bolt-mockup`,
pre `bolt-plan`) and early CONSTRUCTION (token handoff for `bolt-implement`).
**Responsible Agent**: `bolt-penpot` (dual-client shell).
**Positioning**: complements — does **not** replace — `bolt-mockup` (quick low-fi
HTML wireframes with no tool) and `bolt-ux-design` (autonomous design system).
Penpot is for teams with a design role / a visual source-of-truth.

## Preconditions

1. The project has a **frontend** scope and the constitution declares a design tool:
   `decisions.frontend.design-tool ∈ { penpot-local, penpot-remote }` in
   `.boltf/scopes.yaml` (Section 2.4 of the frontend constitution).
2. For `read`/`validate`/`handoff`/`sync`: a reachable Penpot instance and a
   configured Penpot MCP server (run `setup` first if not).
3. `.boltf/memory/constitution.md` is readable (brand defaults, accessibility level,
   Tailwind version for the token target).

## Verified integration facts

- **Penpot self-hosted** is a **multi-container stack** (frontend, backend, exporter,
  postgres, redis) via the official compose file; web UI default on
  `http://localhost:9001`. It is NOT a single image. Bootstrap with Podman by default.
- **MCP — local**: `http://localhost:4401/mcp` (transport `http`, uses the active
  browser session) via `npx @penpot/mcp@stable`.
- **MCP — self-hosted/remote**: `https://<domain>/mcp/stream?userToken=<MCP_KEY>`
  (transport `http`). Generate the MCP key in `Account → Integrations → MCP Server`.
- **MCP tools**: `execute_code`, `high_level_overview`, `penpot_api_info`,
  `export_shape`, `import_image` (local only).
- **Tokens**: `@penpot-export/cli` exports CSS/SCSS/W3C-DTCG JSON. The REST token API
  is not yet shipped (penpot#7916) → the pipeline goes through the CLI, not REST.

> ⚠️ Verify the live MCP endpoint on first use: a self-hosted instance may expose
> `/mcp/stream` on `:9001`, or you may use the `npx` bridge on `:4401`. Confirm against
> the running instance before baking a URL into config.

## Modes

### Mode `setup` (first run)

Stand up Penpot and wire the MCP into both clients.

1. Read `decisions.frontend.design-tool` from `.boltf/scopes.yaml`.
2. **penpot-local** → run the bootstrap script (Podman by default):
   - PowerShell: `.boltf/scripts/powershell/Install-Penpot.ps1`
   - Bash: `.boltf/scripts/bash/install-penpot.sh`
   - Then guide the user to create an account at `http://localhost:9001` and generate
     an MCP key (`Account → Integrations → MCP Server`).
   **penpot-remote** → collect the instance URL + MCP key (no local install).
3. Wire the MCP into **both** clients with the sync script. **`.mcp.json` is tracked by
   git, so the token must NOT be baked into it.** Default (secure): keep the URL in an
   env var; Copilot prompts for it, Claude reads `${PENPOT_MCP_URL}`:
   - Set `PENPOT_MCP_URL=<url>/mcp/stream?userToken=<KEY>` (PowerShell `$env:`, bash `export`).
   - PowerShell: `Sync-McpConfig.ps1`  · Bash: `sync-mcp-config.sh` (no URL arg).
   - This writes `.vscode/mcp.json` (Copilot, `${input:...}` prompt) and `.mcp.json`
     (Claude, `${PENPOT_MCP_URL}` reference) — **no secret committed**.
   - Only for explicitly-untracked local use may you pass `-PenpotMcpUrl` /
     `--penpot-mcp-url` to bake a literal URL. Never for `penpot-remote` (corporate token).
4. Verify the instance actually exposes the MCP endpoint (confirm `/mcp/stream` on the
   running instance, or use the `npx @penpot/mcp@stable` bridge on `:4401`), then confirm
   the MCP responds (`high_level_overview`).

### Mode `read`

Extract design context from a Penpot file via the MCP.

- Input: the Penpot file/page/board reference and the target feature/spec.
- Use `high_level_overview` to map pages/boards → flows/screens; `export_shape` to
  pull individual components/specs; `penpot_api_info` for metadata.
- Output: a structured summary of components, screen states and tokens, written under
  `specs/[XXX-feature-name]/design/penpot-read.md`.

### Mode `validate`

Check the design covers the **required UI states** for each screen, aligned with the
`bolt-ui-mockups` state matrix.

- Required states per screen: `default`, plus `empty` (collections), `loading` (remote
  data), `error` (always), `success` (confirmations). See the table below.
- Output: a checklist report under `specs/[XXX-feature-name]/design/penpot-validate.md`
  flagging missing states. This report backs the **design gate** before `bolt-plan`.

| State | When required |
|-------|---------------|
| `default` | Always |
| `empty` | Screen shows collections (list, table, kanban) |
| `loading` | Screen depends on remote data |
| `error` | Always |
| `success` | Step confirms a user action (submit, save) |

### Mode `handoff`

Produce the design→code package for `bolt-implement`.

1. Export design tokens via the pipeline (Fase 5): `npm run tokens:export` →
   `tokens.css` (CSS custom properties for Tailwind v4 `@theme`). See
   `.penpot-export.config.js` (provisioned under the frontend scope templates).
2. Produce an implementation brief: component inventory, token references, per-screen
   states, accessibility notes → `specs/[XXX-feature-name]/design/handoff.md`.
3. Hand off to `bolt-implement` (and `bolt-architect` if structural).

### Mode `sync`

Detect drift between Penpot tokens and the repository's `tokens.css`.

- Re-run the token export to a temp file and diff against the committed `tokens.css`.
- Report added/changed/removed tokens; do NOT silently overwrite — surface the diff and
  let the user decide. This mode is also consumed by `bolt-ux-design` (sync mode).

## Token pipeline (Penpot → Tailwind v4)

- Tool: `@penpot-export/cli` (devDependency). Config: `.penpot-export.config.js`.
- Target: `tokens.css` with CSS custom properties consumed by Tailwind v4 `@theme`,
  the same file `bolt-ux-design` already uses. Keep the export idempotent and committed.
- Optional CI step (via `bolt-cicd`) to fail the build on uncommitted token drift.

## Security & config notes

- The Penpot MCP key is a secret. In Copilot it is collected via a `promptString` input
  (`penpot-mcp-url`, `password: true`); in Claude it is baked by the sync script or read
  from the `${PENPOT_MCP_URL}` env var. Never commit the key.
- Local Penpot data lives under `.boltf/penpot/` and is git-ignored.
- Podman rootless networking and the official compose file may need manual adjustment on
  first run — verify with `Install-Penpot.ps1 -Status` / `install-penpot.sh --status`.

## Handoffs

- `bolt-mockup` → `bolt-penpot`: from low-fi HTML to a Penpot source-of-truth.
- `bolt-penpot` (validate) → `bolt-plan`: only plan once the design is approved and
  covers the required states (design gate).
- `bolt-penpot` (handoff) → `bolt-implement`: tokens + brief for implementation.
- `bolt-penpot` → `bolt-architect`: when the design implies structural decisions.
- `bolt-penpot` → `bolt-docs`: living documentation of the design system/tokens.

## Quality gates (before closing the agent)

- [ ] `setup`: both `.mcp.json` and `.vscode/mcp.json` contain the `penpot` server; MCP
      responds to `high_level_overview`.
- [ ] `read`/`validate`: report written under `specs/[XXX]/design/`.
- [ ] `validate`: every screen has at least the required states, or a documented reason.
- [ ] `handoff`: `tokens.css` regenerated and `handoff.md` produced.
- [ ] No MCP key committed to the repo.
- [ ] Penpot positioned as complement to `bolt-mockup`/`bolt-ux-design`, not a duplicate.

## Auxiliary skills

- `bolt-ui-mockups` — shared UI state matrix and DISCOVERY conventions.
- `bolt-framework` — lifecycle/phase reference.
- `markdown-formatting` — for the design reports and briefs.

## See also

- User guide: `docs/integrations/penpot-usage-guide.md` (phases, modes, HITL role).
- Integration plan: `docs/integrations/penpot-integration-plan.md`.
