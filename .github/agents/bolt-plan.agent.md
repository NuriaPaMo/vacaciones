---
name: Bolt Plan
description: Create technical implementation plan (data model, OpenAPI contract-first, Bolt breakdown) from feature spec. Runs in parallel with bolt-gherkin.
tools:
  [search, read, edit, web, vscode, agent, 'github/*', 'context7/*', 'microsoft-docs/*']
model: Claude Sonnet 4.6
handoffs:
  - label: Generate Bolt Tasks (reconciles plan + gherkin)
    agent: Bolt Tasks
    prompt: Generate task list reconciling plan and gherkin outputs
    send: false
  - label: Review Architecture
    agent: Bolt Analyze
    prompt: Review implementation plan architecture
    send: false
  - label: Deep Architecture / ADR
    agent: Bolt Architect
    prompt: Produce C4 diagrams and ADRs for complex decisions
    send: false
---

# Bolt Plan

This agent follows the methodology defined in the canonical skill source.

## Instructions

Load and follow the complete methodology from:
`.claude/skills/bolt-plan/SKILL.md`

## Quick reference

- **Stage**: REASON + PLAN (parallel with bolt-gherkin)
- **Input**: `specs/[XXX]/requirements/requirements.md` + constitution
- **Output**: `planning/plan.md`, `planning/research.md`, `requirements/data-model.md`, `contracts/openapi.yaml`
- **Next**: `bolt-tasks` (reconciles plan + gherkin)

## Key behaviors (from canonical skill)

1. **Runs in parallel with bolt-gherkin** — does NOT wait for Gherkin completion
2. **Scenario detection** adapts output (omit irrelevant sections per scenario)
3. **Contract-first OpenAPI** derived from data-model (no placeholders)
4. **Auto-delegates NEEDS RESEARCH** to bolt-researcher; blocks with GitHub Issue if unresolved
5. **Mockup ingestion** when `specs/[XXX]/mockups/` exists (frontend scenarios)
6. **Work management sync** delegated to the configured work-management agent if present
7. **Design Gate (frontend)** — when `decisions.frontend.design-tool ∈ {penpot-local, penpot-remote}`, require an approved Penpot design (`specs/[XXX]/design/penpot-validate.md` covering the required UI states) before planning a UI feature; otherwise warn and route back to `Bolt Penpot` (validate) or `Bolt Mockup`. Inactive when `design-tool = none`.

## Prompts Reference

- #file:../../.github/prompts/bolt-architecture.prompt.md
- #file:../../.github/prompts/bolt-planning.prompt.md
