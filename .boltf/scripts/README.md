# BOLT Framework Automation Scripts

This directory contains automation scripts that support the BOLT Framework methodology.

## How Scripts Relate to Agents

Scripts provide **automation capabilities** that agents can execute using the `execute` tool:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENTS → SCRIPTS RELATIONSHIP                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   🤖 AGENT                         ⚙️ SCRIPT                             │
│   (Conversational)                 (Automation)                          │
│                                                                          │
│   @Bolt ──executes──> init.sh, project-status.sh          │
│   @Bolt Feature     ──executes──> create-new-feature.sh               │
│   @Bolt Testing     ──executes──> generate-tests.sh                   │
│   @Bolt Release     ──executes──> create-release.sh                   │
│   @Bolt Gherkin     ──executes──> generate-gherkin.sh                 │
│   @Bolt ADR           ──executes──> create-adr.sh                       │
│   @Bolt Status      ──executes──> project-status.sh                   │
│   @Bolt Ops         ──executes──> ops-status.sh, deploy.sh            │
│   @Bolt Postmortem  ──executes──> generate-postmortem.sh              │
│   @Bolt Improve     ──executes──> analyze-improvements.sh             │
│   @Bolt Retire      ──executes──> plan-retirement.sh                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Usage Options

### Option 1: Via Agent (Recommended)

Let the agent execute scripts automatically:

```text
@Bolt Status show project status
# Agent internally runs: ./scripts/bash/project-status.sh

@Bolt Feature create user-authentication feature
# Agent internally runs: ./scripts/bash/create-new-feature.sh
```

### Option 2: Direct Execution

Run scripts directly from terminal:

```bash
# Bash (Linux/macOS/WSL)
./scripts/bash/project-status.sh

# PowerShell (Windows)
.\scripts\powershell\Get-ProjectStatus.ps1
```

## Directory Structure

```text
scripts/
├── bash/                        # Bash scripts (Linux/macOS/WSL)
│   ├── bootstrap-python.sh      # 🐍 Python environment setup
│   ├── Test-PythonEnvironment.sh # 🐍 Python environment validation
│   ├── init.sh                  # 🆕 Project initialization (Brownfield/Greenfield)
│   ├── project-status.sh        # 🆕 Project status analyzer (continuity)
│   ├── alignment-analysis.sh    # 🆕 Alignment & gap analysis
│   ├── create-release.sh        # 🆕 Release/deployment automation
│   ├── ops-status.sh            # 🆕 Operations status & runbooks
│   ├── generate-postmortem.sh   # 🆕 Incident postmortem generator
│   ├── analyze-improvements.sh  # 🆕 Improvement backlog generator
│   ├── plan-retirement.sh       # 🆕 System retirement planner
│   ├── architecture-gates.sh    # 🏗️ Architecture quality validation
│   ├── update-bolt-framework.sh # 🔄 Update agents/skills from framework source
│   ├── create-new-feature.sh
│   ├── quality-gates.sh
│   ├── validate-specs.sh
│   ├── generate-usecases.sh
│   ├── generate-gherkin.sh
│   ├── create-adr.sh
│   └── update-agent-context.sh
└── powershell/                  # PowerShell scripts (Windows)
    ├── Bootstrap-Python.ps1     # 🐍 Python environment setup
    ├── Test-PythonEnvironment.ps1 # 🐍 Python environment validation
    ├── Test-PythonIntegration.ps1 # 🐍 End-to-end Python integration test
    ├── Init.ps1                 # 🆕 Project initialization (Brownfield/Greenfield)
    ├── Get-ProjectStatus.ps1    # 🆕 Project status analyzer (continuity)
    ├── Get-AlignmentAnalysis.ps1 # 🆕 Alignment & gap analysis
    ├── Create-Release.ps1       # 🆕 Release/deployment automation
    ├── Get-OpsStatus.ps1        # 🆕 Operations status & runbooks
    ├── Generate-Postmortem.ps1  # 🆕 Incident postmortem generator
    ├── Get-Improvements.ps1     # 🆕 Improvement backlog generator
    ├── Plan-Retirement.ps1      # 🆕 System retirement planner
    ├── Architecture-Gates.ps1   # 🏗️ Architecture quality validation
    ├── Update-BoltFramework.ps1 # 🔄 Update agents/skills from framework source
    ├── Create-NewFeature.ps1
    ├── Quality-Gates.ps1
    ├── Validate-Specs.ps1
    ├── Generate-UseCases.ps1
    ├── Generate-Gherkin.ps1
    ├── Create-ADR.ps1
    └── Update-AgentContext.ps1
```

## Script Reference by Agent

| Agent           | Bash Script                                        | PowerShell Script                                        |
| --------------- | -------------------------------------------------- | -------------------------------------------------------- |
| BOLT Framework  | `init.sh`, `project-status.sh`, `quality-gates.sh`, `update-bolt-framework.sh` | `Init.ps1`, `Get-ProjectStatus.ps1`, `Quality-Gates.ps1`, `Update-BoltFramework.ps1` |
| Bolt Feature    | `create-new-feature.sh`                            | `Create-NewFeature.ps1`                                  |
| Bolt Specify    | `create-new-feature.sh`                            | `Create-NewFeature.ps1`                                  |
| Bolt Use Case   | `generate-usecases.sh`                             | `Generate-UseCases.ps1`                                  |
| Bolt Gherkin    | `generate-gherkin.sh`                              | `Generate-Gherkin.ps1`                                   |
| Bolt Plan       | `setup-plan.sh`                                    | `Setup-Plan.ps1`                                         |
| Bolt Tasks      | `check-prerequisites.sh`                           | `Check-Prerequisites.ps1`                                |
| Bolt Implement  | `quality-gates.sh`, `architecture-gates.sh`        | `Quality-Gates.ps1`, `Architecture-Gates.ps1`            |
| Bolt Architect  | `architecture-gates.sh`                            | `Architecture-Gates.ps1`                                 |
| Bolt Testing    | `generate-tests.sh`                                | `Generate-Tests.ps1`                                     |
| Bolt Review     | `quality-gates.sh`, `architecture-gates.sh`        | `Quality-Gates.ps1`, `Architecture-Gates.ps1`            |
| Bolt Analyze    | `alignment-analysis.sh`                            | `Get-AlignmentAnalysis.ps1`                              |
| Bolt Alignment  | `alignment-analysis.sh`                            | `Get-AlignmentAnalysis.ps1`                              |
| Bolt ADR        | `create-adr.sh`                                    | `Create-ADR.ps1`                                         |
| Bolt Release    | `create-release.sh`                                | `Create-Release.ps1`                                     |
| Bolt Ops        | `ops-status.sh`, `deploy.sh`                       | `Get-OpsStatus.ps1`                                      |
| Bolt Status     | `project-status.sh`                                | `Get-ProjectStatus.ps1`                                  |
| Bolt Postmortem | `generate-postmortem.sh`                           | `Generate-Postmortem.ps1`                                |
| Bolt Improve    | `analyze-improvements.sh`                          | `Get-Improvements.ps1`                                   |
| Bolt Retire     | `plan-retirement.sh`                               | `Plan-Retirement.ps1`                                    |

