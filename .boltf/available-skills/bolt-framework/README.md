# Bolt Framework Skills

Specialized skills for the Bolt Framework methodology (Bolt Framework).

## Overview

This folder contains skills specifically designed to support the Bolt Framework, an AI-Driven Development Lifecycle methodology that guides projects through 6 lifecycle phases with micro-iterations (Bolts).

## Skills

| Skill                                       | Description                                                  | Use When                                      |
| ------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------- |
| [bolt-framework](bolt-framework/SKILL.md)   | Core Bolt Framework methodology with 6 lifecycle phases       | Orchestrating projects, managing Bolt cycles  |
| [bolt-adr](bolt-adr/SKILL.md)               | Architecture Decision Records using MADR format              | Documenting architectural decisions           |

## What is Bolt Framework?

Bolt Framework (Bolt Framework) is an AI-powered software development methodology that organizes work into:

- **6 Lifecycle Phases**: INCEPTION → DISCOVERY → CONSTRUCTION → TRANSITION → PRODUCTION → RETIREMENT
- **Micro-Iterations (Bolts)**: Small, deliverable increments (2-3 days max)
- **Quality Gates**: Every Bolt must pass linting, tests, and review
- **Agent Specialization**: 31+ specialized AI agents for different tasks

## Key Concepts

### Constitution (`.boltf/memory/constitution.md`)

The project's DNA - defines tech stack, standards, constraints. **Must be read before any work.**

### Bolts

Micro-iterations that deliver working, tested, reviewed code. Each Bolt:

- Has clear acceptance criteria
- Passes quality gates
- Takes 2-3 days maximum
- Builds incrementally on previous Bolts

### Agents

Specialized AI agents handle specific tasks:

- `@Bolt Framework` - Main orchestrator
- `@Bolt ADR` - Architecture decisions
- `@Bolt Feature` - Feature specifications
- `@Bolt Implement` - Code implementation
- And 26+ more specialized agents

## Activation

These skills are activated in projects via `.boltf/scopes/` configuration when:

- Using Bolt Framework methodology
- Need architecture decision documentation
- Following Bolt Framework workflow

## Integration

Bolt Framework skills work with:

- **Constitution**: `.boltf/memory/constitution.md` - Project constraints and standards
- **Feature Specs**: `specs/XXX-feature-name/` - Detailed feature specifications
- **Quality Gates**: Automated validation of code quality
- **Agents**: 31+ Bolt Framework agents in `.github/agents/`

## Documentation

Each skill contains:

- `SKILL.md` - Complete skill methodology and usage
- `README.md` - Overview and quick reference
- `examples/` - Real-world usage examples
- `templates/` - Reusable document templates
- `scripts/` - Automation scripts (where applicable)

## References

- **Main Documentation**: [bolt-framework/SKILL.md](bolt-framework/SKILL.md)
- **Agents**: `.github/agents/` - All Bolt Framework agents
- **Skills**: `.claude/skills/` - Currently active skills
- **Scopes**: `.boltf/scopes/` - Skill activation rules

---

**Part of**: Bolt Framework (AI-Driven Development Lifecycle)
**Version**: 1.0.0
**Created**: 2026-02-23
