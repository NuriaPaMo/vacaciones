# Scopes packaging

Este directorio define qué artefactos se pueden copiar al proyecto destino por scope.

## Practice-Based Initialization (Two-Step Workflow)

**Bolt Framework v2.0** introduces a two-step initialization pattern:

### Step 1: Init.ps1 — Practice Selection & Basic Configuration

When you run `Init.ps1`, you select a **Practice** that pre-configures scopes:

| Practice         | Pre-Selected Scopes                     | Use Case                                          |
| ---------------- | --------------------------------------- | ------------------------------------------------- |
| **Apps & Infra** | `backend`, `frontend`, `cloud-platform` | Full-stack applications with cloud infrastructure |
| **Data & AI**    | `data`, `ai`, `integration`             | Data platforms, analytics, AI/ML solutions        |
| **CRM**          | `crm`                                   | Dynamics 365, Power Platform, Dataverse solutions |
| **Custom**       | Manual selection (advanced)             | Fine-grained scope selection                      |

**Output of Step 1**:

- `.boltf/scopes.yaml` — Active scopes + wizard decisions
- `.boltf/memory/constitution.md` — Basic constitution template with metadata

### Step 2: `@Bolt Constitution` — File Provisioning & Constitution Merge

After running `Init.ps1`, you invoke the `@Bolt Constitution` agent (or manually call the `skill-bolt-setup-constitution` skill) to complete setup:

**What it does**:

1. **Merge constitutions**: Combines scope-specific `memory/constitution.md` files into the master constitution
2. **Provision files**: Copies skills, agents, templates based on `scope.yaml` configurations
3. **Generate report**: Creates `.boltf/provision-report.md` with inventory of provisioned files

**Why two steps?**

- **Separation of concerns**: Init.ps1 collects decisions; skill handles complex provisioning logic
- **Reduced complexity**: Init.ps1 stays <500 lines (down from 837)
- **Flexibility**: You can review/modify scopes.yaml before provisioning
- **Agent-driven**: Provisioning uses the full power of Copilot agents

### Quick Start

```bash
# Step 1: Initialize with Practice
powershell -File Init.ps1 -OutputDirectory ./my-project -ProjectType green

# Select "Apps & Infra" → Auto-selects: backend, frontend, cloud-platform

# Step 2: Provision files
cd my-project
# In VS Code chat: @Bolt Constitution
```

---

## Tipos de elementos soportados

- `templates`
- `agents`
- `prompts`
- `instructions`
- `skills`

## Convención `mcp-tools`

Cada scope puede incluir una carpeta `mcp-tools/` con uno o varios JSON de configuración MCP.

Para aplicar uno de estos JSON al proyecto destino, añade un `item` en `scope.yaml` con:

- `source.type: local_file`
- `source.path: scopes/<scope>/mcp-tools/<archivo>.json`
- `destination.folder: .vscode`
- `destination.name: settings.json`

Para alinear nombres entre `chat.mcp.access.allowedServers` y la configuración real de servidores en VS Code, añade además un segundo `item` con:

- `source.type: local_file`
- `source.path: scopes/<scope>/mcp-tools/default.mcp.servers.json`
- `destination.folder: .vscode`
- `destination.name: mcp.json`

Esto permite versionar presets MCP por scope y proyectarlos en `.vscode/settings.json` y `.vscode/mcp.json` del proyecto generado.

## Archivo de configuración

Cada scope debe incluir un `scope.yaml` con entradas en `items`.

Campos recomendados por item:

- `id`: identificador único dentro del scope.
- `kind`: uno de `templates|agents|prompts|instructions|skills`.
- `enabled`: `true|false`.
- `tags`: array opcional de etiquetas para búsqueda (`0..3` elementos).
  - Recomendación: usar `1..3` etiquetas concretas por item.
  - Evitar etiquetas redundantes con el scope (ej.: en `backend` no hace falta `backend`).
  - Si el item es de `csharp/.net/aspnet`, incluir etiqueta `csharp`.
  - Si el item es de `node/nodejs/nestjs/express/fastify`, incluir etiqueta `nodejs`.
