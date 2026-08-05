---
name: bolt-datamodel-diagramer
description: "Translate, generate, and document data models as Mermaid diagrams for Bolt Framework DDD projects. ALWAYS use when the user asks to visualize, translate, diagram, or document: DDD Context Maps, bounded contexts, domain aggregates, entity relationships, data models, value objects, domain events, or any ASCII/text-based model representation. Triggers: 'translate into mermaid', 'document data model', 'draw context map', 'diagram bounded contexts', 'visualize domain model', 'entity diagram', 'model to mermaid', 'DDD diagram', 'data model documentation', 'generate ER diagram', 'domain class diagram'."
---

# Bolt Data Model Diagramer

Translate and generate professional **Mermaid diagrams** from any data model source: DDD Context
Maps, domain aggregates, entity classes, ASCII art, or free-text descriptions — following Bolt
Framework conventions for documentation.

## Input Sources Supported

| Source | Examples |
|--------|----------|
| **ASCII Art** | Context maps, simple box diagrams inside code/markdown |
| **DDD Specifications** | `specs/**/feature.md`, `.boltf/memory/constitution.md` bounded context sections |
| **C# Entity Classes** | EF Core `DbContext`, `IEntity`, aggregate roots in `src/backend/` |
| **Plain Text** | Free-form description of entities and relationships |
| **Existing Diagrams** | Convert one Mermaid type to another (e.g., class → ER) |

---

## Step-by-Step Workflow

### 1. Identify Source

Read the target content — a file, selection, or user description. Determine:

- Is it already structured (code, YAML)? → extract directly
- Is it ASCII art? → parse boxes, arrows, and labels
- Is it a free-text description? → infer entities and relationships

### 2. Classify the DDD Artifact

| Artifact | Content Clues | → Mermaid Type |
|----------|--------------|----------------|
| **Context Map** | Bounded contexts, Upstream/Downstream, ACL, Events between contexts | `flowchart TB` |
| **Domain Model** | Aggregates, Value Objects, Entities, Domain Events | `classDiagram` |
| **Entity / Database Schema** | DB tables, foreign keys, EF Core models | `erDiagram` |
| **Domain Flow** | Commands → Handlers → Events → side effects | `sequenceDiagram` |
| **State Machine** | Entity lifecycle states and transitions | `stateDiagram-v2` |

### 3. Generate Mermaid

Apply the corresponding template below. Always:

- Use icons (emoji) in node labels for readability
- Apply `style` or `classDef` to highlight Core Domain nodes
- Use meaningful relationship labels (e.g. `OrderPlaced`, `ACL`, `Events`, `U/D`)
- Add `%%` comments to explain non-obvious relationships

### 4. Save (if in documentation context)

If running inside `Bolt Documentation` or updating a markdown file:

- Embed inline in the target `.md`
- Save a copy to `docs/diagrams/<artifact-type>-<name>.mmd`

---

## Templates

Load the relevant template file from `templates/` based on the artifact type identified in Step 2:

| Artifact | Template File |
|----------|--------------|
| **Context Map** | [templates/context-map.md](templates/context-map.md) |
| **Domain Model** | [templates/domain-model.md](templates/domain-model.md) |
| **Entity / DB Schema** | [templates/entity-schema.md](templates/entity-schema.md) |
| **Domain Flow** | [templates/domain-flow.md](templates/domain-flow.md) |
| **State Machine** | [templates/state-machine.md](templates/state-machine.md) |

Each template includes: the Mermaid base template, usage rules, and relationship cheat sheets.

---

## Style Guide for This Project

| Context | Fill | Stroke |
|---------|------|--------|
| Core Domain | `#fff3e0` | `#e65100` (3px) |
| Auth / Security | `#fce4ec` | `#b71c1c` (2px) |
| Upstream Provider | `#e1f5ff` | `#01579b` (2px) |
| Downstream Consumer | `#e8f5e9` | `#1b5e20` (2px) |
| Generic Context | `#f3e5f5` | `#4a148c` (2px) |

---

## Quality Checks

Before delivering the diagram, delegate in a new subagent with a different scope to verify:

- [ ] Correct diagram type for the artifact (use table in Step 2)
- [ ] Core Domain node is visually distinct
- [ ] All relationship labels are business-meaningful (not just "→")
- [ ] No orphan nodes (every node has at least one connection)
- [ ] ASCII art / text source is fully represented (no omissions)
- [ ] `style` or `classDef` applied for readability
- [ ] Saved to `docs/diagrams/` if in a documentation context

---

## Related Skills

- `mermaid-creator` — General-purpose Mermaid syntax reference and CLI conversion
- `architect-diagramer` — C4 architecture diagrams and broader system documentation
- `bolt-framework` — Bolt lifecycle context for knowing *where* docs belong
