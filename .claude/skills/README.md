# Bolt Framework Skills — Capacidades Especializadas (dual-client)

Este directorio es la **fuente única** de skills del Bolt Framework. Las skills son
leídas por **ambos clientes**: GitHub Copilot (VS Code) y Claude Code, siguiendo el
estándar abierto **Agent Skills** (`<skill>/SKILL.md`).

## ¿Qué es un Skill?

Un skill es un conjunto de instrucciones especializadas que el asistente de IA carga
ANTES de responder en un dominio concreto. Funcionan como "consultores expertos" que
se activan automáticamente según el contexto de la tarea (triggers en el frontmatter).

## Organización

- **`bolt-*`** — metodología de los agentes del lifecycle (fuente única que consumen
  los shells de `.github/agents/*.agent.md` y `.claude/agents/*.md`).
- **`skill-bolt-*`** — skills transversales del framework (ADR, branch management,
  quality gates, constitution, testing discipline).
- **Skills de apoyo** — `markdown-formatting`, `mermaid-creator`, `mermaid-diagrams`,
  `interface-design`, `tailwind-design-system`, `web-design-reviewer`,
  `bolt-datamodel-diagramer`, `skill-creator`, etc.

## Crear un Skill

Usa la skill **`skill-creator`** (o el agente `@Bolt Skill Creator`) para crear o
mejorar skills siguiendo el estándar Agent Skills.

## Frontmatter obligatorio (SKILL.md)

```yaml
---
name: nombre-del-skill
description: Descripción en una línea
version: 1.0.0
triggers:
  - patron1
  - patron2
---
```