## Available Scripts

### 🆕 Project Status Analyzer

Analyzes project state and generates a comprehensive status report for continuity. Essential for resuming work after a pause, onboarding team members, or preparing status updates.

#### Usage

**Bash (Linux/macOS/WSL):**

```bash
# Executive summary (default)
./scripts/bash/project-status.sh

# Full analysis with all details
./scripts/bash/project-status.sh --full

# Specific views
./scripts/bash/project-status.sh --features    # Features only
./scripts/bash/project-status.sh --tasks       # Tasks/Bolts only
./scripts/bash/project-status.sh --quality     # Quality metrics
./scripts/bash/project-status.sh --blockers    # Blockers and decisions
./scripts/bash/project-status.sh --infra       # Infrastructure status

# JSON output for CI/CD
./scripts/bash/project-status.sh --json

# Save report to memory/context/
./scripts/bash/project-status.sh --full --save

# Analyze specific feature
./scripts/bash/project-status.sh --feature 001-user-auth
```

**PowerShell (Windows):**

```powershell
# Executive summary (default)
.\scripts\powershell\Get-ProjectStatus.ps1

# Full analysis with all details
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Full

# Specific views
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Features
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Tasks
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Quality
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Blockers
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Infra

# JSON output for CI/CD
.\scripts\powershell\Get-ProjectStatus.ps1 -Format Json

# Save report to memory/context/
.\scripts\powershell\Get-ProjectStatus.ps1 -ReportType Full -Save

# Analyze specific feature
.\scripts\powershell\Get-ProjectStatus.ps1 -Feature "001-user-auth"
```

#### What It Analyzes

| Category           | Information                                   |
| ------------------ | --------------------------------------------- |
| **Constitution**   | Project scope, type, tech stack               |
| **Features**       | Status of each feature (specs/), completion % |
| **Tasks**          | Bolt progress, pending tasks, current work    |
| **Quality**        | Coverage %, mutation score, code health       |
| **Infrastructure** | IaC status, modules, tools                    |
| **Git**            | Last commit, branch, uncommitted changes      |
| **Blockers**       | Blocked items, pending decisions              |

#### Sample Output

```text
═══════════════════════════════════════════════════════════════
  🚀 BOLT Framework Project Status
═══════════════════════════════════════════════════════════════

Project:       MyProject
Type:          Greenfield | Scope: Full Stack
Branch:        feature/user-auth
Last Activity: abc1234 - feat: Add user registration (2 hours ago)

─── Quick Stats ───

| Metric        | Value |
|---------------|-------|
| Constitution  | ✅ Present |
| Features      | 2/5 complete |
| Tasks         | [████████░░░░░░░░░░░░] 40% |
| Quality       | ⚠️ Below Target |
| Uncommitted   | 3 files |

─── 🎯 Resume Work ───

Current Bolt: Bolt 2 - User Authentication

Next tasks to complete:
  - [ ] T015 Create UserRepository in src/infrastructure/
  - [ ] T016 Add database migration
  - [ ] T017 Implement login endpoint

─── Recommended Actions ───

🔴 HIGH: Resolve blocker B001 with /bolt.clarify
🟡 MEDIUM: Continue with T015 using /bolt.implement
🟡 MEDIUM: Improve test coverage with /bolt.test
```

#### Integration with AI Agents

When starting a new Copilot session, always run `/bolt.status` first:

```text
@Bolt /bolt.status
```

The agent will analyze the project and provide:

1. Current work in progress
2. Recommended next steps
3. Blockers to address
4. Quality status

---

### 🆕 Alignment & Gap Analysis

Analyzes the alignment between RFP requirements, legacy code, implementation, and Bolt Framework Methodology compliance. Detects gaps and generates actionable reports with coverage percentages.

#### Usage

**Bash (Linux/macOS/WSL):**

```bash
# Executive summary (default)
./scripts/bash/alignment-analysis.sh

# Full analysis with all dimensions
./scripts/bash/alignment-analysis.sh --full

# Specific analyses
./scripts/bash/alignment-analysis.sh --rfp          # RFP coverage only
./scripts/bash/alignment-analysis.sh --legacy       # Legacy migration only
./scripts/bash/alignment-analysis.sh --methodology  # BOLT Framework compliance
./scripts/bash/alignment-analysis.sh --gaps         # Gap summary

# Baseline and comparison
./scripts/bash/alignment-analysis.sh --baseline     # Create baseline
./scripts/bash/alignment-analysis.sh --compare memory/baselines/alignment_2024-01-01.json

# JSON output for CI/CD
./scripts/bash/alignment-analysis.sh --json

# Save report to memory/analysis/
./scripts/bash/alignment-analysis.sh --full --save
```

**PowerShell (Windows):**

```powershell
# Executive summary (default)
.\scripts\powershell\Get-AlignmentAnalysis.ps1

# Full analysis with all dimensions
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -Full

# Specific analyses
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -RfpOnly
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -LegacyOnly
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -MethodologyOnly
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -GapsOnly

# Baseline and comparison
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -CreateBaseline
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -CompareTo "memory\baselines\alignment_2024-01-01.json"

# JSON output for CI/CD
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -AsJson

# Save report to memory/analysis/
.\scripts\powershell\Get-AlignmentAnalysis.ps1 -Full -SaveReport
```

#### Analysis Dimensions

| Dimension                      | Description                                   | Relevance                        |
| ------------------------------ | --------------------------------------------- | -------------------------------- |
| **RFP Coverage**               | Traceability from RFP items to specs/features | When `demo/from_rfp/` exists     |
| **Legacy Migration**           | Functions/modules migrated vs pending         | When `demo/from_old_src/` exists |
| **Bolt Framework Methodology** | Compliance with AI-DLC phases                 | Always                           |
| **Testing**                    | Test coverage and mutation score              | Always                           |
| **Documentation**              | README, ADRs, constitution completeness       | Always                           |
| **Infrastructure**             | IaC, CI/CD, containers                        | Always                           |

