# Bolt Framework — Toolset Definitions

> Reference for VS Code built-in tools and the **stack-agnostic** MCP server tools used
> by Bolt Framework agents.
>
> Stack-specific MCP servers (cloud provider, IaC, frontend framework, database, DevOps
> platform) are **NOT** part of the framework core — each consuming project wires its own
> in `.mcp.json` and references them from the scope constitutions.

---

## MCP Servers — Core (stack-agnostic) Catalog

### 1. Context7 — Library Documentation

Up-to-date documentation for any library or framework.

| Tool                          | Description                         |
| ----------------------------- | ----------------------------------- |
| `context7/resolve-library-id` | Resolve library name to Context7 ID |
| `context7/query-docs`         | Query documentation for a library   |

**Wildcard**: `'context7/*'`
**Use when**: Researching frameworks, libraries, APIs, or need current documentation

---

### 2. Microsoft Docs — Official Documentation

Official Microsoft / Azure / .NET documentation (useful regardless of stack for general guidance).

| Tool                                          | Description                   |
| --------------------------------------------- | ----------------------------- |
| `microsoft-docs/microsoft_docs_search`        | Search Microsoft Learn docs   |
| `microsoft-docs/microsoft_docs_fetch`         | Fetch full documentation page |
| `microsoft-docs/microsoft_code_sample_search` | Search code samples           |

**Wildcard**: `'microsoft-docs/*'`
**Use when**: Researching official Microsoft best practices

---

### 3. GitHub — Repository Operations

GitHub repository management and operations (issues, PRs, branches, releases, code search).

**Wildcard**: `'github/*'`
**Use when**: GitHub operations, repository management, CI/CD integration, issue sync

---

### 4. Playwright — Browser Automation

Web browser automation and testing (navigation, interaction, snapshots, network/console).

**Wildcard**: `'playwright/*'`
**Use when**: Browser automation, E2E testing, functional exploration

---

> **Project-specific MCP servers** (not framework core): cloud provider (e.g. Azure MCP),
> IaC (e.g. Bicep/Terraform), DevOps platform (e.g. Azure DevOps), frontend framework
> (e.g. Angular CLI), UI library (e.g. PrimeNG), database (e.g. SQL Server). Define these
> per project in `.mcp.json` and reference them from the relevant scope constitution.

---

## MCP Server Usage by Domain (core)

| Domain                 | MCP Servers (core)                   | Priority |
| ---------------------- | ------------------------------------ | -------- |
| **Documentation**      | `'context7/*'`, `'microsoft-docs/*'` | ⭐⭐⭐   |
| **DevOps / SCM**       | `'github/*'`                         | ⭐⭐⭐   |
| **Testing/Automation** | `'playwright/*'`                     | ⭐⭐     |

---

## VS Code Built-in Tools

> ⚠️ **IMPORTANT**: All tool names below are the OFFICIAL VS Code tool names.
> Do NOT use short names in isolation — these are NOT recognized by VS Code.

### Tool Namespace Shortcuts

**Namespace shortcuts** automatically include ALL their subtools:

- `search` → includes `search/codebase`, `search/usages`, `search/changes`, and all other search tools
- `execute` → includes `execute/runTests`, `execute/runInTerminal`, `execute/getTerminalOutput`, and all other execute tools
- `read` → includes all `read/` prefixed tools
- `edit` → includes all `edit/` prefixed tools

**Use shortcuts in agent definitions** instead of listing individual subtools.

### Specialized Tools (Not Covered by Shortcuts)

