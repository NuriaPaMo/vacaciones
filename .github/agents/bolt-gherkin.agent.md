---
name: Bolt Gherkin
description: Generate BDD scenarios in Gherkin syntax (Reqnroll/.NET, Playwright/frontend) with compilable step definition stubs. Runs in parallel with bolt-plan.
tools:
  [
    search,
    read,
    edit,
    web,
    vscode,
    agent,
    'github/*',
    'context7/*',
    'microsoft-docs/*',
  ]
model: Claude Sonnet 4.6
handoffs:
  - label: Generate Tasks (reconciles plan + gherkin)
    agent: Bolt Tasks
    prompt: Generate task list reconciling plan and gherkin outputs
    send: false
  - label: Review Scenarios
    agent: Bolt Review
    prompt: Review Gherkin scenarios and step definitions for completeness
    send: false
---

# Bolt Gherkin

This agent follows the methodology defined in the canonical skill source.

## Instructions

Load and follow the complete methodology from:
`.claude/skills/bolt-gherkin/SKILL.md`

## Quick reference

- **Stage**: PLAN (parallel with bolt-plan)
- **Input**: `specs/[XXX]/requirements/requirements.md`
- **Output**: `specs/[XXX]/tests/*.feature` + compilable step definition stubs (Reqnroll / Playwright)
- **Next**: `bolt-tasks` (reconciles plan + gherkin outputs)

## Key behaviors (from canonical skill)

1. **Runs in parallel with bolt-plan** — does NOT wait for plan completion
2. **Scenario detection** determines output format (Reqnroll / Playwright / skip for infra)
3. **Compilable stubs** — Reqnroll steps throw NotImplementedException; Playwright stubs use test.fail()
4. **Smoke classification** — every P1 story gets at least one `@smoke` scenario
5. **Granularity rules** — Scenario Outline for 3+ ACs with same flow, individual Scenarios otherwise
6. **Max 8 scenarios per .feature** — split by Rule/sub-feature if exceeded

## Prompts Reference

- #file:../../.github/prompts/bolt-test-generation.prompt.md