#### Gap Severity Levels

| Level       | Color  | Description                                           |
| ----------- | ------ | ----------------------------------------------------- |
| 🔴 Critical | Red    | Major gaps blocking progress (>50% missing)           |
| 🟠 High     | Orange | Significant gaps requiring attention (30-50% missing) |
| 🟡 Medium   | Yellow | Minor gaps for improvement                            |
| 🟢 Low      | Green  | Nice-to-have items                                    |

#### Sample Output

```text
═══════════════════════════════════════════════════════════════
  🎯 BOLT Framework Alignment Analysis
═══════════════════════════════════════════════════════════════

Project Type: Migration | Scope: Full Stack
Migration Strategy: Strangler Fig
Has RFP: true | Has Legacy: true

─── Overall Alignment: 67% ───

[█████████████░░░░░░░] 67%

| Dimension            | Score                        | Status |
|---------------------|------------------------------|--------|
| RFP Coverage        | [███████████░░░░░░░░░] 55%  | ⚠️     |
| Legacy Migration    | [████████░░░░░░░░░░░░] 40%  | ⚠️     |
| BOLT Framework Methodology  | [█████████████████░░░] 85%  | ✅     |
| Testing             | [████████████████░░░░] 80%  | ✅     |
| Documentation       | [████████████░░░░░░░░] 60%  | ⚠️     |
| Infrastructure      | [█████████████████░░░] 80%  | ✅     |

─── Gap Summary ───

| Priority     | Count |
|-------------|-------|
| 🔴 Critical | 1     |
| 🟠 High     | 2     |
| 🟡 Medium   | 3     |
| 🟢 Low      | 1     |
| **Total**   | **7** |

─── 🔴 Critical Gaps ───

  - Legacy migration only 40%

─── 🟠 High Priority Gaps ───

  - RFP coverage at 55%
  - Test coverage at 75% (target: 80%)

─── 🎯 Recommended Actions ───

| # | Priority | Action                                    | Command           |
|---|----------|-------------------------------------------|-------------------|
| 1 | High     | Analyze and migrate legacy functions      | `/bolt.analyze` |
| 2 | High     | Create feature specs for uncovered RFP    | `/bolt.feature` |
| 3 | High     | Improve test coverage                     | `/bolt.test`    |
```

#### Baseline Comparison

Track alignment progress over time:

```text
═══════════════════════════════════════════════════════════════
  📊 Alignment Comparison
═══════════════════════════════════════════════════════════════

Comparing with baseline: 2024-01-01

| Dimension        | Previous | Current | Delta   |
|------------------|----------|---------|---------|
| Overall          | 45%      | 67%     | +22%    |
| RFP Coverage     | 30%      | 55%     | +25%    |
| Legacy Migration | 20%      | 40%     | +20%    |
| Methodology      | 70%      | 85%     | +15%    |
| Testing          | 60%      | 80%     | +20%    |
```

#### Integration with AI Agents

Invoke alignment analysis from Copilot:

```text
@Bolt /bolt.alignment
```

The agent analyzes:

1. **RFP Traceability**: Which requirements have specs vs uncovered
2. **Legacy Progress**: Migration status by language/module
3. **Methodology Gaps**: Which AI-DLC artifacts are missing
4. **Action Plan**: Prioritized list of next steps

---

### 🆕 Project Initialization (Init)

Initializes a new BOLT Framework project workspace with an **interactive configuration wizard**. Supports both **Greenfield** (new projects) and **Brownfield** (migration from existing code) scenarios.

#### Quick Start with Auto-Profiles

For rapid project setup, use auto-profiles that pre-configure all technology choices:

**Bash (Linux/macOS/WSL):**

```bash
# .NET 8 Modular Monolith with CQRS, Azure SQL, Container Apps
./init.sh /path/to/project green --scope app-only --backend csharp --auto

# Node.js 20 NestJS with PostgreSQL, Container Apps
./init.sh /path/to/project green --scope app-only --backend nodejs --auto

# Landing Zone Infrastructure with Bicep
./init.sh /path/to/project green --scope infra-only --infra-scope landing-zone --auto

# Workload Infrastructure with Bicep
./init.sh /path/to/project green --scope infra-only --infra-scope workload --auto

# Full Stack: .NET + Vue.js + Bicep Infrastructure
./init.sh /path/to/project green --scope full-stack --backend csharp --frontend react --auto
```

**PowerShell (Windows):**

```powershell
# .NET 8 Modular Monolith with CQRS, Azure SQL, Container Apps
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\my-api" -Auto "app-dotnet"

# Node.js 20 NestJS with PostgreSQL, Container Apps
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\my-node-api" -Auto "app-node"

# Landing Zone Infrastructure with Bicep
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\my-landing-zone" -Auto "infra-landing"

# Workload Infrastructure with Bicep
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\my-workload" -Auto "infra-workload"

# Full Stack: .NET + Vue.js + Bicep Infrastructure
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\my-fullstack" -Auto "fullstack-dotnet"
```

#### Auto-Profile Configurations

| Profile            | Scope      | Backend               | Architecture            | Database            | Container      | IaC   |
| ------------------ | ---------- | --------------------- | ----------------------- | ------------------- | -------------- | ----- |
| `app-dotnet`       | App Only   | C# .NET 8 Minimal API | Modular Monolith + CQRS | Azure SQL + EF Core | Container Apps | -     |
| `app-node`         | App Only   | Node.js 20 NestJS     | Modular Monolith + CQRS | PostgreSQL + Prisma | Container Apps | -     |
| `infra-landing`    | Infra Only | -                     | -                       | -                   | -              | Bicep |
| `infra-workload`   | Infra Only | -                     | -                       | -                   | -              | Bicep |
| `fullstack-dotnet` | Full Stack | C# .NET 8 Minimal API | Modular Monolith + CQRS | Azure SQL + EF Core | Container Apps | Bicep |

#### Interactive Wizard Mode

Without `--auto`, the scripts launch a 10-question interactive wizard:

**Bash:**

```bash
# Interactive Greenfield
./init.sh ~/projects/my-new-app green --scope app-only --backend csharp

# Interactive Brownfield (migration)
./init.sh ~/projects/legacy-migration brown ~/legacy-code --backend csharp --architecture microservices
```

**PowerShell:**

```powershell
# Interactive Greenfield
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\my-new-app"

# Interactive Brownfield (migration)
.\scripts\powershell\Init.ps1 -OutputDirectory "C:\projects\migration" -ProjectType brown -SourceDirectory "C:\legacy"
```

