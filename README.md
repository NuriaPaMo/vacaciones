# Bolt Framework - AI-Driven Development Lifecycle

> **Intelligent, micro-iteration "Bolts" orchestrated by specialized AI agents**
> Practice-based initialization with modular, configuration-driven architecture

[![License](https://img.shields.io/badge/license-CUSTOM-orange.svg)](LICENSE)
[![Bolt Framework](https://img.shields.io/badge/methodology-Bolt--Framework-purple.svg)](.github/agents/)
[![AI-DLC](https://img.shields.io/badge/lifecycle-AI--DLC-purple.svg)](.github/agents/)

---

## Overview

This directory contains the **Bolt Framework** - a modular, practice-based AI-native development methodology that replaces traditional sprints with intelligent micro-iterations called "Bolts", orchestrated by 31 specialized AI agents.

### What is Bolt Framework?

**Bolt Framework** is an AI-Driven Development Lifecycle that combines:

- **Practice-Based Initialization**: Apps & Infra, Data & AI, CRM, or Custom
- **Modular Skills System**: Auto-provisioned capabilities based on your tech stack
- **Configuration-Driven**: Everything managed through scopes and constitution
- **Multi-Source Provisioning**: Local files, Context7, Awesome Copilot, GitHub

```text
┌─────────────────────────────────────────────────────────────────────┐
│                 BOLT FRAMEWORK COGNITIVE STAGES                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   1. PERCEIVE ────→ Understand context and gather information       │
│   2. ANALYZE  ────→ Decompose problems into components              │
│   3. REASON   ────→ Apply logic and domain knowledge                │
│   4. PLAN     ────→ Create actionable strategies                    │
│   5. EXECUTE  ────→ Implement solutions                             │
│   6. VALIDATE ────→ Verify correctness and quality                  │
│   7. ADAPT    ────→ Learn and adjust from feedback                  │
│   8. REFLECT  ────→ Document and improve processes                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### AI-DLC Development Lifecycle

**AI-DLC** organizes development into 6 phases with **Bolts** (micro-iterations of 2-3 days):

| Phase           | Focus                               | Key Agents                |
| --------------- | ----------------------------------- | ------------------------- |
| 🎯 INCEPTION    | Vision, stakeholders, initial scope | @Bolt Constitution        |
| 🔍 DISCOVERY    | Requirements, domain modeling       | @Bolt Feature, @Bolt Plan |
| 🔨 CONSTRUCTION | Implementation in Bolts             | @Bolt Implement           |
| 🚀 TRANSITION   | Deployment, rollout                 | @Bolt Release, @Bolt Ops  |
| ⚙️ PRODUCTION   | Monitoring, support                 | @Bolt Ops, @Bolt Improve  |
| 📦 RETIREMENT   | Decommissioning, archival           | @Bolt Retire              |

---

## Getting Started

### Prerequisites

- **Node.js** 20+ or **Python** 3.11+
- **Python** 3.9+ (required for advanced AI-powered features)
- **Git** 2.40+
- **Docker** (optional, for local development)
- **VS Code** with **GitHub Copilot** extension ([`GitHub.copilot`](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot))
- **GitHub Copilot Chat** extension ([`GitHub.copilot-chat`](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat))
- **Awesome Copilot** plugin ([`kinfey.awesome-copilots`](https://marketplace.visualstudio.com/items?itemName=kinfey.awesome-copilots)) (recommended for skill provisioning)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/your-project.git
cd your-project

# Install dependencies
npm install

# Configure environment
cp .env.example .env

# Start development server
npm run dev
```

### Project Structure

```text
.
├── .github/
│   ├── agents/          # AI Agents (31 specialized agents)
│   ├── prompts/         # Copilot prompt files (18 prompts)
│   ├── skills/          # Copilot skill files (scope related skills)
│   └── workflows/       # GitHub Actions CI/CD
├── scripts/
│   ├── bash/            # Automation scripts (Linux/macOS/WSL)
│   └── powershell/      # Automation scripts (Windows)
├── memory/
│   └── constitution.md  # Project governance (single source of truth)
├── specs/               # Feature specifications (organized by feature)
│   ├── .template/       # Template for new features
│   │   ├── contracts/   # API contracts (OpenAPI, JSON Schema)
│   │   ├── requirements/# User stories, acceptance criteria
│   │   ├── tests/       # Gherkin feature files
│   │   └── planning/    # Plan, tasks, research
│   └── XXX-feature/     # Actual feature specs
├── src/
│   ├── domain/          # Domain layer (entities, value objects)
│   ├── application/     # Application layer (use cases)
│   ├── infrastructure/  # Infrastructure layer (adapters)
│   └── presentation/    # Presentation layer (API, UI)
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/
│   ├── adr/             # Architecture Decision Records
│   ├── features/        # Feature specifications
│   └── api/             # API documentation
└── infrastructure/
    └── terraform/       # Infrastructure as Code
```

---

## AI Agents

This project is supported by **29 specialized AI agents** organized across the development lifecycle:

### How to Use Agents

Invoke agents in VS Code Copilot Chat using the `@` prefix:

```text
# Main orchestrator - guides you to the right agent
@Bolt help me start a new feature

# Direct agent invocation
@Bolt Feature create a user authentication feature
@Bolt Testing generate tests for UserService
@Bolt Implement implement the login endpoint
```

### Agent Categories

| Category          | Agents                                       | Purpose                              |
| ----------------- | -------------------------------------------- | ------------------------------------ |
| **Orchestration** | BOLT                                         | Main router to specialized agents    |
| **Discovery**     | Feature, Specify, Clarify, Use Case, Gherkin | Requirements & Analysis              |
| **Architecture**  | Architect, DDD, Constitution                 | Design & Modeling                    |
| **Planning**      | Plan, Tasks                                  | Implementation planning              |
| **Construction**  | Implement, Micro Iterator, Testing, Review   | Development                          |
| **Quality**       | Analyze, Alignment, ADR                      | Validation & Documentation           |
| **Security**      | Security                                     | OWASP compliance & Security analysis |
| **Release**       | Release, Ops, Status                         | Deployment & Monitoring              |
| **Evolution**     | Improve, Postmortem, Retire                  | Improvement & Lifecycle              |
| **DevOps**        | Templates, CI/CD, Deps, Docs, Monitoring     | Infrastructure                       |

📚 **Full documentation**: [.github/agents/README.md](.github/agents/README.md)

---

## 🚀 Quick Start by Scenario

BOLT FRAMEWORK supports different starting points. Choose your scenario:

### Scenario A: Greenfield (New Project from Scratch)

**You have:** Nothing, just an idea or RFP
**Goal:** Build a new system from zero

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    GREENFIELD WORKFLOW                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. @Bolt Framework    → Initialize and guide you                  │
│  2. @Bolt Constitution → Define project DNA (tech stack, rules)    │
│  3. @Bolt Feature      → Create first feature spec                 │
│  4. @Bolt Specify      → Detail requirements                       │
│  5. @Bolt Plan         → Create implementation plan (Bolts)        │
│  6. @Bolt Implement    → Execute each Bolt                         │
│  7. @Bolt Testing      → Generate and run tests                    │
│  8. @Bolt Release      → Prepare release                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Step by Step:**

```bash
# Step 1: Initialize project structure
./init.sh                                       # Linux/macOS/WSL
.\scripts\powershell\Init.ps1             # Windows

# Step 2: Define Constitution (in VS Code Copilot Chat)
@Bolt Constitution create project constitution for a REST API
with TypeScript, NestJS, PostgreSQL, following Clean Architecture

# Step 3: Create your first feature
@Bolt Feature create user-authentication feature

# Or via script:
./.boltf/scripts/bash/create-new-feature.sh "user-authentication"
```

---

### Scenario B: Brownfield (Modernize Legacy System)

**You have:** Existing legacy code (COBOL, VB6, old Java, etc.)
**Goal:** Understand, document, and modernize

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    BROWNFIELD WORKFLOW                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. @Bolt Framework    → Initialize and guide you                  │
│  2. @Bolt Constitution → Define TARGET tech stack                  │
│  3. @Bolt Analyze      → Analyze legacy code (put in legacy/)      │
│  4. @Bolt Use Case     → Extract use cases from legacy             │
│  5. @Bolt Feature      → Create feature specs from use cases       │
│  6. @Bolt DDD          → Model the domain                          │
│  7. @Bolt Plan         → Plan migration in Bolts                   │
│  8. @Bolt Implement    → Implement modern version                  │
│  9. @Bolt Testing      → Create tests (use legacy as oracle)       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Step by Step:**

```bash
# Step 1: Initialize and place legacy code
./init.sh ../my-migration brown ./legacy-source --backend csharp --architecture microservices
# Legacy code copied to: legacy/source/

# Step 2: Define TARGET constitution
@Bolt Constitution create constitution for modernizing COBOL system
to TypeScript microservices with event-driven architecture

# Step 3: Analyze legacy code
@Bolt Analyze analyze the COBOL code in legacy/ and extract
business rules and data structures

# Step 4: Extract use cases
@Bolt Use Case generate use cases from the legacy analysis

# Step 5: Create modern feature specs
@Bolt Feature create features based on extracted use cases
```

---

### Scenario C: From RFP (Request for Proposal)

**You have:** An RFP document or client requirements document
**Goal:** Analyze, estimate, and plan the project

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    RFP ANALYSIS WORKFLOW                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. @Bolt Framework    → Initialize and guide you                  │
│  2. @Bolt Analyze      → Analyze RFP document (put in demo/from_rfp/)│
│  3. @Bolt Use Case     → Extract use cases from RFP                │
│  4. @Bolt Specify      → Create detailed requirements              │
│  5. @Bolt Architect    → Propose architecture                      │
│  6. @Bolt Plan         → Create high-level plan & estimate         │
│  7. @Bolt Constitution → Define tech stack (if approved)           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Step by Step:**

```bash
# Step 1: Initialize and place RFP
./init.sh ../rfp-project green --scope app-only --backend csharp
# RFP copied from: demo/from_rfp/

# Step 2: Analyze RFP
@Bolt Analyze analyze the RFP in demo/from_rfp/ and identify
functional requirements, non-functional requirements, and risks

# Step 3: Generate use cases
@Bolt Use Case create use cases from the RFP analysis

# Step 4: Estimate effort
@Bolt Plan create estimation and high-level plan for the RFP
```

---

### Scenario D: Discovery Only (Analysis Phase)

**You have:** Need to understand a domain or existing system
**Goal:** Document, model, and create specifications only (no code)

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    DISCOVERY ONLY WORKFLOW                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. @Bolt Framework    → Initialize                                │
│  2. @Bolt Clarify      → Clarify requirements with stakeholders    │
│  3. @Bolt Use Case     → Document use cases                        │
│  4. @Bolt DDD          → Model domain (entities, aggregates)       │
│  5. @Bolt Gherkin      → Write acceptance criteria                 │
│  6. @Bolt Architect    → Propose architecture                      │
│  7. @Bolt ADR          → Document key decisions                    │
│  8. @Bolt Alignment    → Verify business-tech alignment            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Step by Step:**

```bash
# Step 1: Initialize
./init.sh ../clarify-project green --scope app-only --backend csharp

# Step 2: Start clarification session
@Bolt Clarify I need to understand the requirements for
an e-commerce checkout system

# Step 3: Generate use cases
./.boltf/scripts/bash/generate-usecases.sh "checkout"

# Step 4: Model domain
@Bolt DDD create domain model for checkout bounded context

# Step 5: Write Gherkin scenarios
./.boltf/scripts/bash/generate-gherkin.sh "checkout"

# Step 6: Check alignment
./.boltf/scripts/bash/alignment-analysis.sh
```

---

### Scenario E: Single Feature (Add to Existing Project)

**You have:** An existing BOLT Framework project with Constitution
**Goal:** Add a new feature following the methodology

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    SINGLE FEATURE WORKFLOW                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. @Bolt Feature      → Create feature specification               │
│  2. @Bolt Specify      → Detail requirements                        │
│  3. @Bolt Gherkin      → Write acceptance criteria                  │
│  4. @Bolt Plan         → Plan implementation (Bolts)                │
│  5. @Bolt Tasks        → Break down into tasks                      │
│  6. @Bolt Implement    → Execute Bolt by Bolt                       │
│  7. @Bolt Testing      → Test each Bolt                             │
│  8. @Bolt Review       → Code review                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Step by Step:**

```bash
# Step 1: Create feature
./.boltf/scripts/bash/create-new-feature.sh "payment-processing"
# Or:
@Bolt Feature create payment-processing feature

# Step 2: Specify requirements
@Bolt Specify detail requirements for payment-processing

# Step 3: Generate Gherkin
./.boltf/scripts/bash/generate-gherkin.sh "payment-processing"

# Step 4: Plan implementation
@Bolt Plan create implementation plan for payment-processing

# Step 5: Execute Bolt 1
@Bolt Implement execute Bolt 1 for payment-processing

# Step 6: Test
./.boltf/scripts/bash/generate-tests.sh "payment-processing"

# Step 7: Validate
./.boltf/scripts/bash/quality-gates.sh
```

---

## 📋 Agent Execution Order Reference

### Full Development Cycle (Recommended Order)

| Phase            | Agent                  | Script Alternative        | Output                          |
| ---------------- | ---------------------- | ------------------------- | ------------------------------- |
| **INCEPTION**    |                        |                           |                                 |
| 1                | `@Bolt`                | `init.sh`                 | Project initialized             |
| 2                | `@Bolt Constitution`   | -                         | `.boltf/memory/constitution.md` |
| **DISCOVERY**    |                        |                           |                                 |
| 3                | `@Bolt Clarify`        | -                         | Requirements clarified          |
| 4                | `@Bolt Feature`        | `create-new-feature.sh`   | `specs/XXX-feature/`            |
| 5                | `@Bolt Specify`        | -                         | `requirements/requirements.md`  |
| 6                | `@Bolt Use Case`       | `generate-usecases.sh`    | `requirements/use-cases.md`     |
| 7                | `@Bolt Gherkin`        | `generate-gherkin.sh`     | `tests/*.feature`               |
| 8                | `@Bolt DDD`            | -                         | Domain model                    |
| 9                | `@Bolt Architect`      | -                         | Architecture design             |
| **CONSTRUCTION** |                        |                           |                                 |
| 10               | `@Bolt Plan`           | -                         | `planning/plan.md`              |
| 11               | `@Bolt Tasks`          | -                         | `planning/tasks.md`             |
| 12               | `@Bolt Implement`      | -                         | Source code                     |
| 13               | `@Bolt Micro Iterator` | -                         | Bolt execution                  |
| 14               | `@Bolt Testing`        | `generate-tests.sh`       | Test files                      |
| 15               | `@Bolt Review`         | -                         | Code reviewed                   |
| 16               | `@Bolt ADR`            | `create-adr.sh`           | `docs/adr/`                     |
| **TRANSITION**   |                        |                           |                                 |
| 17               | `@Bolt Release`        | `create-release.sh`       | Release prepared                |
| 18               | `@Bolt Docs`           | -                         | Documentation                   |
| **PRODUCTION**   |                        |                           |                                 |
| 19               | `@Bolt Ops`            | `ops-status.sh`           | Operations running              |
| 20               | `@Bolt Monitoring`     | -                         | Monitoring configured           |
| 21               | `@Bolt Status`         | `project-status.sh`       | Status report                   |
| **EVOLUTION**    |                        |                           |                                 |
| 22               | `@Bolt Postmortem`     | `generate-postmortem.sh`  | Incident analysis               |
| 23               | `@Bolt Improve`        | `analyze-improvements.sh` | Improvements                    |
| 24               | `@Bolt Alignment`      | `alignment-analysis.sh`   | Alignment report                |
| **RETIREMENT**   |                        |                           |                                 |
| 25               | `@Bolt Retire`         | `plan-retirement.sh`      | Decommission plan               |

---

## 🔧 Development Workflow (Detailed)

### Phase 1: Constitution (Do Once)

The Constitution is the **DNA** of your project. It defines:

- Tech stack (languages, frameworks, databases)
- Coding standards
- Architecture patterns
- Quality gates
- Git workflow

```bash
# Create constitution
@Bolt Constitution create constitution for {project description}

# Verify constitution
cat .boltf/memory/constitution.md
```

⚠️ **Important:** All agents read the Constitution before generating code. Update it carefully.

---

### Phase 2: Feature Definition

⚠️ **MANDATORY: Every feature MUST have its own Git branch**

Before creating any feature specification, create the branch first:

```bash
# This is REQUIRED - DO NOT SKIP
./.boltf/scripts/bash/create-new-feature.sh "feature-name" "main"
# Or PowerShell:
.\scripts\powershell\Create-NewFeature.ps1 -FeatureName "feature-name"
```

The script automatically:

1. Creates branch `feature/feature-name` from base branch
2. Creates the `specs/feature-name/` directory structure
3. Initializes template files

Each feature gets its own directory under `specs/`:

```text
specs/
└── 001-user-authentication/
    ├── feature.md           # Feature overview
    ├── requirements/
    │   ├── requirements.md  # Detailed requirements
    │   └── use-cases.md     # Use case diagrams
    ├── contracts/
    │   └── openapi.yaml     # API contract
    ├── tests/
    │   └── auth.feature     # Gherkin scenarios
    └── planning/
        ├── plan.md          # Implementation plan
        └── tasks.md         # Bolt tasks
```

```bash
# Create feature structure
@Bolt Feature create {feature-name} feature

# Or via script
./.boltf/scripts/bash/create-new-feature.sh "{feature-name}"
```

---

### Phase 3: Implementation Bolts

Bolts are **micro-iterations of 2-3 days**. Each Bolt:

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         BOLT LIFECYCLE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────┐     ┌──────────┐    ┌──────────┐    ┌──────────┐     │
│   │  DESIGN  │───▶│ IMPLEMENT│───▶│   TEST   │───▶│  REVIEW  │     │
│   └──────────┘     └──────────┘    └──────────┘    └──────────┘     │
│        │               │               │               │            │
│        ▼               ▼               ▼               ▼            │
│   Domain model    Clean code      Unit tests     Code review        │
│   API contract    TDD approach    Integration    Quality gates      │
│                                   E2E tests      Merge ready        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

```bash
# Execute a Bolt
@Bolt Implement execute Bolt 1 for {feature-name}

# Generate tests for the implementation
@Bolt Testing generate tests for {component}

# Run quality gates
./.boltf/scripts/bash/quality-gates.sh

# Code review
@Bolt Review review the implementation of {feature-name}
```

---

### Phase 4: Validation & Release

```bash
# Check project status
./.boltf/scripts/bash/project-status.sh

# Verify alignment
./.boltf/scripts/bash/alignment-analysis.sh

# Create release
./.boltf/scripts/bash/create-release.sh "1.0.0"
# Or:
@Bolt Release prepare release 1.0.0
```

---

## 🤖 AI Agents (29 Total)

This project is supported by **29 specialized AI agents** organized across the development lifecycle.

### How to Invoke Agents

In VS Code with GitHub Copilot, use `@` in the Chat:

```text
@Bolt help me start a new project          # Main orchestrator
@Bolt Feature create a login feature       # Direct agent
@Bolt Testing generate unit tests          # Direct agent
```

### Agents by Phase

| Phase             | Agent                  | Purpose              | When to Use                |
| ----------------- | ---------------------- | -------------------- | -------------------------- |
| **ORCHESTRATION** |                        |                      |                            |
|                   | `@Bolt`                | Main orchestrator    | Start here if unsure       |
| **INCEPTION**     |                        |                      |                            |
|                   | `@Bolt Constitution`   | Project DNA          | First step in any project  |
|                   | `@Bolt Templates`      | Project scaffolding  | Initial setup              |
| **DISCOVERY**     |                        |                      |                            |
|                   | `@Bolt Feature`        | Create feature specs | New feature needed         |
|                   | `@Bolt Specify`        | Detail requirements  | Elaborate on feature       |
|                   | `@Bolt Clarify`        | Requirements Q&A     | Unclear requirements       |
|                   | `@Bolt Use Case`       | Extract use cases    | Document behaviors         |
|                   | `@Bolt Gherkin`        | BDD scenarios        | Acceptance criteria        |
|                   | `@Bolt Analyze`        | Code/doc analysis    | Legacy/RFP analysis        |
| **ARCHITECTURE**  |                        |                      |                            |
|                   | `@Bolt Architect`      | System design        | Architecture decisions     |
|                   | `@Bolt DDD`            | Domain modeling      | Domain entities/aggregates |
|                   | `@Bolt ADR`            | Decision records     | Document decisions         |
| **CONSTRUCTION**  |                        |                      |                            |
|                   | `@Bolt Plan`           | Implementation plan  | Before coding              |
|                   | `@Bolt Tasks`          | Task breakdown       | Bolt task lists            |
|                   | `@Bolt Implement`      | Write code           | During Bolts               |
|                   | `@Bolt Micro Iterator` | Bolt orchestration   | Execute Bolts              |
|                   | `@Bolt Testing`        | Test generation      | After implementation       |
|                   | `@Bolt Review`         | Code review          | Before merge               |
| **TRANSITION**    |                        |                      |                            |
|                   | `@Bolt Release`        | Release prep         | Version release            |
|                   | `@Bolt Docs`           | Documentation        | API docs, guides           |
|                   | `@Bolt CI/CD`          | Pipeline config      | CI/CD setup                |
| **PRODUCTION**    |                        |                      |                            |
|                   | `@Bolt Ops`            | Operations           | Deployment, monitoring     |
|                   | `@Bolt Monitoring`     | Observability        | Metrics, alerts            |
|                   | `@Bolt Status`         | Project status       | Progress reports           |
| **EVOLUTION**     |                        |                      |                            |
|                   | `@Bolt Improve`        | Improvements         | Refactoring proposals      |
|                   | `@Bolt Postmortem`     | Incident analysis    | After incidents            |
|                   | `@Bolt Alignment`      | Alignment check      | Business-tech sync         |
|                   | `@Bolt Deps`           | Dependencies         | Update deps                |
| **RETIREMENT**    |                        |                      |                            |
|                   | `@Bolt Retire`         | Decommission         | End of life                |

📚 **Full documentation**: [.github/agents/README.md](.github/agents/README.md)

---

## 📜 Automation Scripts

Scripts are available in **Bash** (Linux/macOS/WSL) and **PowerShell** (Windows):

### Script Reference

| Task                 | Bash                            | PowerShell                  | Related Agent      |
| -------------------- | ------------------------------- | --------------------------- | ------------------ |
| **INCEPTION**        |                                 |                             |                    |
| Initialize project   | `init.sh`                       | `Init.ps1`                  | `@Bolt`            |
| **DISCOVERY**        |                                 |                             |                    |
| Create feature       | `create-new-feature.sh`         | `Create-NewFeature.ps1`     | `@Bolt Feature`    |
| Generate use cases   | `generate-usecases.sh`          | `Generate-UseCases.ps1`     | `@Bolt Use Case`   |
| Generate Gherkin     | `generate-gherkin.sh`           | `Generate-Gherkin.ps1`      | `@Bolt Gherkin`    |
| Validate specs       | `validate-specs.sh`             | `Validate-Specs.ps1`        | `@Bolt Specify`    |
| **CONSTRUCTION**     |                                 |                             |                    |
| Generate tests       | `generate-tests.sh`             | `Generate-Tests.ps1`        | `@Bolt Testing`    |
| Quality gates        | `quality-gates.sh`              | `Quality-Gates.ps1`         | `@Bolt Review`     |
| Create ADR           | `create-adr.sh`                 | `Create-ADR.ps1`            | `@Bolt ADR`        |
| **TRANSITION**       |                                 |                             |                    |
| Create release       | `create-release.sh`             | `Create-Release.ps1`        | `@Bolt Release`    |
| Deploy               | `deploy.sh`                     | -                           | `@Bolt Ops`        |
| **PRODUCTION**       |                                 |                             |                    |
| Project status       | `project-status.sh`             | `Get-ProjectStatus.ps1`     | `@Bolt Status`     |
| Ops status           | `ops-status.sh`                 | `Get-OpsStatus.ps1`         | `@Bolt Ops`        |
| **EVOLUTION**        |                                 |                             |                    |
| Alignment analysis   | `alignment-analysis.sh`         | `Get-AlignmentAnalysis.ps1` | `@Bolt Alignment`  |
| Analyze improvements | `analyze-improvements.sh`       | `Get-Improvements.ps1`      | `@Bolt Improve`    |
| Generate postmortem  | `generate-postmortem.sh`        | `Generate-Postmortem.ps1`   | `@Bolt Postmortem` |
| **RETIREMENT**       |                                 |                             |                    |
| Plan retirement      | `plan-retirement.sh`            | `Plan-Retirement.ps1`       | `@Bolt Retire`     |
| **UTILITIES**        |                                 |                             |                    |
| Update agent context | `update-agent-context.sh`       | `Update-AgentContext.ps1`   | -                  |
| Generate structure   | `generate-project-structure.sh` | -                           | -                  |

### Usage Examples

```bash
# Linux/macOS/WSL
./init.sh ../my-project green --scope app-only --backend csharp
./.boltf/scripts/bash/create-new-feature.sh "payment"
./.boltf/scripts/bash/quality-gates.sh

# Windows PowerShell
.\scripts\powershell\Init.ps1
.\scripts\powershell\Create-NewFeature.ps1 -Name "payment"
.\scripts\powershell\Quality-Gates.ps1
```

📚 **Full documentation**: [scripts/README.md](scripts/README.md)

---

## CI/CD

This project uses GitHub Actions for continuous integration and deployment:

| Workflow            | Trigger     | Purpose                |
| ------------------- | ----------- | ---------------------- |
| `ci.yml`            | Push/PR     | Build, test, lint      |
| `cd.yml`            | Main branch | Deploy to environments |
| `security-scan.yml` | Daily       | Security scanning      |
| `release.yml`       | Tags        | Version releases       |

---

## Documentation

- **Agents**: `/.github/agents/` - AI agent definitions (29 agents)
- **Prompts**: `/.github/prompts/` - Reusable prompt templates (18 prompts)
- **Scripts**: `/scripts/` - Automation scripts (36 scripts)
- **Constitution**: `/.boltf/memory/constitution.md` - Project governance
- **API Documentation**: `/docs/api/`
- **Architecture Decisions**: `/docs/adr/`

---

## Contributing

1. Create a feature branch from `develop`
2. Follow the Bolt workflow (intent → spec → plan → implement)
3. Ensure all tests pass
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **BOLT FRAMEOWKR-IA Methodology** - AI-native development approach
- **AWS AI-DLC** - AI-Driven Development Lifecycle framework
- **Domain-Driven Design** - Strategic and tactical patterns
- **Clean Architecture** - Separation of concerns principles

---

## Contact

- **Project Lead**: [Name]
- **Repository**: [GitHub URL]
- **Documentation**: [Wiki URL]
