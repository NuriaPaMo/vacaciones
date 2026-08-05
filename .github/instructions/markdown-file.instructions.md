---
applyTo: '**/*.md'
---

# Markdown File Instructions

When working on any Markdown file, **immediately load** the required skills below before generating
or editing content.

## Required Skills

### Always Load

- **markdown-formatting** — Enforces consistent formatting, Bolt Framework conventions, and
  readability best practices for all `.md`, `.agent.md`, and `.prompt.md` files.

  ```text
  read_file: f:\repos\train-bolt-framework-greenfield\.claude\skills\markdown-formatting\SKILL.md
  ```

### Load When Diagrams Are Involved

If the markdown file contains or requires **Mermaid diagrams**, data models, domain maps, entity
relationships, bounded contexts, or any visual architecture representation, also load:

- **bolt-datamodel-diagramer** — Translates and generates professional Mermaid diagrams from DDD
  specs, entity classes, ASCII art, or free-text descriptions.

  ```text
  read_file: f:\repos\train-bolt-framework-greenfield\.claude\skills\bolt-datamodel-diagramer\SKILL.md
  ```

  Triggers: `translate into mermaid`, `document data model`, `draw context map`,
  `diagram bounded contexts`, `visualize domain model`, `entity diagram`, `model to mermaid`,
  `DDD diagram`, `generate ER diagram`, `domain class diagram`.

## When This Applies

This instruction file activates automatically for every `*.md` file in the workspace. Skills must be
loaded **before** any content is written or modified.