**Wizard Questions (10 steps):**

1. **Project Scope**: Infrastructure Only, Application Only, or Full Stack
2. **Backend Technology**: C# .NET or Node.js TypeScript
3. **Architecture Style**: Modular Monolith, Microservices, Monolith, Serverless, Event-Driven
4. **CQRS Pattern**: Enable/Disable Command Query Responsibility Segregation
5. **Frontend Framework**: None, Vue.js, React, Angular, Blazor
6. **Database**: Azure SQL, PostgreSQL, Cosmos DB, MongoDB
7. **Containers & Orchestration**: Docker + Container Apps/AKS/App Service
8. **Infrastructure as Code**: Bicep, Terraform, Pulumi
9. **CI/CD Platform**: GitHub Actions or Azure DevOps
10. **Environments**: dev, staging, prod (customizable)

#### Parameters Reference

| Parameter        | Bash               | PowerShell         | Required   | Description                             |
| ---------------- | ------------------ | ------------------ | ---------- | --------------------------------------- |
| Output Directory | `$1` (positional)  | `-OutputDirectory` | Yes        | Where to create the project             |
| Project Type     | `$2` (positional)  | `-ProjectType`     | Yes\*      | `green` (new) or `brown` (migration)    |
| Source Directory | `$3` (positional)  | `-SourceDirectory` | Brown only | Source code/docs to migrate             |
| Auto Profile     | `--auto <profile>` | `-Auto <profile>`  | No         | Skip wizard with pre-configured profile |

\*PowerShell defaults to `green` if not specified.

#### Generated Project Structure

**Greenfield (Application - app-dotnet):**

```text
my-project/
├── .github/
│   ├── copilot/agents/       # AI Agents
│   ├── commands/             # Slash Commands
│   ├── prompts/              # Context Prompts
│   └── workflows/            # CI/CD Pipelines
├── memory/
│   └── constitution.md       # Pre-filled with your choices!
├── specs/
│   └── .template/            # Feature specification templates
├── docs/
│   ├── adr/                  # Architecture Decision Records
│   └── architecture/         # Architecture documentation
├── src/
│   ├── Shared/SharedKernel/  # CQRS interfaces, Domain primitives
│   ├── Modules/SampleModule/ # Sample module with DDD layers
│   └── Api.Host/             # Composition root
├── tests/
│   ├── SampleModule.UnitTests/
│   ├── SampleModule.IntegrationTests/
│   └── Architecture.Tests/
├── scripts/                  # BOLT Framework automation scripts
├── infra/scripts/            # Infrastructure scripts
├── Directory.Build.props     # .NET build configuration
├── global.json               # .NET SDK version
├── .editorconfig             # Code style rules
├── .gitignore                # Git ignore patterns
└── README.md                 # Project documentation
```

**Greenfield (Infrastructure - infra-landing):**

```text
my-landing-zone/
├── .github/workflows/        # Platform deploy pipelines
├── .boltf/memory/constitution.md    # Pre-filled configuration
├── infra/
│   └── landing-zone/
│       ├── modules/
│       │   ├── management-groups/
│       │   ├── policy-definitions/
│       │   ├── policy-assignments/
│       │   ├── rbac/
│       │   ├── networking/hub/
│       │   ├── networking/dns/
│       │   ├── security/defender/
│       │   ├── security/sentinel/
│       │   ├── monitoring/log-analytics/
│       │   └── identity/
│       ├── environments/
│       └── main.bicep
├── tests/
│   ├── bicep-lint/
│   ├── security/
│   ├── policy-compliance/
│   └── post-deploy/
├── docs/
│   ├── adr/
│   ├── architecture/
│   └── runbooks/
└── pipelines/
```

**Brownfield (Migration):**

```text
my-migration/
├── legacy/
│   ├── source/               # Copy of original code
│   ├── analysis/             # Discovery documentation
│   └── documentation/        # Existing docs
├── migration/
│   ├── plan/                 # Migration roadmap
│   └── mappings/             # Legacy → New mappings
├── .boltf/memory/constitution.md    # Technology choices
├── specs/                    # Feature specifications
├── docs/adr/                 # Architecture decisions
└── ... (same structure as greenfield)
```

#### Constitution Pre-fill

The `constitution.md` file is automatically pre-filled with your wizard/auto-profile selections:

```markdown
## 🎯 Project Scope

- [x] **Application Development Only** ← Auto-selected!

## 💻 Backend Technology

- [x] **C# / .NET** ← Auto-selected!
  - Version: [x] .NET 8
  - API Style: [x] Minimal APIs

## 🏛️ Architecture Pattern

- [x] **Modular Monolith** ← Auto-selected!
  - CQRS Enabled: [x] Yes
```

#### Next Steps After Init

1. `cd <your-project-directory>`
2. Review `.boltf/memory/constitution.md` (already pre-filled!)
3. Complete any remaining configuration sections
4. Start your first feature: `/bolt.feature [your-first-feature]`

---

### Feature Creation

Creates a new feature branch with specification structure.

**Bash:**

```bash
./scripts/bash/create-new-feature.sh user-authentication main
```

**PowerShell:**

```powershell
.\scripts\powershell\Create-NewFeature.ps1 -FeatureName "user-authentication" -BaseBranch "main"
```

**Creates:**

- Feature branch: `feature/user-authentication`
- Specification directory: `specs/user-authentication/`
  - `spec.md` - Feature specification template
  - `data-model.md` - Data model template
  - `plan.md` - Plan placeholder
  - `contracts/` - API contracts directory

### Quality Gates

Runs comprehensive quality checks on the codebase.

**Bash:**

```bash
# Check mode (default)
./scripts/bash/quality-gates.sh --check

# Auto-fix mode
./scripts/bash/quality-gates.sh --fix

# Full suite (includes security scan + architecture gates)
./scripts/bash/quality-gates.sh --check --full
```

**PowerShell:**

```powershell
# Check mode (default)
.\scripts\powershell\Quality-Gates.ps1 -Check

# Auto-fix mode
.\scripts\powershell\Quality-Gates.ps1 -Fix

# Full suite
.\scripts\powershell\Quality-Gates.ps1 -Check -Full
```

**Checks Include:**

1. Type checking (TypeScript/MyPy)
2. Linting (ESLint/Ruff/Go Vet)
3. Formatting (Prettier/Black/gofmt)
4. Unit tests
5. Coverage (with `--full`)
6. Mutation testing
7. Security scan (with `--full`)
8. **Architecture gates** (with `--full`)

