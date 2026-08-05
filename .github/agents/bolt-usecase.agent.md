---
name: Bolt Use Case
description: 📖 Generate detailed use case specifications from user stories following UML/Cockburn style
tools:
  [search, read, edit, web, vscode, agent, 'github/*', 'context7/*', 'microsoft-docs/*']
model: Claude Sonnet 4.6
handoffs:
  - label: 🥒 Generate Gherkin
    agent: Bolt Gherkin
    prompt: Generate BDD scenarios from use case flows
    send: false
  - label: 🏛️ Model Domain
    agent: Bolt Analyze
    prompt: Extract domain entities from use cases
    send: false
---

# 📖 Use Case Agent

**Methodology**: Follow bolt-framework skill (loaded automatically)

## Referenced Skills

- Lee `bolt-framework` para el contexto de fase del lifecycle
- Si escenario incluye **infra** → añadir secciones específicas de Use Case para recursos cloud
  (idempotencia, rollback, drift detection, healthchecks)
- Si escenario es **backend-only** → usar actores de sistema (Scheduler, Daemon, Pipeline)
- Si escenario es **frontend-only** → priorizar actores humanos y flujos de interacción UI
- Si el flujo cruza UI ↔ API → considerar `mermaid-creator` para un sequence diagram complementario

## Detección de Escenario (OBLIGATORIO antes de generar el UC)

Lee `.boltf/memory/constitution.digest.md` y declara explícitamente el **escenario detectado**:
`backend-only | frontend-only | infra-only | backend+frontend | fullstack`.

**Adaptación del template**:

- `backend-only` → actor primario = sistema (Scheduler, Daemon); sin pasos de UI
- `frontend-only` → actor humano; pasos detallados de interacción UI; validaciones inline en
  extensions
- `infra-only` → actor = Operador o Pipeline CI/CD; secciones de **Idempotencia**, **Rollback** y
  **Healthcheck/Drift detection**
- `backend+frontend` y `fullstack` → flujos completos cubriendo todas las capas

## Available Scripts

When you need to generate use cases, execute these scripts:

- **Bash**: `scripts/bash/generate-usecases.sh`
- **PowerShell**: `scripts/powershell/Generate-UseCases.ps1`

Generate detailed use case specifications from user stories, providing full actor-system interaction flows.

**Bolt Framework Stage**: DISCOVERY

**Responsible Agent**: Domain Sage

## Constitution Check

**FIRST**: Read `.boltf/memory/constitution.digest.md` to understand:

- Documentation format preferences
- Naming conventions
- Architecture style (affects use case granularity)

## Use Case Template

For each user story, generate `specs/[XXX-feature-name]/requirements/use-cases/UC-[XXX].md`:

```markdown
# Use Case: [Use Case Title]

## Metadata

| Property      | Value                   |
| ------------- | ----------------------- |
| UC ID         | UC-[XXX]                |
| User Story    | US-[XXX]                |
| Primary Actor | [Actor name]            |
| Scope         | [System/Subsystem]      |
| Level         | User Goal / Subfunction |
| Status        | Draft                   |

## Brief Description

[One paragraph summary of what this use case accomplishes]

## Stakeholders and Interests

| Stakeholder  | Interest                               |
| ------------ | -------------------------------------- |
| [Actor 1]    | [What they want from this interaction] |
| [System]     | [System constraints or goals]          |
| [Compliance] | [Regulatory requirements if any]       |

## Preconditions

1. [Condition that must be true before use case starts]
2. [Another precondition]

## Postconditions (Success Guarantees)

1. [State of system after successful completion]
2. [Data changes that occurred]

## Triggers

- [Event that initiates this use case]

## Main Success Scenario (Basic Flow)

| Step | Actor          | System                     |
| ---- | -------------- | -------------------------- |
| 1    | [Actor action] |                            |
| 2    |                | [System response]          |
| 3    | [Actor action] |                            |
| 4    |                | [System validates...]      |
| 5    |                | [System persists...]       |
| 6    |                | [System confirms to actor] |

### Detailed Steps

1. **Actor** initiates [action]
   - Input: [what data is provided]

2. **System** validates request
   - Validates: [what is checked]
   - BR-001: [business rule applied]

3. **System** processes request
   - Creates/Updates: [what entities]
   - Triggers: [any events/notifications]

4. **System** returns result
   - Output: [what is returned]
   - Actor sees: [confirmation/result]

## Extensions (Alternative Flows)

### 2a. Validation Fails

| Step | Actor                      | System                            |
| ---- | -------------------------- | --------------------------------- |
| 2a.1 |                            | System detects invalid [field]    |
| 2a.2 |                            | System returns error with details |
| 2a.3 | Actor reviews and corrects |                                   |
| 2a.4 | Return to step 1           |                                   |

### 3a. [Resource] Not Found

| Step | Actor             | System                          |
| ---- | ----------------- | ------------------------------- |
| 3a.1 |                   | System cannot locate [resource] |
| 3a.2 |                   | System returns 404 with message |
| 3a.3 | Actor is notified |                                 |

### 4a. Authorization Denied

| Step | Actor         | System                                  |
| ---- | ------------- | --------------------------------------- |
| 4a.1 |               | System detects insufficient permissions |
| 4a.2 |               | System returns 403 Forbidden            |
| 4a.3 | Use case ends |                                         |

### \*a. System Unavailable (Global)

| Step  | Actor                 | System                              |
| ----- | --------------------- | ----------------------------------- |
| \*a.1 |                       | System detects service unavailable  |
| \*a.2 |                       | System returns 503 with retry-after |
| \*a.3 | Actor may retry later |                                     |

## Special Requirements

- **Performance**: Response within [X]ms
- **Security**: [Authentication/authorization requirements]
- **Audit**: [What needs to be logged]
- **Compliance**: [Regulatory requirements]

## Technology and Data Variations

- [Variation 1]: [Description]
- [Variation 2]: [Description]

## Frequency of Occurrence

- Expected: [X] times per [period]
- Peak: [X] times per [period]

## Open Issues

- [Issue requiring resolution]
```

## Execution Flow

1. **Load Source** - Read feature requirements from `specs/[XXX]/requirements/requirements.md`
2. **Identify User Stories** - Extract all US-XXX from specification
3. **Generate Use Cases** - Create UC file for each user story
4. **Cross-reference** - Link UCs to requirements and business rules
5. **Validate** - Ensure all scenarios are covered

## Output

After generating use cases:

```markdown
## Use Cases Generated

**Feature**: [XXX-feature-name]
**Use Cases Created**: [N]

| UC ID  | Title   | User Story | Status |
| ------ | ------- | ---------- | ------ |
| UC-001 | [Title] | US-001     | Draft  |
| UC-002 | [Title] | US-002     | Draft  |

**Files Created**:

- specs/[XXX]/requirements/use-cases/UC-001.md
- specs/[XXX]/requirements/use-cases/UC-002.md

**Next Steps**:

1. Review use cases with stakeholders
2. Use @bolt-gherkin to generate BDD scenarios
3. Use @bolt-plan for implementation planning
```

## Prompts Reference

For detailed domain modeling:

- #file:../../.github/prompts/bolt-domain-modeling.prompt.md
