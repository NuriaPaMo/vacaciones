# Bolt Framework - GitHub Copilot Instructions

> This file provides context to GitHub Copilot about the Bolt Framework methodology used in this workspace.

## What is Bolt Framework?

Bolt Framework (AI-Driven Development Lifecycle) is an AI-powered software development methodology. It guides development through six phases:

1. **INCEPTION** - Project definition and constitution
2. **DISCOVERY** - Requirements, features, and planning
3. **CONSTRUCTION** - Implementation with quality gates
4. **TRANSITION** - Release and documentation
5. **PRODUCTION** - Operations and continuous improvement
6. **RETIREMENT** - Decommissioning and archival

## Interaction Language

Agent interaction and generated documentation use the **project's configured language**
(set it in the constitution / `CLAUDE.md`). The framework does not impose a language.

## Key Concepts

### Constitution (tiered reads — token-optimized)

The project's DNA — tech stack, standards, constraints. Served in three tiers; read the lowest that
answers your need:

- **Tier 0 — scope card (below).** Auto-loaded with this file. Enough to pick the scenario/scope and stack.
- **Tier 1 — `.boltf/memory/constitution.digest.md`.** Condensed, decision-only (~1–2K tokens).
  **Default read before generating code.** Carries every binding decision.
- **Tier 2 — `.boltf/memory/constitution.md`.** Full canonical text (SINGLE SOURCE OF TRUTH). Read only
  for governance/amendments or a detail the digest lacks.

Tier 0/1 are generated from `merged-refinement.yaml` by `skill-bolt-setup-constitution` (Phase 5).

<!-- BOLT:SCOPE-CARD (generated from merged-refinement.yaml — do not edit by hand) -->
> **Project**: full-stack · greenfield · Practice: Apps & Infra
>
> | Scope | Stack |
> |-------|-------|
> | **backend** | C# / .NET 10 · Minimal APIs · Modular Monolith · Simple CQRS (no MediatR) · Azure SQL · EF Core+Dapper · Entra ID · OTel→Azure |
> | **frontend** | Vue 3.x · TypeScript · Vite · SPA · Azure Static Web Apps · Pinia · Vitest · Playwright |
> | **cloud-platform** | Azure Container Apps · Docker · Terraform · Azure Service Bus · Redis · Key Vault · Aspire (local dev) |
>
> **Cross-scope**: Azure DevOps · GitFlow · Rolling · OTel→Azure Monitor · TLS 1.2+ · GDPR · No VNet (greenfield)
>
> **Naming (backend)**: PascalCase classes/methods · _camelCase fields · IInterface · 4sp · 120ch · nullable enabled
> **Naming (frontend)**: kebab-case files · PascalCase components · use+camelCase composables · 2sp · 100ch · no semicolons
>
> Read `.boltf/memory/constitution.digest.md` (Tier 1) before generating code.
<!-- /BOLT:SCOPE-CARD -->

### Features (`specs/XXX-feature-name/`)

Each feature has its own directory with:

- `feature.md` - Feature specification
- `requirements/` - Detailed requirements
- `planning/` - Tasks and implementation plan
- `contracts/` - API contracts

### Agents (`@Bolt*`)

Invoke Bolt Framework workflows via agents:

- `@Bolt Framework` - Main orchestrator
- `@Bolt Feature` - Create feature
- `@Bolt Legacy Analyst` - Analyze legacy code in brownfield (assess / map / rules)
- `@Bolt Mockup` - Generate low-fi UI mockups (DISCOVERY, frontend)
- `@Bolt Penpot` - Penpot design tool integration: setup, read design via MCP, tokens, handoff (frontend)
- `@Bolt Implement` - Implement code
- `@Bolt Testing` - Generate tests
- `@Bolt Status` - Project status

## Code Generation Rules

When generating code in a Bolt Framework project:

1. **Check Constitution First** - Read `.boltf/memory/constitution.digest.md` (Tier 1) for:
   - Allowed languages/frameworks
   - Coding standards
   - Architecture patterns
   - Testing requirements

   Fall back to the full `.boltf/memory/constitution.md` only for governance/amendments or a detail
   the digest lacks.

2. **Follow Specs** - Implementation must match specifications in `specs/`

3. **Quality Gates** - Code must pass:
   - Linting
   - Unit tests
   - Architecture compliance

4. **Documentation** - Include:
   - Code comments
   - API documentation
   - README updates

## File Structure

```text
project/
├── memory/
│   └── constitution.md      # Project DNA
├── specs/
│   └── XXX-feature-name/    # Feature specs
├── src/                     # Source code
├── legacy/                  # Legacy code analysis (brownfield)
└── .github/
    ├── agents/              # Bolt Framework agents (30)
    ├── prompts/             # Reusable prompts
    ├── skills/              # Auto-discovered skills
    └── workflows/           # GitHub Actions
```

## Specialized Agents

Bolt Framework includes 32 specialized AI agents. Invoke them with `@AgentName`:

| Topic           | Agent                 |
| --------------- | --------------------- |
| Orchestration   | `@Bolt Framework`     |
| Legacy analysis | `@Bolt Legacy Analyst`|
| Architecture    | `@Bolt Architect`     |
| Domain modeling | `@Bolt DDD`           |
| Design tooling  | `@Bolt Penpot`        |
| Testing         | `@Bolt Testing`       |
| Implementation  | `@Bolt Implement`     |
| Documentation   | `@Bolt Documentation` |
| Operations      | `@Bolt Ops`           |
| Releases        | `@Bolt Release`       |
| Research        | `@Bolt Researcher`    |