### Architecture Quality Gates 🏗️

**New in v2.3** - Validates architectural rules, boundaries and quality metrics.

**Bash:**

```bash
# Run architecture checks
./scripts/bash/architecture-gates.sh --check

# Generate SVG dependency graph
./scripts/bash/architecture-gates.sh --report

# CI mode (exit code on failure)
./scripts/bash/architecture-gates.sh --ci
```

**PowerShell:**

```powershell
# Run architecture checks
.\scripts\powershell\Architecture-Gates.ps1 -Check

# Generate reports
.\scripts\powershell\Architecture-Gates.ps1 -Report

# CI mode
.\scripts\powershell\Architecture-Gates.ps1 -CIMode
```

**Architecture Gates:**

| Gate                         | Description                           | Tools by Stack                                                                                 |
| ---------------------------- | ------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **1. Dependency Rules**      | Layer boundary enforcement            | `dependency-cruiser` (Node), `NetArchTest` (.NET), `ArchUnit` (Java), `import-linter` (Python) |
| **2. Circular Dependencies** | Detect import cycles                  | `madge` (Node), architecture tests                                                             |
| **3. Contract Validation**   | API spec validation                   | `Spectral` (OpenAPI), `asyncapi validate`, `Pact`                                              |
| **4. Complexity Metrics**    | Code complexity limits                | ESLint rules, Roslyn analyzers, `radon` (Python)                                               |
| **5. Fitness Functions**     | Build time, bundle size, test quality | Custom scripts                                                                                 |

**Configuration:**

Thresholds are loaded from `.boltf/memory/constitution.md`:

```markdown
### 5.1 Dependency Rules

- Domain layer must not import from Infrastructure or Presentation
- Tools: dependency-cruiser (Node), NetArchTest (.NET), ArchUnit (Java)

### 5.2 Contract Validation

- OpenAPI specs: Must pass Spectral linting
- AsyncAPI specs: Must pass validation
- Pact contracts: Consumer/provider tests must pass

### 5.3 Complexity Metrics

- Cyclomatic Complexity ≤ 10
- Cognitive Complexity ≤ 15
- Max function lines: 50
- Max file lines: 400
```

**Auto-generated Config:**

For Node.js/TS projects without dependency-cruiser, the script generates `.dependency-cruiser.cjs` with Clean Architecture rules:

- Domain → No Infrastructure/Presentation imports
- Application → No Infrastructure imports
- Infrastructure → Can import Domain/Application

**Reports:**

Reports are generated in `reports/architecture/`:

- `dependency-graph.svg` - Visual dependency graph
- `architecture-report.json` - Gate results (CI mode)

### Specification Validation

Validates specification files for completeness.

**Bash:**

```bash
# Validate all features
./scripts/bash/validate-specs.sh --check

# Validate specific feature
./scripts/bash/validate-specs.sh --check user-authentication
```

**PowerShell:**

```powershell
# Validate all features
.\scripts\powershell\Validate-Specs.ps1 -Check

# Validate specific feature
.\scripts\powershell\Validate-Specs.ps1 -Check -BranchName "user-authentication"
```

**Validates:**

- Constitution existence and required sections
- `spec.md` - User stories and acceptance criteria
- `plan.md` - Bolts definition
- `tasks.md` - Task completion status
- `data-model.md` - Entity definitions
- `contracts/` - API specifications
- Cross-references between artifacts

### Use Case Generation

Generates use case documents from feature specifications.

**Bash:**

```bash
# Generate for feature
./scripts/bash/generate-usecases.sh user-authentication

# Generate for multiple features
./scripts/bash/generate-usecases.sh user-authentication payment-processing
```

**PowerShell:**

```powershell
# Generate for feature
.\scripts\powershell\Generate-UseCases.ps1 -FeatureName "user-authentication"

# Custom output directory
.\scripts\powershell\Generate-UseCases.ps1 -FeatureName "user-authentication" -OutputDir "docs/features"
```

**Creates:**

- `docs/use-cases/{feature}/` - Use case directory
  - `README.md` - Use case index
  - `UC-{NNN}-{name}.md` - Individual use case files

### Gherkin Scenario Generation

Generates BDD/Gherkin test scenarios from use cases.

**Bash:**

```bash
# Generate for feature
./scripts/bash/generate-gherkin.sh user-authentication

# Generate for specific use case
./scripts/bash/generate-gherkin.sh user-authentication login
```

**PowerShell:**

```powershell
# Generate for feature
.\scripts\powershell\Generate-Gherkin.ps1 -FeatureName "user-authentication"

# Custom output directory
.\scripts\powershell\Generate-Gherkin.ps1 -FeatureName "user-authentication" -OutputDir "tests/acceptance"
```

**Creates:**

- `tests/acceptance/{feature}/` - Gherkin directory
  - `{feature}.feature` - Main feature file
  - Individual `.feature` files per use case

### ADR Creation

Creates Architectural Decision Records from template.

**Bash:**

```bash
# Create new ADR
./scripts/bash/create-adr.sh database-selection

# With spaces
./scripts/bash/create-adr.sh "authentication strategy"
```

**PowerShell:**

```powershell
# Create new ADR
.\scripts\powershell\Create-ADR.ps1 -Title "database-selection"

# With spaces
.\scripts\powershell\Create-ADR.ps1 -Title "authentication strategy"
```

**Creates:**

- `docs/adr/ADR-{NNN}-{slug}.md` - New ADR from template
- `docs/adr/README.md` - Updated index (creates if not exists)

### Agent Context Validation

Validates the relationships between Prompts, Agents, and Constitution ensuring consistency across BOLT Framework artifacts.

**Bash:**

```bash
# Check mode - validate all relationships (default)
./scripts/bash/update-agent-context.sh --check

# Report mode - generate detailed mapping report
./scripts/bash/update-agent-context.sh --report

# Fix mode - show what would be corrected
./scripts/bash/update-agent-context.sh --fix
```

**PowerShell:**

```powershell
# Check mode - validate all relationships
.\scripts\powershell\Update-AgentContext.ps1 -Mode Check

# Report mode - generate detailed mapping report
.\scripts\powershell\Update-AgentContext.ps1 -Mode Report

# Fix mode - show what would be corrected
.\scripts\powershell\Update-AgentContext.ps1 -Mode Fix
```

**Validates:**

- Constitution exists at `.boltf/memory/constitution.md`
- All Agents (`.github/copilot/agents/`) reference the Constitution
- All Prompts (`.github/prompts/`) reference their corresponding Agent(s)
- Prompt → Agent → Constitution chain is complete