- `source`: definición de origen.
  - `type`: `local_file|local_folder|web|git_repo|context7|awesome_copilot|awesome_skills`
  - según `type`, usar:
    - `path` (local)
    - `url` (web)
    - `repo` y opcional `ref`/`subpath` (git)
    - `library` + `query` (context7)
    - `collection` + `item_path` (awesome_copilot)
    - `catalog_url` + `repository` y opcional `skill_path|plugin|listing_url` (awesome_skills)
  - opcional:
    - `title` (nombre humano del recurso)
    - `notes` (contexto de por qué incluirlo)
  - para fuentes externas (`web|git_repo|context7|awesome_copilot|awesome_skills`) se recomienda incluir metadatos de resolución:
    - `resolved_url`: URL final resuelta usada para descarga.
    - `resolved_ref`: versión/ref concreta (tag/commit/doc-version).
    - `resolved_doc_id`: identificador estable de documento (especialmente útil en `context7`).
    - `content_hash`: hash del contenido descargado (por ejemplo, `sha256:<hex>`).
    - `fetched_at`: fecha/hora de resolución en formato ISO-8601 UTC.
    - `license`: licencia o referencia corta de uso del recurso.
- `destination`: destino en el proyecto generado.
  - `folder`: ruta de carpeta destino (ej. `.github/instructions`)
  - `name`: nombre final de fichero/carpeta en destino.

## Convención `memory/constitution.md` (Scope Constitution)

Cada scope incluye un fichero `memory/constitution.md` que contiene **únicamente los artículos relevantes** extraídos de la constitución maestra (`.boltf/memory/constitution.md`).

### Estructura

- **Secciones comunes 🔄** — Presentes en TODOS los scopes:
  - Preamble, Article I §1.0, Article X (Environments), Article XI (CI/CD), Article XII §12.1-12.2 (Observability), Article XVI (Security), Article XIX (Governance), Signatories, Revision History.
- **Secciones específicas del scope** — Extraídas según la tabla de mapeo:

| Scope             | Artículos específicos                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------- |
| `backend`         | II §2.1, III §3.1/3.3/3.4, IV, V, VI, VII, VIII, XIII §13.1-13.3, XIV, XV (A-D), XVII, XVIII |
| `frontend`        | II §2.2-2.3, III §3.2, VII §7.3-7.4, XIII (E2E), XIV, XV (frontend)                          |
| `cloud-platform`  | I §1.0.1, VIII, IX, XII §12.3, XIII §13.4, XV (E-F)                                          |
| `data`            | V, VI                                                                                        |
| `integration`     | IV, XVII, XVIII                                                                              |
| `ai`              | XIX §19.2 (emphasis)                                                                         |
| `crm`             | VII                                                                                          |
| `work-management` | XI (emphasis), XIX (emphasis)                                                                |

- **Gaps 🆕** — Artículos propuestos con alternativas Microsoft/Azure para áreas no cubiertas por la constitución maestra.

### Registro en `scope.yaml`

Cada `scope.yaml` incluye un item `memory` para el fichero de constitución:

```yaml
- id: <scope>-constitution
  kind: templates
  enabled: true
  tags: ['constitution', 'memory']
  source:
    type: local_file
    path: scopes/<scope>/memory/constitution.md
  destination:
    folder: memory
    name: constitution.md
```

### Backup

La constitución maestra original se conserva en `.boltf/memory/constitution.original.md`.

## Reglas

- No copiar skills de `.boltf/available-skills` salvo decisión de inicialización o del agente Bolt Framework.
- Las rutas locales se resuelven relativas a `.boltf/`.
- Un item puede quedar `enabled: false` para dejarlo documentado sin aplicarlo.

## Reglas mínimas de validación recomendadas

- `source.type=awesome_skills` requiere `catalog_url` y `repository`.
- `tags`, si existe, debe ser array de máximo 3 elementos.
- Items relacionados con C# o Node.js deben incluir `csharp` o `nodejs` respectivamente.
