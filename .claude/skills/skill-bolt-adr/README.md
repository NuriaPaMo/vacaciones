# bolt-adr

Architecture Decision Records (ADRs) skill for Bolt Framework projects.

## Purpose

This skill provides comprehensive guidance for creating and managing Architecture Decision Records using the MADR (Markdown Architecture Decision Records) format. It defines the structure, workflow, categories, and best practices for documenting architectural decisions in Bolt Framework projects.

## When to Use

- Documenting architectural decisions (frameworks, databases, patterns)
- Making technology selections with significant impact
- Evaluating alternatives for design decisions
- Recording the "why" behind technical choices

## Contents

- **[SKILL.md](SKILL.md)** - Complete ADR creation methodology
- **[templates/](templates/)** - MADR templates (standard, business, technical)
- **[examples/](examples/)** - Real-world ADR examples

## Templates

| Template                                         | Use Case                    |
| ------------------------------------------------ | --------------------------- |
| [madr-standard.md](templates/madr-standard.md)   | General technical decisions |
| [madr-business.md](templates/madr-business.md)   | Business-impact decisions   |
| [madr-technical.md](templates/madr-technical.md) | Deep technical decisions    |

## Automation Scripts

Create ADRs quickly using automation scripts:

**Project-level scripts:**

- **Bash**: `.boltf/scripts/bash/create-adr.sh`
- **PowerShell**: `.boltf/scripts/powershell/Create-ADR.ps1`

**Utility scripts (skill-level):**

- **Bash**: `.claude/skills/skill-bolt-adr/scripts/get-next-adr-number.sh`
- **PowerShell**: `.claude/skills/skill-bolt-adr/scripts/Get-NextAdrNumber.ps1`

See [scripts/README.md](scripts/README.md) for usage details.

## Integration

This skill is automatically loaded when:

- Working with `@Bolt ADR` agent
- Creating architecture decision records
- Evaluating technology options
- Following Bolt Framework

## Related

- **Agent**: `@Bolt ADR` - Orchestrates ADR creation
- **Skill**: `bolt-framework` - Bolt Framework lifecycle methodology
- **Docs**: [MADR Format](https://adr.github.io/madr/)

---

**Version**: 1.0.0
**Created**: 2026-02-13
**Part of**: Bolt Framework Methodology