**Report Output:**

```text
BOLT Framework Context Validation Report
========================================

Constitution: ✓ Found
Agents: 18 total, 18 with Constitution Reference
Prompts: 15 total, 15 with Agent Reference

Prompt → Agent Mappings:
  business-analysis.prompt.md → business-explorer.md
  code-generation.prompt.md → coding-agent.md, micro-iterator.md
  ...
```

## Integration with Commands

Scripts are referenced in command files for automation:

```yaml
# In .github/commands/constitution.md
scripts:
  sh: scripts/bash/create-new-feature.sh
  ps: scripts/powershell/Create-NewFeature.ps1
```

## Supported Project Types

The scripts auto-detect project type and adapt accordingly:

| Project Type | Detection                             | Tools Used                                           |
| ------------ | ------------------------------------- | ---------------------------------------------------- |
| Node.js      | `package.json`                        | TypeScript, ESLint, Prettier, Jest/Vitest, npm audit |
| Python       | `requirements.txt` / `pyproject.toml` | MyPy, Ruff/Flake8, Black, Pytest, Safety             |
| Go           | `go.mod`                              | go vet, golint, gofmt, go test, govulncheck          |
| Rust         | `Cargo.toml`                          | rustfmt, cargo test, cargo audit                     |

## Making Scripts Executable

**Linux/macOS:**

```bash
chmod +x scripts/bash/*.sh
```

**Windows:**
PowerShell scripts may require execution policy adjustment:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Exit Codes

All scripts follow standard exit codes:

| Code | Meaning                             |
| ---- | ----------------------------------- |
| 0    | Success (all checks passed)         |
| 1    | Failure (one or more checks failed) |

This allows integration with CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Quality Gates
  run: ./scripts/bash/quality-gates.sh --check --full
```

---

## 🎯 Practical Examples: Step-by-Step Tutorials

This section provides complete walkthroughs using the demo files included in this repository.

### Demo Files Available

```text
demo/
├── from_rfp/
│   └── RFP-Calculator.md      # 📄 RFP document for a new Calculator app
├── from_old_src/
│   ├── CALCENGN.cbl           # 📜 Legacy COBOL calculator engine
│   └── CALCMAIN.cbl           # 📜 Legacy COBOL main program
├── to_rfp/
│   └── README.md              # Output folder for Greenfield projects
└── to_old_src/
    └── README.md              # Output folder for Brownfield projects
```

---

### 🌱 Example 1: Greenfield Project (New Calculator from RFP)

**Scenario**: You have an RFP (Request for Proposal) document describing a new Business Calculator application. You want to create a brand new project using modern technologies.

#### Step 1: Initialize the Greenfield Project

**Using WSL/Bash:**

```bash
# Navigate to BOLT Framework template
cd /path/to/Bolt Framework-v1.0.0

# Create new project from RFP
./init.sh ./demo/to_rfp/calculator-app green --scope app-only --backend csharp
```

**Using PowerShell (Windows):**

```powershell
# Navigate to BOLT Framework template
cd C:\path\to\Bolt Framework-v1.0.0

# Create new project from RFP
.\scripts\powershell\Init.ps1 -OutputDirectory ".\demo\to_rfp\calculator-app" -ProjectType green
```

#### Step 2: Configure the Constitution

```bash
# Open VS Code in the new project
code ./demo/to_rfp/calculator-app
```

Edit `.boltf/memory/constitution.md` and fill in your technology choices:

```markdown
# Example Constitution for Calculator App

## Article I: Technology Stack

### Section 1.1: Frontend

| Layer            | Technology               | Version | Rationale                 |
| ---------------- | ------------------------ | ------- | ------------------------- |
| Framework        | React                    | 18.x    | Modern component-based UI |
| Language         | TypeScript               | 5.x     | Type safety               |
| Styling          | Tailwind CSS             | 3.x     | Utility-first CSS         |
| State Management | Zustand                  | 4.x     | Lightweight state         |
| Build Tool       | Vite                     | 5.x     | Fast builds               |
| Testing          | Vitest + Testing Library | latest  | Modern testing            |

### Section 1.2: Backend

| Layer          | Technology | Version | Rationale               |
| -------------- | ---------- | ------- | ----------------------- |
| Runtime        | Node.js    | 20.x    | LTS version             |
| Framework      | Express    | 4.x     | Mature, well-documented |
| Language       | TypeScript | 5.x     | Type safety             |
| API Style      | REST       | -       | Simple, well-understood |
| Authentication | JWT        | -       | Stateless auth          |
| Testing        | Jest       | 29.x    | Comprehensive testing   |
```

**Or use Copilot Chat:**

```text
/bolt.constitution
```

#### Step 3: Attach the RFP and Create Feature

In GitHub Copilot Chat:

```text
#file:demo/from_rfp/RFP-Calculator.md

/bolt.feature calculator-core
```

#### Step 4: Generate Use Cases

```text
/bolt.usecase
```

#### Step 5: Plan Implementation

```text
/bolt.plan
```

#### Step 6: Generate Tasks (Bolts)

```text
/bolt.tasks
```

#### Step 7: Start Implementation

```text
#file:.github/prompts/bolt-code-generation.prompt.md

Implement task T001: Create the Calculator domain entity
```

#### Greenfield Project Structure Created

```text
demo/to_rfp/calculator-app/
├── .github/
│   ├── copilot/agents/       # 18 AI agents ready
│   ├── commands/             # 13 slash commands
│   ├── prompts/              # 15 context prompts
│   └── workflows/            # CI/CD pipelines
├── memory/
│   ├── constitution.md       # 👈 FILL THIS FIRST
│   └── SETUP-CONSTITUTION.md # Setup guide
├── specs/                    # Feature specifications
├── docs/
│   ├── adr/                  # Architecture decisions
│   └── architecture/         # Design docs
├── src/
│   ├── domain/               # Business logic (DDD)
│   │   ├── entities/
│   │   ├── value-objects/
│   │   ├── events/
│   │   └── services/
│   ├── application/          # Use cases
│   │   ├── use-cases/
│   │   ├── ports/
│   │   └── dtos/
│   ├── infrastructure/       # External adapters
│   │   ├── persistence/
│   │   ├── messaging/
│   │   └── external/
│   └── presentation/         # API/UI
│       ├── api/
│       └── web/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── scripts/                  # BOLT Framework automation scripts
```

---

### 🏗️ Example 2: Brownfield Project (COBOL Migration)

**Scenario**: You have legacy COBOL calculator programs that need to be migrated to a modern technology stack while preserving business logic.

#### Step 1: Initialize the Brownfield Project

**Using WSL/Bash:**

```bash
# Navigate to BOLT Framework template
cd /path/to/Bolt Framework-v1.0.0