| Tool                     | Description                    | Category   |
| ------------------------ | ------------------------------ | ---------- |
| `extensions`             | VS Code extensions             | Read-only  |
| `installExtension`       | Install extension              | Execute    |
| `problems`               | Problems panel errors/warnings | Read-only  |
| `terminalLastCommand`    | Last terminal command output   | Read-only  |
| `terminalSelection`      | Terminal selection text        | Read-only  |
| `selection`              | Current editor selection       | Read-only  |
| `getProjectSetupInfo`    | Project setup info             | Read-only  |
| `editNotebook`           | Edit notebook                  | Write      |
| `getNotebookSummary`     | Notebook summary               | Read-only  |
| `newWorkspace`           | Create workspace               | Write      |
| `vscode`                 | VS Code API operations         | Multi-tool |
| `agent`                  | Agent operations               | Multi-tool |
| `todo`                   | Task management                | Multi-tool |
| `web`                    | Web fetch operations           | Multi-tool |
| `memory`                 | Context memory operations      | Multi-tool |

---

## Toolset Categories for Bolt Framework agents

> **RECOMMENDED**: Use namespace shortcuts (`search`, `execute`, `read`, `edit`) instead of
> specific subtools for cleaner, future-proof definitions. Add project-specific MCP wildcards
> on top of these per scope.

### 1. FULL_PLANNING (Read-Only Analysis)

```yaml
tools: [search, read, problems, agent, 'context7/*', 'microsoft-docs/*']
```

**Used by**: Plan, Analyze, Status, Alignment, Architect, Tasks, Improve, Retire, Deps

### 2. FULL_IMPLEMENTATION (Read + Write + Execute)

```yaml
tools: [search, read, edit, execute, problems, todo, agent, 'context7/*', 'microsoft-docs/*']
```

**Used by**: Implement, Testing, Review

### 3. SPEC_FOCUSED (Specifications)

```yaml
tools: [search, read, edit, web, agent, vscode, 'context7/*', 'microsoft-docs/*']
```

**Used by**: Feature, Specify, Clarify, Use Case, Gherkin, DDD

### 4. DOCS_FOCUSED (Documentation)

```yaml
tools: [search, read, edit, web, agent, vscode, 'context7/*', 'microsoft-docs/*']
```

**Used by**: Documentation, ADR, Postmortem

### 5. OPS_FOCUSED (Operations)

```yaml
tools: [search, read, edit, execute, problems, agent, vscode, 'context7/*', 'microsoft-docs/*']
```

**Used by**: Ops, Release, Monitoring

### 6. CONSTITUTION_BUILDER (Project Configuration)

```yaml
tools: [search, read, edit, web, agent, vscode, 'context7/*', 'microsoft-docs/*']
```

**Used by**: Constitution

### 7. CICD_FOCUSED (CI/CD & Pipelines)

```yaml
tools: [search, read, edit, execute, web, agent, vscode, 'context7/*', 'microsoft-docs/*', 'github/*']
```

**Used by**: CI/CD (add your DevOps platform MCP wildcard per project)

### 8. SECURITY_FOCUSED (Security Analysis)

```yaml
tools: [search, read, problems, web, vscode, agent, 'github/*', 'context7/*', 'microsoft-docs/*']
```

**Used by**: Security

### 9. INIT_WORKSPACE (Workspace Initialization)

```yaml
tools: [search, read, edit, execute, todo, web, vscode, agent, memory, 'github/*', 'context7/*', 'microsoft-docs/*']
```

**Used by**: Bolt Framework, Templates

> **Stack-specific toolsets** (e.g. cloud, IaC, frontend framework, database) are defined
> per project by composing the categories above with the project's own MCP wildcards.

---

## Tool Name Reference

### Namespace Shortcuts (Recommended for Agents)

✅ `search`, `execute`, `read`, `edit`, `web`, `vscode`, `agent`, `todo`, `memory`

**Benefits:**

- Each namespace includes ALL its subtools automatically
- Shorter, cleaner agent definitions
- Future-proof (new subtools automatically included)

### Core MCP Servers (Always Quote Wildcards)

✅ `'context7/*'`, `'microsoft-docs/*'`, `'github/*'`, `'playwright/*'`

Project-specific MCP wildcards are added per project on top of these.
