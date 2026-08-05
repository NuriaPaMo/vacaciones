# Bolt Framework Copilot Prompts Directory

This directory contains GitHub Copilot prompt files (`.prompt.md`) that provide context and instructions for AI-assisted development within the Bolt Framework methodology.

## Purpose

Copilot prompts help ensure consistent, high-quality AI assistance aligned with:

- **Bolt Framework**: AI-Driven Development Lifecycle with 6 phases and micro-iterations
- **Constitution**: Central governance through `.boltf/memory/constitution.md`
- **Quality Gates**: Automated validation at each Bolt iteration

## How Prompts Relate to Agents

Prompts are **reusable instruction templates** that agents can reference for additional context:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENTS → PROMPTS RELATIONSHIP                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   🤖 AGENT                         📝 PROMPT                             │
│   (Conversational)                 (Instructions)                        │
│                                                                          │
│   @Bolt Testing         ──uses──>  bolt-test-generation.prompt.md       │
│   @Bolt Implement       ──uses──>  bolt-code-generation.prompt.md       │
│   @Bolt Architect       ──uses──>  bolt-architecture.prompt.md          │
│   @Bolt DDD             ──uses──>  bolt-domain-modeling.prompt.md       │
│   @Bolt Release         ──uses──>  bolt-release.prompt.md               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Available Prompts (18 Total)

### Block 1: Inception - Discovery & Analysis

| Prompt                               | Related Agent | Purpose                          |
| ------------------------------------ | ------------- | -------------------------------- |
| `bolt-business-analysis.prompt.md`   | Bolt Feature  | Business requirements extraction |
| `bolt-technical-discovery.prompt.md` | Bolt Analyze  | Technical assessment             |
| `bolt-legacy-analysis.prompt.md`     | Bolt Analyze  | Legacy system documentation      |

### Block 2: Inception - Planning & Architecture

| Prompt                           | Related Agent  | Purpose                           |
| -------------------------------- | -------------- | --------------------------------- |
| `bolt-planning.prompt.md`        | Bolt Plan      | Sprint planning, Bolts definition |
| `bolt-architecture.prompt.md`    | Bolt Architect | Solution architecture             |
| `bolt-domain-modeling.prompt.md` | Bolt DDD       | Domain-Driven Design              |

### Block 3: Construction - Implementation

| Prompt                           | Related Agent  | Purpose                      |
| -------------------------------- | -------------- | ---------------------------- |
| `bolt-code-generation.prompt.md` | Bolt Implement | Clean code generation        |
| `bolt-test-generation.prompt.md` | Bolt Testing   | Test case creation (BDD/TDD) |
| `bolt-infrastructure.prompt.md`  | Bolt CI/CD     | Terraform/IaC generation     |

### Block 4: Construction - Security & Quality

| Prompt                           | Related Agent | Purpose                  |
| -------------------------------- | ------------- | ------------------------ |
| `bolt-security-review.prompt.md` | Bolt Review   | Security analysis, OWASP |
| `bolt-guardrails.prompt.md`      | Bolt Review   | Policy compliance        |

### Block 5: Delivery - Release & Operations

| Prompt                      | Related Agent | Purpose              |
| --------------------------- | ------------- | -------------------- |
| `bolt-release.prompt.md`    | Bolt Release  | CI/CD, versioning    |
| `bolt-operations.prompt.md` | Bolt Ops      | Monitoring, alerting |

### Block 6: Evolution - Continuous Improvement

| Prompt                       | Related Agent  | Purpose                     |
| ---------------------------- | -------------- | --------------------------- |
| `bolt-evolution.prompt.md`   | Bolt Improve   | System evolution, tech debt |
| `bolt-refactoring.prompt.md` | Bolt Implement | Safe refactoring patterns   |

### Block 7: Sunset - End of Life

| Prompt                        | Related Agent | Purpose                |
| ----------------------------- | ------------- | ---------------------- |
| `bolt-decommission.prompt.md` | Bolt Retire   | System decommissioning |

### Cross-Phase

| Prompt                               | Related Agent  | Purpose                        |
| ------------------------------------ | -------------- | ------------------------------ |
| `bolt.prompt.md`                     | Bolt Framework | Main orchestrator instructions |
| `bolt-structure-generator.prompt.md` | Bolt Templates | Project scaffolding            |

## Usage

### Method 1: Reference in Chat

Use the `#file` directive to add prompt context to any chat:

```text
#file:.github/prompts/bolt-test-generation.prompt.md
Generate comprehensive tests for the UserService class
```

### Method 2: Use with Agent

Combine agent invocation with prompt context:

```text
@Bolt Testing #file:.github/prompts/bolt-test-generation.prompt.md
Generate BDD tests for the payment module
```

### Method 3: Agent Auto-Discovery

Agents automatically pick up relevant prompts based on the task. The agent will reference the appropriate prompt internally.

## Prompt + Agent + Script Workflow

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    COMPLETE WORKFLOW EXAMPLE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. USER: @Bolt Testing generate tests for auth module                  │
│                                                                          │
│   2. AGENT: Bolt Testing                                                 │
│      ├── Reads: bolt-test-generation.prompt.md (instructions)           │
│      ├── Reads: .boltf/memory/constitution.md (standards)                      │
│      └── Generates: Test code following BDD/TDD patterns                │
│                                                                          │
│   3. AGENT: Executes script (if needed)                                  │
│      └── scripts/bash/generate-tests.sh                                  │
│                                                                          │
│   4. OUTPUT: Comprehensive test suite                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Related Resources

- **Agents**: `.github/agents/` - AI agent definitions (29 agents)
- **Scripts**: `scripts/bash/` and `scripts/powershell/` - Automation
- **Constitution**: `.boltf/memory/constitution.md` - Project governance
- **Workflows**: `.github/workflows/` - GitHub Actions

## Validation

Use validation scripts to ensure prompt-agent consistency:

```bash
# Bash
./scripts/bash/update-agent-context.sh --check

# PowerShell
.\scripts\powershell\Update-AgentContext.ps1 -Mode Check
```