# Create migration project pointing to legacy source
./init.sh ./demo/to_old_src/calculator-migration brown ./demo/from_old_src --backend csharp --architecture microservices
```

**Using PowerShell (Windows):**

```powershell
# Navigate to BOLT Framework template
cd C:\path\to\Bolt Framework-v1.0.0

# Create migration project pointing to legacy source
.\scripts\powershell\Init.ps1 `
    -OutputDirectory ".\demo\to_old_src\calculator-migration" `
    -ProjectType brown `
    -SourceDirectory ".\demo\from_old_src"
```

#### Step 2: Analyze Legacy Code

Your COBOL source has been copied to `legacy/source/`:

```bash
# View the legacy code
cat ./demo/to_old_src/calculator-migration/legacy/source/CALCENGN.cbl
cat ./demo/to_old_src/calculator-migration/legacy/source/CALCMAIN.cbl
```

Use Copilot to analyze:

```markdown
#file:legacy/source/CALCENGN.cbl
#file:legacy/source/CALCMAIN.cbl
#file:.github/prompts/bolt-legacy-analysis.prompt.md

Analyze these COBOL programs and document:

1. Business logic and calculations
2. Data structures
3. Input/output operations
4. Dependencies
```

Document findings in `legacy/analysis/`:

```markdown
# legacy/analysis/cobol-analysis.md

## CALCENGN.cbl Analysis

- Purpose: Core calculation engine
- Operations: ADD, SUBTRACT, MULTIPLY, DIVIDE
- Precision: 18 digits with 4 decimal places
- Error handling: Division by zero, overflow

## CALCMAIN.cbl Analysis

- Purpose: User interface and orchestration
- Input: Screen-based data entry
- Output: Formatted results display
- Flow: Menu-driven operation selection
```

#### Step 3: Define TARGET Constitution

Edit `.boltf/memory/constitution.md` with your **target** modern stack:

```markdown
# Migration Constitution: COBOL Calculator → Modern Stack

## Article I: Technology Stack

<!-- LEGACY (for reference):
- Language: COBOL-85
- Runtime: Mainframe z/OS
- Data: VSAM files
- UI: 3270 terminal screens
-->

### Section 1.2: Backend (TARGET)

| Layer          | Technology | Version | Rationale                    |
| -------------- | ---------- | ------- | ---------------------------- |
| Runtime        | Python     | 3.12    | Easy COBOL logic translation |
| Framework      | FastAPI    | 0.100+  | Modern async API             |
| Language       | Python     | 3.12    | Readable, maintainable       |
| API Style      | REST       | -       | Universal access             |
| Authentication | OAuth2     | -       | Modern standard              |
| Testing        | Pytest     | 7.x     | Comprehensive                |

### Section 1.3: Data Layer (TARGET)

| Layer            | Technology | Version | Rationale                      |
| ---------------- | ---------- | ------- | ------------------------------ |
| Primary Database | PostgreSQL | 15+     | ACID compliance like mainframe |
| ORM              | SQLAlchemy | 2.x     | Robust data mapping            |
```

#### Step 4: Create Migration Mappings

Create `migration/mappings/technology-mapping.md`:

```markdown
# Technology Migration Mapping

| Legacy (COBOL)  | Target (Python) | Notes            |
| --------------- | --------------- | ---------------- |
| PIC 9(18)V9(4)  | Decimal(22,4)   | Exact precision  |
| WORKING-STORAGE | Python classes  | State management |
| PERFORM         | Functions       | Procedure calls  |
| EVALUATE/WHEN   | match/case      | Control flow     |
| VSAM files      | PostgreSQL      | Data persistence |
| DISPLAY         | API response    | Output           |
| ACCEPT          | API request     | Input            |
```

Create `migration/mappings/code-mapping.md`:

````markdown
# Code Pattern Migration

## Calculation Mapping

### COBOL Pattern

```cobol
COMPUTE WS-RESULT = WS-NUM1 + WS-NUM2
IF WS-RESULT > 999999999999999999.9999
   MOVE 'OVERFLOW' TO WS-ERROR
END-IF
```
````

### Python Equivalent

```python
from decimal import Decimal, InvalidOperation

def add(num1: Decimal, num2: Decimal) -> Decimal:
    result = num1 + num2
    if result > Decimal('999999999999999999.9999'):
        raise OverflowError("Result exceeds maximum precision")
    return result
```

```markdown
#### Step 5: Define Migration Features
```

```text
/bolt.feature migrate-calculation-engine
```

This creates `specs/migrate-calculation-engine/spec.md`:

```markdown
# Feature: Migrate Calculation Engine

## Migration Scope

- Source: CALCENGN.cbl
- Target: src/domain/services/calculation_engine.py

## Acceptance Criteria

- [ ] All 4 operations (ADD, SUB, MUL, DIV) produce identical results
- [ ] Precision maintained: 18 digits, 4 decimals
- [ ] Error handling: Division by zero, overflow
- [ ] 100% test coverage with legacy equivalence tests
```

#### Step 6: Plan Migration

```text
/bolt.plan
```

#### Step 7: Execute Migration with Legacy Equivalence

```markdown
#file:.github/prompts/bolt-code-generation.prompt.md
#file:legacy/source/CALCENGN.cbl
#file:migration/mappings/code-mapping.md

Migrate the COBOL calculation engine to Python, ensuring:

1. Exact same precision (18,4)
2. Same overflow handling
3. Same division by zero behavior
```

#### Step 8: Create Equivalence Tests

```markdown
#file:.github/prompts/bolt-test-generation.prompt.md

Create equivalence tests that verify the Python implementation
produces identical results to the COBOL original for:

- Edge cases (max values, zero, negative)
- All operations
- Error conditions
```

#### Brownfield Project Structure Created