📚 **Full list**: [.github/agents/README.md](.github/agents/README.md)

## Skills - Specialized Capabilities

Bolt Framework includes specialized **skills** (single source for both clients) auto-discovered from `.claude/skills/<name>/SKILL.md`. When working on specific tasks, the AI automatically loads relevant skills.

### Available Skills

| Skill                                                      | Domain                        | Use When                                                                                         |
| ---------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------ |
| [bolt-framework](../.claude/skills/bolt-framework/)           | Bolt Framework Methodology    | Working on Bolt Framework projects, managing lifecycle                                           |
| [bolt-adr](../.claude/skills/bolt-adr/)                       | Architecture Decision Records | Documenting architectural decisions, technology selections, or design patterns using MADR format |
| [skill-creator](../.claude/skills/skill-creator/)             | Skill Creation                | Creating or improving Agent Skills                                                               |
| [markdown-formatting](../.claude/skills/markdown-formatting/) | Markdown Best Practices       | Writing or editing any Markdown document (.md, .agent.md, .prompt.md)                            |
| [interface-design](../.claude/skills/interface-design/)       | Interface Design              | Building dashboards, admin panels, SaaS apps, tools, settings pages, and data interfaces         |
| [mermaid-creator](../.claude/skills/mermaid-creator/)         | Mermaid Diagrams              | Creating any diagram — flowchart, sequence, class, state, ER, C4, and more                       |
| [mermaid-diagrams](../.claude/skills/mermaid-diagrams/)       | Mermaid Diagrams (alt)        | Alternative Mermaid reference with class, sequence, flowchart, ERD, and C4 examples              |
| [tailwind-design-system](../.claude/skills/tailwind-design-system/) | Tailwind Design System  | Building scalable design systems with Tailwind CSS v4, design tokens, component libraries        |
| [skill-tdd-red-green-refactor](../.claude/skills/skill-tdd-red-green-refactor/) | TDD Discipline | Driving development through the Red-Green-Refactor cycle |
| [skill-playwright-e2e](../.claude/skills/skill-playwright-e2e/) | Playwright E2E | Browser automation, Page Object Model, E2E fixtures |
| [bolt-ui-mockups](../.claude/skills/bolt-ui-mockups/)         | UI Mockups (low-fi)           | Generating/refining static low-fi HTML mockups in DISCOVERY before planning                       |
| [bolt-legacy-analyst](../.claude/skills/bolt-legacy-analyst/) | Legacy Discovery (brownfield) | Reading legacy code: assess, map (call graph/data lineage), extract business rules (G/W/T) |
| [skill-characterization-testing](../.claude/skills/skill-characterization-testing/) | Equivalence Testing | Pinning legacy behavior (golden master / parity) to prove the modernized code is equivalent |

### Creating Custom Skills

Want to add a new skill? Ask Copilot:

```text
"Help me create a skill for [domain]"
```

Copilot will guide you through the process using the new-skill guidelines.

## GitHub Issues Synchronization

### Commit message format

Commit messages **MUST** reference the issue ID as primary identifier:

```text
feat(#128): descripción breve del cambio

Detalle de los cambios...

Closes #128
```

- **ID first**: always use `#<issue-number>` as the scope, not feature/bolt names.
- **Closing keyword**: include `Closes #<id>` in the body so GitHub auto-closes the issue on merge.
- **Conventional Commits type**: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.
- **If ID is not known**: use `<feature name|bolt name>` and WARN the user.

### Creating features, bolts, specs and tests

**WHENEVER** a new feature, bolt, spec or test is created by Bolt Framework agents, ALSO create a
corresponding GitHub issue:

1. Use the project's GitHub Project board.
2. Understand the project's custom fields to properly categorize the issue.
3. Use sub-issues for a feature's bolts, and a bolt's tasks.
4. Prefer MCP tools when available.
5. **Store the issue ID** in the corresponding spec/planning file (`issue: #<id>`).
6. Issue dependencies must reflect feature/bolt dependencies and be documented as sub-issues.
7. Feature branches are named `feature/<feature-name>`.
8. Bolt branches are named `bolt/<feature-name>-<bolt-name>`.

### Updating features, bolts, specs and tests

**WHENEVER** an existing feature, bolt, spec or test is updated by Bolt Framework agents, ALSO
update the corresponding GitHub issue:

1. Locate the issue ID from the spec/planning file (`issue: #<id>`).
2. Update the issue description, status, and custom fields to reflect the changes.
3. Review the issue comments for additional context or feedback.
4. Keep issue dependencies in sync with feature/bolt dependencies (sub-issues).
5. Prefer MCP tools when available.

## Remember

- 🔒 **Constitution is law** - Never violate its constraints
- 📋 **Specs before code** - Features need specifications first
- 🧪 **Test everything** - TDD/BDD approach
- 📝 **Document decisions** - ADRs for architecture
- 🔄 **Iterate small** - Micro-iterations, frequent validation
- 🎯 **Use skills** - Load relevant skills for specialized tasks
- 🎯 **Session efficiency rules are mandatory** — see `.claude/skills/session-efficiency/SKILL.md`

---

*Bolt Framework v2.0.0*