```text
demo/to_old_src/calculator-migration/
├── .github/
│   ├── copilot/agents/       # 18 AI agents
│   ├── commands/             # 13 slash commands
│   ├── prompts/              # 15 context prompts
│   └── workflows/            # CI/CD pipelines
├── memory/
│   ├── constitution.md       # 👈 TARGET stack here
│   └── SETUP-CONSTITUTION.md # Migration guide
├── legacy/                   # 📂 LEGACY REFERENCE
│   ├── source/               # 👈 Your COBOL copied here
│   │   ├── CALCENGN.cbl
│   │   └── CALCMAIN.cbl
│   ├── analysis/             # Document discoveries
│   └── documentation/        # Existing docs
├── migration/                # 📋 MIGRATION PLANNING
│   ├── plan/                 # Phase planning
│   └── mappings/             # Legacy → New mappings
├── specs/                    # Migration features
├── docs/
│   ├── adr/                  # Decisions (e.g., "why Python")
│   └── architecture/         # New architecture
└── scripts/                  # Automation
```

---

### 📊 Comparison: Greenfield vs Brownfield

| Aspect                 | Greenfield 🌱          | Brownfield 🏗️            |
| ---------------------- | ---------------------- | ------------------------ |
| **Starting Point**     | RFP/Requirements doc   | Existing source code     |
| **Constitution Focus** | Define new stack       | Define TARGET stack      |
| **First Step**         | `/bolt.constitution`   | Analyze legacy code      |
| **Key Folders**        | `src/` (new code)      | `legacy/` + `migration/` |
| **Testing Strategy**   | TDD from scratch       | Equivalence tests        |
| **Risk**               | Requirements gaps      | Logic translation errors |
| **AI Prompts**         | `bolt-code-generation` | `bolt-legacy-analysis`   |

---

### 🔄 Quick Reference: Init Parameters

```bash
# Greenfield Syntax
./init.sh <output-dir> green --scope <scope> --backend <backend>

# Brownfield Syntax
./init.sh <output-dir> brown <source-dir> --backend <backend> --architecture <architecture>
```

```powershell
# Greenfield Syntax
.\scripts\powershell\Init.ps1 -OutputDirectory <path> -ProjectType green

# Brownfield Syntax
.\scripts\powershell\Init.ps1 -OutputDirectory <path> -ProjectType brown -SourceDirectory <legacy-path>
```

| Parameter         | Greenfield  | Brownfield  | Description             |
| ----------------- | ----------- | ----------- | ----------------------- |
| `OutputDirectory` | ✅ Required | ✅ Required | Where to create project |
| `ProjectType`     | `green`     | `brown`     | Type of project         |
| `SourceDirectory` | ❌ Not used | ✅ Required | Path to legacy code     |

---

### � Release Manager (NEW)

Creates release artifacts, updates CHANGELOG, and generates deployment units for Block 5 - Release.

**Bash:**

```bash
./scripts/bash/create-release.sh --version 1.2.0
./scripts/bash/create-release.sh --type patch --notes
./scripts/bash/create-release.sh --version 2.0.0 --deploy staging
```

**PowerShell:**

```powershell
.\scripts\powershell\Create-Release.ps1 -Version "1.2.0"
.\scripts\powershell\Create-Release.ps1 -VersionType patch -IncludeNotes
.\scripts\powershell\Create-Release.ps1 -Version "2.0.0" -DeployTo staging
```

---

### 🔧 Operations Status (NEW)

Checks system health, Docker status, and generates runbooks for Block 6 - Operations.

**Bash:**

```bash
./scripts/bash/ops-status.sh --all
./scripts/bash/ops-status.sh --status
./scripts/bash/ops-status.sh --runbook "my-service"
./scripts/bash/ops-status.sh --docker
```

**PowerShell:**

```powershell
.\scripts\powershell\Get-OpsStatus.ps1 -All
.\scripts\powershell\Get-OpsStatus.ps1 -CheckHealth
.\scripts\powershell\Get-OpsStatus.ps1 -GenerateRunbook "my-service"
.\scripts\powershell\Get-OpsStatus.ps1 -DockerStatus
```

---

### 📋 Postmortem Generator (NEW)

Creates blameless incident postmortem documents for Block 6 - Operations.

**Bash:**

```bash
./scripts/bash/generate-postmortem.sh --interactive
./scripts/bash/generate-postmortem.sh --title "API Outage" --severity P1 --date 2024-01-15
```

**PowerShell:**

```powershell
.\scripts\powershell\Generate-Postmortem.ps1 -Interactive
.\scripts\powershell\Generate-Postmortem.ps1 -Title "API Outage" -Severity P1 -IncidentDate "2024-01-15"
```

---

### 📊 Improvement Analyzer (NEW)

Analyzes codebase and generates improvement backlogs for Block 7 - Evolution.

**Bash:**

```bash
./scripts/bash/analyze-improvements.sh --all
./scripts/bash/analyze-improvements.sh --code
./scripts/bash/analyze-improvements.sh --deps
./scripts/bash/analyze-improvements.sh --generate
```

**PowerShell:**

```powershell
.\scripts\powershell\Get-Improvements.ps1 -All
.\scripts\powershell\Get-Improvements.ps1 -AnalyzeCode
.\scripts\powershell\Get-Improvements.ps1 -AnalyzeDependencies
.\scripts\powershell\Get-Improvements.ps1 -GenerateBacklogs
```

---

### 🏚️ Retirement Planner (NEW)

Plans system decommissioning and tracks consumer migrations for Block 8 - Retirement.

**Bash:**

```bash
./scripts/bash/plan-retirement.sh --interactive
./scripts/bash/plan-retirement.sh --name "Legacy API" --date 2024-12-31 --generate
./scripts/bash/plan-retirement.sh --name "Old Module" --list-consumers
```

**PowerShell:**

```powershell
.\scripts\powershell\Plan-Retirement.ps1 -Interactive
.\scripts\powershell\Plan-Retirement.ps1 -SystemName "Legacy API" -TargetDate "2024-12-31" -GeneratePlan
.\scripts\powershell\Plan-Retirement.ps1 -SystemName "Old Module" -ListConsumers
```

---

### �💡 Tips for Real Projects

1. **Always start with Constitution** - It's the DNA of your project
2. **For Brownfield**: Spend time analyzing legacy BEFORE defining target stack
3. **Use ADRs** - Document why you chose specific technologies
4. **Iterate in Bolts** - Small 2-3 day iterations, not big-bang migrations
5. **Test equivalence** - For migrations, ensure new code behaves identically
6. **Leverage AI agents** - Each agent is specialized for specific tasks

---

### 🚀 Try It Yourself

```bash
# Quick test - Greenfield
./init.sh /tmp/test-green green --scope app-only --backend csharp --auto
ls -la /tmp/test-green

# Quick test - Brownfield
./init.sh /tmp/test-brown brown ./demo/from_old_src --backend csharp --architecture microservices --auto
ls -la /tmp/test-brown/legacy/source
```
